/// Filodaki bir hava aracı.
///
/// `model` bilinçli olarak serbest metin: uygulama CT110 ile başlıyor ama
/// CT33s Pro / CT50s Pro sonradan eklenebilsin diye modele özel varsayım
/// koda gömülmüyor.
class Aircraft {
  final String id;
  final String serialNo;
  final String model;
  final String? shgmRegistrationNo;

  /// Uygulamaya kaydedilmeden önce yapılmış sorti sayısı.
  /// Kullanılmış bir hava aracı filoya eklendiğinde sayaç sıfırdan başlamasın.
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
        'baseline_sorties': baselineSorties,
        'baseline_flight_minutes': baselineFlightMinutes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Aircraft.fromJson(Map<String, dynamic> json) => Aircraft(
        id: json['id'] as String,
        serialNo: json['serial_no'] as String,
        model: json['model'] as String,
        shgmRegistrationNo: json['shgm_registration_no'] as String?,
        baselineSorties: (json['baseline_sorties'] as num?)?.toInt() ?? 0,
        baselineFlightMinutes:
            (json['baseline_flight_minutes'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
