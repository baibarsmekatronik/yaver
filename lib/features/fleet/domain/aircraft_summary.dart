import 'aircraft.dart';

/// Faz 1'de gösterilebilen bakım durumu.
///
/// Kırmızı ("uçma, önce kontrol") bilinçli olarak yok: bir kontrolün
/// gecikmiş olduğunu söyleyebilmek için o kontrolün ne zaman yapıldığını
/// bilmek gerekir; tamamlanma kaydı Faz 2'de geliyor. O yüzden şimdilik
/// yalnızca "takipte" ve "yaklaşıyor" gösteriliyor.
enum FleetHealth { tracking, dueSoon }

/// Yaklaşan kontrolün hangi sayaca bağlı olduğu.
enum UpcomingCheckBasis { sortie, hours }

/// Bir sonraki periyodik kontrole ne kadar kaldığı.
class UpcomingCheck {
  final UpcomingCheckBasis basis;

  /// Kontrole kalan miktar: sorti adedi veya uçuş saati.
  final int remaining;

  const UpcomingCheck({required this.basis, required this.remaining});
}

/// Hava aracı + hesaplanmış sayaçlar (liste ve detay ekranlarının verisi).
class AircraftSummary {
  final Aircraft aircraft;

  /// Başlangıç sayacı + uygulamada kaydedilen uçuşlar.
  final int totalSorties;
  final int totalFlightMinutes;

  /// Bu hava aracında şu an sürmekte olan bir uçuş var mı.
  final bool hasActiveFlight;

  const AircraftSummary({
    required this.aircraft,
    required this.totalSorties,
    required this.totalFlightMinutes,
    this.hasActiveFlight = false,
  });

  double get totalFlightHours => totalFlightMinutes / 60;

  /// baibars mühendisliğince doğrulanmış aralıklar (CLAUDE.md).
  /// TBD işaretli aralıklar burada bilinçli olarak yok — onaylanmadan
  /// çiftçiye kesin bilgi gibi gösterilmez.
  static const int armBoltSortieInterval = 100;
  static const int motorTorqueHourInterval = 100;

  /// "Yaklaşıyor" uyarısının ne kadar erken çıkacağı. Bu bir bakım aralığı
  /// değil, yalnızca arayüz eşiği — baibars isterse değiştirilebilir.
  static const int warnBeforeSorties = 10;
  static const int warnBeforeHours = 10;

  /// Kalan miktarı en az olan yaklaşan kontrol.
  UpcomingCheck get nextCheck {
    final sortiesLeft =
        armBoltSortieInterval - (totalSorties % armBoltSortieInterval);
    final hoursLeft =
        motorTorqueHourInterval - (totalFlightHours.floor() % motorTorqueHourInterval);

    // İki kontrolden hangisi oransal olarak daha yakınsa onu göster.
    final sortieRatio = sortiesLeft / armBoltSortieInterval;
    final hourRatio = hoursLeft / motorTorqueHourInterval;

    return sortieRatio <= hourRatio
        ? UpcomingCheck(basis: UpcomingCheckBasis.sortie, remaining: sortiesLeft)
        : UpcomingCheck(basis: UpcomingCheckBasis.hours, remaining: hoursLeft);
  }

  FleetHealth get health {
    final check = nextCheck;
    final threshold = check.basis == UpcomingCheckBasis.sortie
        ? warnBeforeSorties
        : warnBeforeHours;
    return check.remaining <= threshold
        ? FleetHealth.dueSoon
        : FleetHealth.tracking;
  }
}
