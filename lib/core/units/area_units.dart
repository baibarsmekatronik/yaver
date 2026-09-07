/// Alan birimi dönüşümleri.
///
/// Uygulama ve veritabanı her yerde **dekar** tutar; dönüşüm yalnızca veri
/// girerken (platformdan gelen kayıtlar) ve gösterirken yapılır. Böylece
/// aynı alan iki farklı birimde saklanıp karışmaz.
abstract final class AreaUnits {
  /// Çin kaynaklı uçuş verisi alanı *mu* biriminde bildiriyor.
  /// Katsayı platform yol haritasından: 1 mu = 0,6667 dekar.
  static const double muToDekar = 0.6667;

  /// 1 hektar = 10 dekar.
  static const double hectareToDekar = 10;

  static double fromMu(double mu) => mu * muToDekar;

  static double fromHectare(double hectare) => hectare * hectareToDekar;

  static double toHectare(double dekar) => dekar / hectareToDekar;
}
