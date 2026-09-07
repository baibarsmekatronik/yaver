import 'aircraft.dart';
import 'maintenance_rule.dart';

/// Faz 1'de gösterilebilen bakım durumu.
///
/// Kırmızı ("uçma, önce kontrol") bilinçli olarak yok: bir kontrolün
/// gecikmiş olduğunu söyleyebilmek için o kontrolün ne zaman yapıldığını
/// bilmek gerekir; tamamlanma kaydı Faz 2'de geliyor. O yüzden şimdilik
/// yalnızca "takipte" ve "yaklaşıyor" gösteriliyor.
enum FleetHealth { tracking, dueSoon }

/// Bir sonraki periyodik kontrole ne kadar kaldığı.
class UpcomingCheck {
  final MaintenanceRule rule;

  /// Kontrole kalan miktar: sorti adedi veya uçuş saati.
  final int remaining;

  const UpcomingCheck({required this.rule, required this.remaining});

  bool get isDueSoon => remaining <= rule.warnBefore;
}

/// Hava aracı + hesaplanmış sayaçlar (liste ve detay ekranlarının verisi).
class AircraftSummary {
  final Aircraft aircraft;

  /// Toplam sorti. Cihaz sayacı varsa ondan, yoksa başlangıç sayacı +
  /// uygulamada kaydedilen uçuşlardan gelir.
  final int totalSorties;

  /// Toplam uçuş süresi (saniye). Cihaz sayacı varken **alt sınır**
  /// (`min_known`) kullanılır — bakım aralığını sessizce uzatmamak için.
  final int totalFlightSeconds;

  /// Bu hava aracında şu an sürmekte olan bir uçuş var mı.
  final bool hasActiveFlight;

  /// Sayaçlar cihazın kendi bildirdiği değerlere mi dayanıyor.
  final bool usesDeviceTotals;

  /// Kesintili sorti nedeniyle sayacın altında belirsizlik var mı
  /// (yol haritası v1.2, D2). Doğruysa gösterilen süre alt sınırdır ve
  /// bakım uyarısı bu belirsizliği görünür kılmalıdır.
  final bool countersLowConfidence;

  /// Bu hava aracı için geçerli bakım kuralları — veriden gelir, koda gömülü
  /// değildir (yol haritası v1.2: aralıklar `maintenance_rules` tablosunda).
  final List<MaintenanceRule> rules;

  const AircraftSummary({
    required this.aircraft,
    required this.totalSorties,
    required this.totalFlightSeconds,
    this.hasActiveFlight = false,
    this.usesDeviceTotals = false,
    this.countersLowConfidence = false,
    this.rules = const [],
  });

  int get totalFlightMinutes => totalFlightSeconds ~/ 60;

  double get totalFlightHours => totalFlightSeconds / 3600;

  /// Sayaçla değerlendirilebilen ve baibars'ın onayladığı kurallar.
  ///
  /// Onay bekleyen (TBD) aralıklar çiftçiye kesin bilgi gibi gösterilmez;
  /// takvim ve döngü tabanlı kurallar sırasıyla Faz 2 ve Faz 4'te devreye girer.
  List<MaintenanceRule> get _activeRules => rules
      .where((r) =>
          !r.isTbd && r.isCounterEvaluable && r.appliesTo(aircraft.model))
      .toList();

  /// Oransal olarak en yakın kontrol. Değerlendirilebilir kural yoksa null.
  UpcomingCheck? get nextCheck {
    UpcomingCheck? closest;
    double closestRatio = double.infinity;

    for (final rule in _activeRules) {
      final counter = rule.intervalType == MaintenanceIntervalType.sortie
          ? totalSorties
          : totalFlightHours.floor();
      final remaining = rule.intervalValue - (counter % rule.intervalValue);
      final ratio = remaining / rule.intervalValue;

      if (ratio < closestRatio) {
        closestRatio = ratio;
        closest = UpcomingCheck(rule: rule, remaining: remaining);
      }
    }
    return closest;
  }

  FleetHealth get health =>
      (nextCheck?.isDueSoon ?? false) ? FleetHealth.dueSoon : FleetHealth.tracking;
}
