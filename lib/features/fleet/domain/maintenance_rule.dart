/// Bakım aralığının hangi sayaca bağlı olduğu.
enum MaintenanceIntervalType { sortie, hours, calendar, cycles }

/// Bir bakım kaydının sayacı nasıl etkilediği (yol haritası v1.2, D6).
///
/// İş emrinin kapanması tek başına sayacı sıfırlamaz: 800 saatlik bir motor,
/// üzerinde göz kontrolü yapıldı diye 0 saatlik motora dönüşmemeli.
enum MaintenanceResetAction {
  /// Muayene edildi — yalnızca o kuralın muayene başlangıcı sıfırlanır.
  inspected,

  /// Değiştirildi — eski parça kaydı kapanır, yenisi 0 saatten başlar.
  replaced,

  /// Onarıldı — yalnızca kural izin veriyorsa sıfırlar.
  repaired,
}

/// Bir periyodik bakım kuralı (platform şemasında `maintenance_rules`).
///
/// Aralıklar koda gömülmez: baibars bir aralığı güncellediğinde uygulama
/// yeniden yayınlanmamalı. Bu sınıf veriden okunur; [maintenanceRulesSeed]
/// yalnızca ilk kurulum tohumudur.
class MaintenanceRule {
  final String id;

  /// Hangi modele ait. null = tüm modeller için geçerli.
  final String? model;

  final String? componentType;
  final String labelTr;
  final String labelEn;

  final MaintenanceIntervalType intervalType;
  final int intervalValue;

  /// "Yaklaşıyor" uyarısının kaç birim önce çıkacağı (sorti adedi / saat).
  final int warnBefore;

  /// baibars mühendisliği bu aralığı henüz onaylamadıysa true.
  /// Onaysız aralıklar çiftçiye kesin bilgi gibi gösterilmez.
  final bool isTbd;

  /// Bu kuralın sayacını hangi işlemler sıfırlar (D6).
  final Set<MaintenanceResetAction> validResetActions;

  /// Kural sürümü ve yürürlük tarihi (D6): aralık değiştiğinde geçmiş
  /// kayıtlar hangi sürüme göre kapandığını bilmeli.
  final int ruleVersion;
  final DateTime effectiveFrom;

  const MaintenanceRule({
    required this.id,
    this.model,
    this.componentType,
    required this.labelTr,
    required this.labelEn,
    required this.intervalType,
    required this.intervalValue,
    required this.warnBefore,
    this.isTbd = false,
    required this.validResetActions,
    this.ruleVersion = 1,
    required this.effectiveFrom,
  });

  /// Faz 1'de yalnızca sorti ve uçuş saati sayaçları değerlendirilebiliyor.
  /// Takvim ve döngü tabanlı kurallar son yapılma tarihini/batarya verisini
  /// gerektiriyor — sırasıyla Faz 2 ve Faz 4.
  bool get isCounterEvaluable =>
      intervalType == MaintenanceIntervalType.sortie ||
      intervalType == MaintenanceIntervalType.hours;

  bool appliesTo(String aircraftModel) => model == null || model == aircraftModel;

  /// Kural adı, arayüz diline göre. Kural adları veriden geldiği için
  /// ARB dosyalarında değil burada tutulur.
  String label(String languageCode) => languageCode == 'tr' ? labelTr : labelEn;
}
