import 'dart:convert';

import 'package:baibars_fleetcare/core/storage/local_store.dart';
import 'package:baibars_fleetcare/features/fleet/application/fleet_controller.dart';
import 'package:baibars_fleetcare/features/fleet/data/fleet_repository.dart';
import 'package:baibars_fleetcare/features/fleet/data/local_fleet_repository.dart';
import 'package:baibars_fleetcare/features/fleet/domain/aircraft.dart';
import 'package:baibars_fleetcare/features/fleet/domain/aircraft_summary.dart';
import 'package:baibars_fleetcare/features/fleet/domain/flight.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryLocalStore store;
  late DateTime clock;

  /// Testler zamanı kendileri ilerletsin diye saat sabitlendi.
  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        fleetRepositoryProvider
            .overrideWithValue(LocalFleetRepository.open(store)),
        nowProvider.overrideWithValue(() => clock),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    store = InMemoryLocalStore();
    clock = DateTime(2026, 8, 2, 9);
  });

  test('yeni İHA başlangıç sayaçlarıyla eklenir', () async {
    final container = makeContainer();
    final controller = container.read(fleetControllerProvider.notifier);

    await controller.addAircraft(
      serialNo: 'BAI-2026-001',
      model: 'CT110',
      baselineSorties: 40,
      baselineFlightMinutes: 450,
    );

    final fleet = container.read(fleetControllerProvider);
    expect(fleet, hasLength(1));
    expect(fleet.single.totalSorties, 40);
    expect(fleet.single.totalFlightHours, 7.5);
  });

  test('aynı seri numarası ikinci kez eklenemez', () async {
    final container = makeContainer();
    final controller = container.read(fleetControllerProvider.notifier);

    await controller.addAircraft(serialNo: 'BAI-2026-001', model: 'CT110');

    expect(
      () => controller.addAircraft(serialNo: 'bai-2026-001', model: 'CT110'),
      throwsA(isA<DuplicateSerialNoException>()),
    );
  });

  test('kronometreyle uçuş sayaçları artırır', () async {
    final container = makeContainer();
    final controller = container.read(fleetControllerProvider.notifier);

    await controller.addAircraft(serialNo: 'BAI-2026-001', model: 'CT110');
    final id = container.read(fleetControllerProvider).single.aircraft.id;

    await controller.startFlight(id);
    expect(container.read(fleetControllerProvider).single.hasActiveFlight, isTrue);

    clock = clock.add(const Duration(minutes: 12));
    await controller.finishActiveFlight(areaCoveredDa: 35);

    final summary = container.read(fleetControllerProvider).single;
    expect(summary.hasActiveFlight, isFalse);
    expect(summary.totalSorties, 1);
    expect(summary.totalFlightMinutes, 12);
  });

  test('bir dakikadan kısa uçuş 1 dakika sayılır', () async {
    final container = makeContainer();
    final controller = container.read(fleetControllerProvider.notifier);

    await controller.addAircraft(serialNo: 'BAI-2026-001', model: 'CT110');
    final id = container.read(fleetControllerProvider).single.aircraft.id;

    await controller.startFlight(id);
    clock = clock.add(const Duration(seconds: 20));
    await controller.finishActiveFlight();

    expect(container.read(fleetControllerProvider).single.totalFlightMinutes, 1);
  });

  test('iptal edilen uçuş kayıt oluşturmaz', () async {
    final container = makeContainer();
    final controller = container.read(fleetControllerProvider.notifier);

    await controller.addAircraft(serialNo: 'BAI-2026-001', model: 'CT110');
    final id = container.read(fleetControllerProvider).single.aircraft.id;

    await controller.startFlight(id);
    clock = clock.add(const Duration(minutes: 5));
    await controller.cancelActiveFlight();

    final summary = container.read(fleetControllerProvider).single;
    expect(summary.totalSorties, 0);
    expect(summary.totalFlightMinutes, 0);
    expect(controller.flightsFor(id), isEmpty);
  });

  test('elle eklenen uçuş kayda ve sayaca yansır', () async {
    final container = makeContainer();
    final controller = container.read(fleetControllerProvider.notifier);

    await controller.addAircraft(serialNo: 'BAI-2026-001', model: 'CT110');
    final id = container.read(fleetControllerProvider).single.aircraft.id;

    await controller.addManualFlight(
      aircraftId: id,
      startedAt: DateTime(2026, 7, 30),
      durationMin: 9,
      areaCoveredDa: 20,
    );

    expect(container.read(fleetControllerProvider).single.totalSorties, 1);
    expect(controller.flightsFor(id).single.durationMin, 9);
  });

  test('uçuş silinince sayaç geri düşer', () async {
    final container = makeContainer();
    final controller = container.read(fleetControllerProvider.notifier);

    await controller.addAircraft(serialNo: 'BAI-2026-001', model: 'CT110');
    final id = container.read(fleetControllerProvider).single.aircraft.id;
    await controller.addManualFlight(
      aircraftId: id,
      startedAt: clock,
      durationMin: 10,
    );

    await controller.deleteFlight(controller.flightsFor(id).single.id);

    final summary = container.read(fleetControllerProvider).single;
    expect(summary.totalSorties, 0);
    expect(summary.totalFlightMinutes, 0);
  });

  test('İHA silinince uçuş kayıtları da silinir', () async {
    final container = makeContainer();
    final controller = container.read(fleetControllerProvider.notifier);

    await controller.addAircraft(serialNo: 'BAI-2026-001', model: 'CT110');
    final id = container.read(fleetControllerProvider).single.aircraft.id;
    await controller.addManualFlight(
      aircraftId: id,
      startedAt: clock,
      durationMin: 10,
    );

    await controller.deleteAircraft(id);

    expect(container.read(fleetControllerProvider), isEmpty);
    expect(controller.flightsFor(id), isEmpty);
  });

  test('veri uygulama yeniden açıldığında kaybolmaz', () async {
    final first = makeContainer();
    await first.read(fleetControllerProvider.notifier).addAircraft(
          serialNo: 'BAI-2026-001',
          model: 'CT110',
          baselineSorties: 5,
        );

    // Aynı yerel depoyla yeni bir oturum aç.
    final second = makeContainer();
    final fleet = second.read(fleetControllerProvider);

    expect(fleet, hasLength(1));
    expect(fleet.single.aircraft.serialNo, 'BAI-2026-001');
    expect(fleet.single.totalSorties, 5);
  });

  test('süren uçuş yeniden açılışta korunur', () async {
    final first = makeContainer();
    final controller = first.read(fleetControllerProvider.notifier);
    await controller.addAircraft(serialNo: 'BAI-2026-001', model: 'CT110');
    final id = first.read(fleetControllerProvider).single.aircraft.id;
    await controller.startFlight(id);

    final second = makeContainer();
    expect(second.read(fleetControllerProvider).single.hasActiveFlight, isTrue);
  });

  group('platform eşitlemesi — cihaz sayacı', () {
    /// Cihaz sayacı ve sorti kayıtları eşitlemeyle gelir; burada yerel depoya
    /// doğrudan yazılarak JSON okuması da birlikte sınanıyor.
    void seed({
      Map<String, dynamic>? deviceTotals,
      List<Map<String, dynamic>> flights = const [],
    }) {
      store = InMemoryLocalStore({
        'fleet.aircraft': jsonEncode([
          {
            'id': 'a1',
            'serial_no': 'BAI-2026-001',
            'model': 'CT110',
            'platform_id': 'drone-77',
            'tenant_id': 'tenant-5',
            'device_totals': deviceTotals,
            'baseline_sorties': 30,
            'baseline_flight_minutes': 600,
            'created_at': '2026-08-01T09:00:00.000',
            'updated_at': '2026-08-01T09:00:00.000',
          }
        ]),
        'fleet.flights': jsonEncode(flights),
      });
    }

    Map<String, dynamic> flightJson({
      required String id,
      required int durationMin,
      String? source,
    }) =>
        {
          'id': id,
          'aircraft_id': 'a1',
          'started_at': '2026-08-02T09:00:00.000',
          'ended_at': '2026-08-02T09:10:00.000',
          'duration_min': durationMin,
          if (source != null) 'source': source,
        };

    test('cihaz sayacı varsa başlangıç sayacı kullanılmaz', () {
      seed(
        deviceTotals: {
          'sorties': 120,
          'flight_minutes': 1800,
          'as_of': '2026-09-07T08:00:00.000',
        },
      );

      final summary = makeContainer().read(fleetControllerProvider).single;
      // Başlangıç sayacı (30 sorti / 600 dk) yok sayılmalı: cihaz sayacı
      // uygulamadan önceki uçuşları zaten içeriyor.
      expect(summary.totalSorties, 120);
      expect(summary.totalFlightHours, 30);
      expect(summary.usesDeviceTotals, isTrue);
    });

    test('cihazdan gelen sortiler cihaz sayacına ikinci kez eklenmez', () {
      seed(
        deviceTotals: {
          'sorties': 120,
          'flight_minutes': 1800,
          'as_of': '2026-09-07T08:00:00.000',
        },
        flights: [
          flightJson(id: 'f1', durationMin: 12, source: 'device'),
          flightJson(id: 'f2', durationMin: 9, source: 'device'),
        ],
      );

      final summary = makeContainer().read(fleetControllerProvider).single;
      expect(summary.totalSorties, 120);
      expect(summary.totalFlightMinutes, 1800);
    });

    test('cihaz sayacı varken elle girilen uçuşlar üstüne eklenir', () {
      seed(
        deviceTotals: {
          'sorties': 120,
          'flight_minutes': 1800,
          'as_of': '2026-09-07T08:00:00.000',
        },
        flights: [
          flightJson(id: 'f1', durationMin: 12, source: 'device'),
          flightJson(id: 'f2', durationMin: 15, source: 'manual'),
        ],
      );

      final summary = makeContainer().read(fleetControllerProvider).single;
      expect(summary.totalSorties, 121);
      expect(summary.totalFlightMinutes, 1815);
    });

    test('cihaz sayacı yoksa eski davranış korunur', () {
      seed(flights: [flightJson(id: 'f1', durationMin: 20, source: 'manual')]);

      final summary = makeContainer().read(fleetControllerProvider).single;
      expect(summary.totalSorties, 31);
      expect(summary.totalFlightMinutes, 620);
      expect(summary.usesDeviceTotals, isFalse);
    });

    test('güncelleme öncesi kayıtlar (source alanı yok) elle sayılır', () {
      seed(flights: [flightJson(id: 'f1', durationMin: 20)]);

      final container = makeContainer();
      final summary = container.read(fleetControllerProvider).single;
      expect(summary.totalSorties, 31);
      expect(
        container
            .read(fleetControllerProvider.notifier)
            .flightsFor('a1')
            .single
            .source,
        FlightSource.manual,
      );
    });

    test('platform kimlikleri okunur ve korunur', () {
      seed();
      final aircraft =
          makeContainer().read(fleetControllerProvider).single.aircraft;

      expect(aircraft.platformId, 'drone-77');
      expect(aircraft.tenantId, 'tenant-5');
      // Kaydedilip geri okunduğunda kaybolmamalı.
      final roundTripped = Aircraft.fromJson(aircraft.toJson());
      expect(roundTripped.platformId, 'drone-77');
      expect(roundTripped.tenantId, 'tenant-5');
    });
  });

  group('yaklaşan bakım', () {
    test('sayaç aralığın uzağındayken takipte gösterilir', () async {
      final container = makeContainer();
      await container.read(fleetControllerProvider.notifier).addAircraft(
            serialNo: 'BAI-2026-001',
            model: 'CT110',
            baselineSorties: 20,
          );

      final summary = container.read(fleetControllerProvider).single;
      expect(summary.health, FleetHealth.tracking);
      expect(summary.nextCheck.basis, UpcomingCheckBasis.sortie);
      expect(summary.nextCheck.remaining, 80);
    });

    test('100 sortiye yaklaşınca uyarı verir', () async {
      final container = makeContainer();
      await container.read(fleetControllerProvider.notifier).addAircraft(
            serialNo: 'BAI-2026-001',
            model: 'CT110',
            baselineSorties: 95,
          );

      final summary = container.read(fleetControllerProvider).single;
      expect(summary.health, FleetHealth.dueSoon);
      expect(summary.nextCheck.remaining, 5);
    });

    test('saat sayacı daha yakınsa saat kontrolü gösterilir', () async {
      final container = makeContainer();
      await container.read(fleetControllerProvider.notifier).addAircraft(
            serialNo: 'BAI-2026-001',
            model: 'CT110',
            baselineSorties: 10,
            baselineFlightMinutes: 95 * 60,
          );

      final summary = container.read(fleetControllerProvider).single;
      expect(summary.nextCheck.basis, UpcomingCheckBasis.hours);
      expect(summary.nextCheck.remaining, 5);
      expect(summary.health, FleetHealth.dueSoon);
    });
  });
}
