import 'dart:convert';

import '../../../core/storage/local_store.dart';
import '../domain/aircraft.dart';
import '../domain/flight.dart';
import 'fleet_repository.dart';

/// Filo verisini cihazda tutan uygulama (offline-first).
///
/// Veri bellekte tutulur, her değişiklikte yerel depoya JSON olarak yazılır.
/// Filo birkaç hava aracı ölçeğinde olduğu için bu yeterli; veri büyüdüğünde
/// yalnızca bu sınıf drift/sqflite ile değiştirilecek.
class LocalFleetRepository implements FleetRepository {
  static const _aircraftKey = 'fleet.aircraft';
  static const _flightsKey = 'fleet.flights';
  static const _activeFlightKey = 'fleet.active_flight';

  final LocalStore _store;

  final List<Aircraft> _aircraft;
  final List<Flight> _flights;
  ActiveFlight? _activeFlight;

  LocalFleetRepository._(
    this._store,
    this._aircraft,
    this._flights,
    this._activeFlight,
  );

  /// Yerel depodaki veriyi okuyup depoyu hazırlar.
  ///
  /// Bozuk/eski biçimli kayıt varsa uygulama açılmamazlık etmesin diye
  /// o anahtar boş kabul edilir.
  factory LocalFleetRepository.open(LocalStore store) {
    final aircraft = _decodeList(
      store.read(_aircraftKey),
      Aircraft.fromJson,
    );
    final flights = _decodeList(store.read(_flightsKey), Flight.fromJson);

    ActiveFlight? active;
    final activeRaw = store.read(_activeFlightKey);
    if (activeRaw != null) {
      try {
        active = ActiveFlight.fromJson(
          jsonDecode(activeRaw) as Map<String, dynamic>,
        );
      } on Object {
        active = null;
      }
    }

    return LocalFleetRepository._(store, aircraft, flights, active);
  }

  static List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(growable: true);
    } on Object {
      return [];
    }
  }

  @override
  List<Aircraft> listAircraft() => List.unmodifiable(_aircraft);

  @override
  List<Flight> listFlights({String? aircraftId}) {
    final result = aircraftId == null
        ? [..._flights]
        : _flights.where((f) => f.aircraftId == aircraftId).toList();
    // En yeni uçuş en üstte.
    result.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return List.unmodifiable(result);
  }

  @override
  ActiveFlight? activeFlight() => _activeFlight;

  @override
  Future<void> saveAircraft(Aircraft aircraft) async {
    final clash = _aircraft.any(
      (a) =>
          a.id != aircraft.id &&
          a.serialNo.toLowerCase() == aircraft.serialNo.toLowerCase(),
    );
    if (clash) throw DuplicateSerialNoException(aircraft.serialNo);

    final index = _aircraft.indexWhere((a) => a.id == aircraft.id);
    if (index >= 0) {
      _aircraft[index] = aircraft;
    } else {
      _aircraft.add(aircraft);
    }
    await _persistAircraft();
  }

  @override
  Future<void> deleteAircraft(String aircraftId) async {
    _aircraft.removeWhere((a) => a.id == aircraftId);
    _flights.removeWhere((f) => f.aircraftId == aircraftId);
    if (_activeFlight?.aircraftId == aircraftId) {
      _activeFlight = null;
      await _store.delete(_activeFlightKey);
    }
    await _persistAircraft();
    await _persistFlights();
  }

  @override
  Future<void> addFlight(Flight flight) async {
    _flights.add(flight);
    await _persistFlights();
  }

  @override
  Future<void> deleteFlight(String flightId) async {
    _flights.removeWhere((f) => f.id == flightId);
    await _persistFlights();
  }

  @override
  Future<void> startFlight(ActiveFlight active) async {
    _activeFlight = active;
    await _store.write(_activeFlightKey, jsonEncode(active.toJson()));
  }

  @override
  Future<void> clearActiveFlight() async {
    _activeFlight = null;
    await _store.delete(_activeFlightKey);
  }

  Future<void> _persistAircraft() => _store.write(
        _aircraftKey,
        jsonEncode(_aircraft.map((a) => a.toJson()).toList()),
      );

  Future<void> _persistFlights() => _store.write(
        _flightsKey,
        jsonEncode(_flights.map((f) => f.toJson()).toList()),
      );
}
