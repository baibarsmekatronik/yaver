import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/fleet_repository.dart';
import '../data/maintenance_rules_seed.dart';
import '../domain/aircraft.dart';
import '../domain/aircraft_summary.dart';
import '../domain/flight.dart';
import '../domain/maintenance_rule.dart';

/// Uygulama açılışında `main.dart` içinde gerçek depo ile geçersiz kılınır;
/// testlerde bellek deposu verilir.
final fleetRepositoryProvider = Provider<FleetRepository>(
  (ref) => throw UnimplementedError(
    'fleetRepositoryProvider main.dart içinde override edilmeli',
  ),
);

final uuidProvider = Provider<Uuid>((ref) => const Uuid());

/// Bakım kuralları veriden gelir; tohum yalnızca ilk kurulum içindir.
/// Platform bağlandığında bu sağlayıcı `maintenance_rules` tablosunu okuyacak.
final maintenanceRulesProvider =
    Provider<List<MaintenanceRule>>((ref) => maintenanceRulesSeed);

/// Şu anki saati veren sağlayıcı — testler zamanı sabitleyebilsin diye.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final fleetControllerProvider =
    NotifierProvider<FleetController, List<AircraftSummary>>(
  FleetController.new,
);

/// Filo ekranlarının tek durum kaynağı.
///
/// Veri zaten cihazda olduğu için okuma senkron; bu yüzden `AsyncNotifier`
/// değil `Notifier` kullanıldı — uygulama yükleme spinner'ı olmadan açılır.
class FleetController extends Notifier<List<AircraftSummary>> {
  FleetRepository get _repo => ref.read(fleetRepositoryProvider);
  Uuid get _uuid => ref.read(uuidProvider);
  List<MaintenanceRule> get _rules => ref.read(maintenanceRulesProvider);
  DateTime _now() => ref.read(nowProvider)();

  @override
  List<AircraftSummary> build() => _summaries();

  List<AircraftSummary> _summaries() {
    final active = _repo.activeFlight();
    final flights = _repo.listFlights();

    final summaries = _repo.listAircraft().map((aircraft) {
      final own = flights.where((f) => f.aircraftId == aircraft.id);
      final device = aircraft.deviceTotals;

      // Cihaz sayacı geldiyse o esastır (platform kuralı: doğruluk kaynağı
      // cihazın bildirdiği ftime). Cihaz sayacı uygulamadan önceki uçuşları
      // da içerdiği için başlangıç sayacı bu durumda kullanılmaz. Cihazdan
      // gelen sorti kayıtları da sayaca zaten dahil olduğundan yalnızca elle
      // girilen uçuşlar üstüne eklenir — aksi halde çift sayılırdı.
      final counted = device == null
          ? own
          : own.where((f) => f.source == FlightSource.manual);
      final baseSorties = device?.sorties ?? aircraft.baselineSorties;

      // Cihaz sayacında alt sınır (min_known) kullanılır: kesintili sorti
      // yüzünden eksik sayarsak bakım aralığı sessizce uzar (v1.2, D2).
      final baseSeconds = device?.flightSecondsMinKnown ??
          aircraft.baselineFlightMinutes * 60;

      // Elle girilen kayıtlar arasında da alt sınır olanlar varsa
      // (ör. platformdan gelmiş kesintili sorti) belirsizlik işaretlenir.
      final hasLowerBoundFlight = counted.any((f) => f.isDurationLowerBound);

      return AircraftSummary(
        aircraft: aircraft,
        totalSorties: baseSorties + counted.length,
        totalFlightSeconds:
            baseSeconds + counted.fold(0, (sum, f) => sum + f.durationMin * 60),
        hasActiveFlight: active?.aircraftId == aircraft.id,
        usesDeviceTotals: device != null,
        countersLowConfidence:
            (device?.isLowConfidence ?? false) || hasLowerBoundFlight,
        rules: _rules,
      );
    }).toList();

    summaries.sort(
      (a, b) => a.aircraft.serialNo.toLowerCase().compareTo(
            b.aircraft.serialNo.toLowerCase(),
          ),
    );
    return summaries;
  }

