/// Cihazın kendi bildirdiği ömür sayaçları (platform `airframe_totals`).
///
/// Platform yol haritasının sabit kuralı: uçuş saatinin doğruluk kaynağı
/// cihazın bildirdiği `ftime` değeridir — duvar saati değil. Bu değer
/// geldiğinde uygulamadaki elle sayaç tahmini yerine bu kullanılır.
class AirframeTotals {
  final int sorties;
  final int flightMinutes;

  /// Platformun bu değerleri en son ne zaman bildirdiği.
  /// Bağlantı koptuğunda sayacın ne kadar eski olduğunu göstermek için tutulur.
  final DateTime asOf;

  const AirframeTotals({
    required this.sorties,
    required this.flightMinutes,
    required this.asOf,
  });

  Map<String, dynamic> toJson() => {
        'sorties': sorties,
        'flight_minutes': flightMinutes,
        'as_of': asOf.toIso8601String(),
      };

  factory AirframeTotals.fromJson(Map<String, dynamic> json) => AirframeTotals(
        sorties: (json['sorties'] as num).toInt(),
        flightMinutes: (json['flight_minutes'] as num).toInt(),
        asOf: DateTime.parse(json['as_of'] as String),
      );
}

/// Filodaki bir hava aracı (platform şemasında `drones`).
///
/// `model` bilinçli olarak serbest metin: uygulama CT110 ile başlıyor ama
/// CT33s Pro / CT50s Pro sonradan eklenebilsin diye modele özel varsayım
/// koda gömülmüyor.
class Aircraft {
  final String id;
  final String serialNo;
  final String model;
  final String? shgmRegistrationNo;

  /// baibars platformundaki `drones.id`. Eşitleme anahtarıdır: aynı hava aracı
  /// hem burada hem platformda varsa bu alan sayesinde çift kayıt oluşmaz.
  /// Platforma bağlanmadan önce null.
  final String? platformId;

  /// Müşteri hesabı (platform `tenant_id`). Bir müşteri yalnızca kendi
  /// İHA'larını görür; teslimatta atanır. Bağlantı öncesi null.
  final String? tenantId;

  /// Cihazın bildirdiği ömür sayaçları. Doluysa sayaç hesabında
  /// [baselineSorties] / [baselineFlightMinutes] yerine bu kullanılır —
  /// cihaz sayacı uygulamadan önceki uçuşları da zaten içerir.
  final AirframeTotals? deviceTotals;

  /// Uygulamaya kaydedilmeden önce yapılmış sorti sayısı.
  /// Kullanılmış bir hava aracı filoya eklendiğinde sayaç sıfırdan başlamasın.
  /// Yalnızca cihaz sayacı yokken kullanılır.
  final int baselineSorties;

  /// Uygulamaya kaydedilmeden önceki uçuş süresi (dakika).
  /// Dakika tutuluyor; saat gösterimi bölme ile yapılıyor ki yuvarlama
  /// hatası birikmesin.
  final int baselineFlightMinutes;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Aircraft({
    required this.id,
    required this.serialNo,
    required this.model,
    this.shgmRegistrationNo,
    this.platformId,
    this.tenantId,
    this.deviceTotals,
    this.baselineSorties = 0,
    this.baselineFlightMinutes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Aircraft copyWith({
    String? serialNo,
    String? model,
    String? shgmRegistrationNo,
    bool clearShgmRegistrationNo = false,
    String? platformId,
    String? tenantId,
    AirframeTotals? deviceTotals,
    int? baselineSorties,
    int? baselineFlightMinutes,
    DateTime? updatedAt,
  }) {
    return Aircraft(
      id: id,
      serialNo: serialNo ?? this.serialNo,
      model: model ?? this.model,
      shgmRegistrationNo: clearShgmRegistrationNo
          ? null
          : (shgmRegistrationNo ?? this.shgmRegistrationNo),
      platformId: platformId ?? this.platformId,
      tenantId: tenantId ?? this.tenantId,
      deviceTotals: deviceTotals ?? this.deviceTotals,
      baselineSorties: baselineSorties ?? this.baselineSorties,
      baselineFlightMinutes:
          baselineFlightMinutes ?? this.baselineFlightMinutes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'serial_no': serialNo,
        'model': model,
        'shgm_registration_no': shgmRegistrationNo,
        'platform_id': platformId,
        'tenant_id': tenantId,
        'device_totals': deviceTotals?.toJson(),
        'baseline_sorties': baselineSorties,
        'baseline_flight_minutes': baselineFlightMinutes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Eski kayıtlarda yeni alanlar bulunmaz; hepsi isteğe bağlı okunuyor ki
  /// güncellemeden sonra cihazdaki mevcut veri kaybolmasın.
  factory Aircraft.fromJson(Map<String, dynamic> json) => Aircraft(
        id: json['id'] as String,
        serialNo: json['serial_no'] as String,
        model: json['model'] as String,
        shgmRegistrationNo: json['shgm_registration_no'] as String?,
        platformId: json['platform_id'] as String?,
        tenantId: json['tenant_id'] as String?,
        deviceTotals: json['device_totals'] == null
            ? null
            : AirframeTotals.fromJson(
                json['device_totals'] as Map<String, dynamic>,
              ),
        baselineSorties: (json['baseline_sorties'] as num?)?.toInt() ?? 0,
        baselineFlightMinutes:
            (json['baseline_flight_minutes'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
