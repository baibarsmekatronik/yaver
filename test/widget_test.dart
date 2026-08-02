import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baibars_fleetcare/app/app.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, {Locale? locale}) async {
    // Cihaz dilini simüle et; dil çözümü çoğul `locales` listesini kullanır.
    tester.platformDispatcher.localesTestValue = [locale ?? const Locale('tr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const ProviderScope(child: FleetCareApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('giriş ekranı Türkçe açılır', (tester) async {
    await pumpApp(tester, locale: const Locale('tr'));

    expect(find.text('Hoş geldiniz'), findsOneWidget);
    expect(find.text('baibars FleetCare'), findsOneWidget);
    expect(find.text('Giriş kodu gönder'), findsOneWidget);
    expect(find.text('Çiftçinin Gökyüzündeki Dostu'), findsOneWidget);
  });

  testWidgets('desteklenmeyen cihaz dilinde Türkçe gösterilir', (tester) async {
    await pumpApp(tester, locale: const Locale('de'));

    expect(find.text('Hoş geldiniz'), findsOneWidget);
  });

  testWidgets('İngilizce cihaz dilinde İngilizce gösterilir', (tester) async {
    await pumpApp(tester, locale: const Locale('en'));

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Send sign-in code'), findsOneWidget);
    // Marka sloganı her dilde Türkçe kalır.
    expect(find.text('Çiftçinin Gökyüzündeki Dostu'), findsOneWidget);
  });

  testWidgets('geçersiz e-posta uyarı gösterir', (tester) async {
    await pumpApp(tester, locale: const Locale('tr'));

    await tester.enterText(find.byType(TextFormField), 'gecersiz-eposta');
    await tester.tap(find.text('Giriş kodu gönder'));
    await tester.pumpAndSettle();

    expect(find.text('Geçerli bir e-posta adresi yazın'), findsOneWidget);
  });

  testWidgets('geçerli e-posta ile bilgi mesajı gösterilir', (tester) async {
    await pumpApp(tester, locale: const Locale('tr'));

    await tester.enterText(find.byType(TextFormField), 'ciftci@ornek.com');
    await tester.tap(find.text('Giriş kodu gönder'));
    await tester.pump();

    expect(
      find.text('Giriş sistemi çok yakında aktif olacak.'),
      findsOneWidget,
    );
  });
}