  void _refresh() => state = _summaries();

  AircraftSummary? summaryFor(String aircraftId) {
    for (final s in state) {
      if (s.aircraft.id == aircraftId) return s;
    }
    return null;
  }

  List<Flight> flightsFor(String aircraftId) =>
      _repo.listFlights(aircraftId: aircraftId);

  ActiveFlight? get activeFlight => _repo.activeFlight();

  /// Yeni hava aracı ekler. Seri numarası filoda varsa
  /// [DuplicateSerialNoException] atar.
  Future<void> addAircraft({
    required String serialNo,
    required String model,
    String? shgmRegistrationNo,
    int baselineSorties = 0,
    int baselineFlightMinutes = 0,
  }) async {
    final now = _now();
    await _repo.saveAircraft(
      Aircraft(
        id: _uuid.v4(),
        serialNo: serialNo.trim(),
        model: model.trim(),
        shgmRegistrationNo: _emptyToNull(shgmRegistrationNo),
        baselineSorties: baselineSorties,
        baselineFlightMinutes: baselineFlightMinutes,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _refresh();
  }

  Future<void> updateAircraft(
    Aircraft aircraft, {
    required String serialNo,
    required String model,
    String? shgmRegistrationNo,
    required int baselineSorties,
    required int baselineFlightMinutes,
  }) async {
    final trimmedShgm = _emptyToNull(shgmRegistrationNo);
    await _repo.saveAircraft(
      aircraft.copyWith(
        serialNo: serialNo.trim(),
        model: model.trim(),
        shgmRegistrationNo: trimmedShgm,
        clearShgmRegistrationNo: trimmedShgm == null,
        baselineSorties: baselineSorties,
        baselineFlightMinutes: baselineFlightMinutes,
        updatedAt: _now(),
      ),
    );
    _refresh();
  }

  Future<void> deleteAircraft(String aircraftId) async {
    await _repo.deleteAircraft(aircraftId);
    _refresh();
  }

  Future<void> startFlight(String aircraftId) async {
    await _repo.startFlight(
      ActiveFlight(aircraftId: aircraftId, startedAt: _now()),
    );
    _refresh();
  }

  Future<void> cancelActiveFlight() async {
    await _repo.clearActiveFlight();
    _refresh();
  }

  /// Süren uçuşu bitirip kayda dönüştürür.
  ///
  /// Bir dakikadan kısa uçuşlar 1 dakika sayılır: sorti gerçekleşmiştir,
  /// sayaç 0 dakika göstermemeli.
  Future<void> finishActiveFlight({double? areaCoveredDa}) async {
    final active = _repo.activeFlight();
    if (active == null) return;

    final endedAt = _now();
    final minutes = endedAt.difference(active.startedAt).inMinutes;
    await _repo.addFlight(
      Flight(
        id: _uuid.v4(),
        aircraftId: active.aircraftId,
        startedAt: active.startedAt,
        endedAt: endedAt,
        durationMin: minutes < 1 ? 1 : minutes,
        areaCoveredDa: areaCoveredDa,
      ),
    );
    await _repo.clearActiveFlight();
    _refresh();
  }

  /// Geçmişte yapılmış bir uçuşu elle ekler (kronometre kullanılmadıysa).
  Future<void> addManualFlight({
    required String aircraftId,
    required DateTime startedAt,
    required int durationMin,
    double? areaCoveredDa,
  }) async {
    await _repo.addFlight(
      Flight(
        id: _uuid.v4(),
        aircraftId: aircraftId,
        startedAt: startedAt,
        endedAt: startedAt.add(Duration(minutes: durationMin)),
        durationMin: durationMin,
        areaCoveredDa: areaCoveredDa,
      ),
    );
    _refresh();
  }

  Future<void> deleteFlight(String flightId) async {
    await _repo.deleteFlight(flightId);
    _refresh();
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
