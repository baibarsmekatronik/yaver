import 'package:baibars_fleetcare/app/app.dart';
import 'package:baibars_fleetcare/core/storage/local_store.dart';
import 'package:baibars_fleetcare/features/fleet/application/fleet_controller.dart';
import 'package:baibars_fleetcare/features/fleet/data/local_fleet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryLocalStore store;

  setUp(() => store = InMemoryLocalStore());

  Future<void> pumpApp(WidgetTester tester, {Locale locale = const Locale('tr')}) async {
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fleetRepositoryProvider
              .overrideWithValue(LocalFleetRepository.open(store)),
        ],
        child: const FleetCareApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Form doldurup kaydeden ortak adım.
  Future<void> addAircraft(
    WidgetTester tester, {
    required String serialNo,
    String sorties = '0',
    String hours = '0',
  }) async {
    await tester.tap(find.text('İHA ekle'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Seri numarası'),
      serialNo,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Şu ana kadarki sorti sayısı'),
      sorties,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Şu ana kadarki uçuş saati (sa)'),
      hours,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
    await tester.pumpAndSettle();
  }

  /// Bildirim çubuğu ekranın altındaki butonların üstüne biniyor; sonraki
  /// dokunuşlar bildirime denk gelmesin diye kaybolması beklenir.
  Future<void> dismissSnackBar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('filo boşken yönlendirme metni gösterilir', (tester) async {
    await pumpApp(tester);

    expect(find.text("İHA'larım"), findsOneWidget);
    expect(find.text('Henüz İHA eklemediniz'), findsOneWidget);
  });

  testWidgets('İngilizce cihazda arayüz İngilizce gelir', (tester) async {
    await pumpApp(tester, locale: const Locale('en'));

    expect(find.text('My UAVs'), findsOneWidget);
    expect(find.text('No UAV added yet'), findsOneWidget);
  });

  testWidgets('İHA eklenince listede sayaçlarıyla görünür', (tester) async {
    await pumpApp(tester);
    await addAircraft(
      tester,
      serialNo: 'BAI-2026-001',
      sorties: '40',
      hours: '7,5',
    );

    expect(find.text('BAI-2026-001'), findsOneWidget);
    expect(find.text('CT110'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
    // Virgüllü giriş de kabul edilmeli (Türkçe klavye).
    expect(find.text('7.5'), findsOneWidget);
    expect(find.text('Takipte'), findsOneWidget);
  });

  testWidgets('aynı seri numarası ikinci kez kaydedilemez', (tester) async {
    await pumpApp(tester);
    await addAircraft(tester, serialNo: 'BAI-2026-001');
    await dismissSnackBar(tester);
    await addAircraft(tester, serialNo: 'BAI-2026-001');

    expect(find.text('Bu seri numarası zaten kayıtlı'), findsOneWidget);
  });

  testWidgets('seri numarası boşken uyarı verir', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('İHA ekle'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('Bu alanı doldurun'), findsOneWidget);
  });

  testWidgets('bakım yaklaşınca kartta uyarı çıkar', (tester) async {
    await pumpApp(tester);
    await addAircraft(tester, serialNo: 'BAI-2026-001', sorties: '95');

    expect(find.text('Bakım yaklaşıyor'), findsOneWidget);
    expect(
      find.text('Kol katlama vidası kontrolüne 5 sorti kaldı'),
      findsOneWidget,
    );
  });

  testWidgets('detayda uçuş başlatılıp bitirilince sorti artar',
      (tester) async {
    await pumpApp(tester);
    await addAircraft(tester, serialNo: 'BAI-2026-001');
    await dismissSnackBar(tester);

    await tester.tap(find.text('BAI-2026-001'));
    await tester.pumpAndSettle();

    expect(find.text('Henüz uçuş kaydı yok'), findsOneWidget);

    // Uçuş sürerken kronometre her saniye kare çizdiği için pumpAndSettle
    // yerine sabit adımlarla ilerleniyor.
    await tester.tap(find.text('Uçuşu başlat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Uçuş sürüyor'), findsOneWidget);

    await tester.tap(find.text('Uçuşu bitir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Uçuş kaydedildi'), findsOneWidget);
    expect(find.text('Henüz uçuş kaydı yok'), findsNothing);
    // Sorti sayacı 1 oldu.
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('elle uçuş eklenince kayıt listesine düşer', (tester) async {
    await pumpApp(tester);
    await addAircraft(tester, serialNo: 'BAI-2026-001');
    await dismissSnackBar(tester);

    await tester.tap(find.text('BAI-2026-001'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Elle uçuş ekle'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Süre (dakika)'),
      '12',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('Uçuş kaydedildi'), findsOneWidget);
    expect(find.textContaining('12 dk'), findsOneWidget);
  });
}
