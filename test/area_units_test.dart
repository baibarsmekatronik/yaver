import 'package:baibars_fleetcare/core/units/area_units.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mu dekara çevrilir', () {
    // Yol haritasındaki katsayı: 1 mu = 0,6667 dekar.
    expect(AreaUnits.fromMu(1), closeTo(0.6667, 1e-9));
    expect(AreaUnits.fromMu(150), closeTo(100.005, 1e-6));
  });

  test('hektar ve dekar karşılıklı çevrilir', () {
    expect(AreaUnits.fromHectare(2.5), 25);
    expect(AreaUnits.toHectare(25), 2.5);
    expect(AreaUnits.toHectare(AreaUnits.fromHectare(7.3)), closeTo(7.3, 1e-9));
  });
}
