/// Bir uçuş kaydının nereden geldiği.
///
/// Sayaç hesabında kritik: cihazdan gelen kayıtlar cihazın ömür sayacına
/// zaten dahildir, elle girilenler değildir. İkisi ayrılmazsa uçuş saati
/// iki kere sayılır ve bakım görevleri yanlış zamanda tetiklenir.
enum FlightSource {
  /// Kullanıcının kronometreyle ya da elle girdiği uçuş.
  manual,

  /// baibars platformundan gelen, cihazın kendi bildirdiği sorti.
  device,
}

/// Sorti defteri durumu (yol haritası v1.2, §3).
///
/// Telemetri kesilmesi tek başına "indi" demek değildir; kesintili sorti
/// kapanmış sayılmaz, süresi alt sınır olarak kalır.
enum SortieCompleteness {
  /// Açık/devam eden sorti; süre henüz kesinleşmedi.
  provisional,

  /// Temiz kapandı — iniş kanıtı ve kararlı yer örnekleri alındı.
  confirmed,

  /// Bağlantı uçuş bitmeden koptu; kayıtlı süre gerçek süreden az.
  interrupted,

  /// Geçmiş verisiyle sonradan tamamlandı.
  reconciled,
}

/// Tek bir uçuş kaydı (platform şemasında `sorties`).
class Flight {
  final String id;
  final String aircraftId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationMin;

  /// İşlenen alan (dekar). Zorunlu değil — çiftçi her uçuşta girmek zorunda
  /// kalmasın diye boş bırakılabilir. Platformdan gelen değerler dekara
  /// çevrilerek yazılır (kaynak sistem mu kullanıyor).
  final double? areaCoveredDa;

  final FlightSource source;

  /// Sorti defteri durumu. Elle girilen kayıtlarda varsayılan `confirmed`:
  /// kullanıcı süreyi kendisi beyan etmiştir, bekleyen bir belirsizlik yoktur.
  final SortieCompleteness completeness;

  /// Platformdaki `sorties.id`. Eşitlemede aynı sortinin ikinci kez
  /// yazılmasını engeller. Elle girilen uçuşlarda null.
  final String? platformId;

  const Flight({
    required this.id,
    required this.aircraftId,
    required this.startedAt,
    required this.endedAt,
    required this.durationMin,
    this.areaCoveredDa,
    this.source = FlightSource.manual,
    this.completeness = SortieCompleteness.confirmed,
    this.platformId,
  });

  /// Kayıtlı süre gerçek süreden az olabilir mi.
  bool get isDurationLowerBound =>
      completeness == SortieCompleteness.interrupted ||
      completeness == SortieCompleteness.provisional;

  Map<String, dynamic> toJson() => {
        'id': id,
        'aircraft_id': aircraftId,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt.toIso8601String(),
        'duration_min': durationMin,
        'area_covered_da': areaCoveredDa,
        'source': source.name,
        'completeness': completeness.name,
        'platform_id': platformId,
      };

  /// Eski kayıtlarda `source` / `completeness` yoktur; onlar elle girilmiş
  /// ve kapanmış sayılır.
  factory Flight.fromJson(Map<String, dynamic> json) => Flight(
        id: json['id'] as String,
        aircraftId: json['aircraft_id'] as String,
        startedAt: DateTime.parse(json['started_at'] as String),
        endedAt: DateTime.parse(json['ended_at'] as String),
        durationMin: (json['duration_min'] as num).toInt(),
        areaCoveredDa: (json['area_covered_da'] as num?)?.toDouble(),
        source: FlightSource.values.firstWhere(
          (s) => s.name == json['source'],
          orElse: () => FlightSource.manual,
        ),
        completeness: SortieCompleteness.values.firstWhere(
          (c) => c.name == json['completeness'],
          orElse: () => SortieCompleteness.confirmed,
        ),
        platformId: json['platform_id'] as String?,
      );
}

/// Başlatılmış ama henüz bitirilmemiş uçuş.
///
/// Uygulama kapansa bile kaybolmasın diye yerel depoya yazılır —
/// tarlada telefonun kapanması uçuş kaydını yok etmemeli.
class ActiveFlight {
  final String aircraftId;
  final DateTime startedAt;

  const ActiveFlight({required this.aircraftId, required this.startedAt});

  Map<String, dynamic> toJson() => {
        'aircraft_id': aircraftId,
        'started_at': startedAt.toIso8601String(),
      };

  factory ActiveFlight.fromJson(Map<String, dynamic> json) => ActiveFlight(
        aircraftId: json['aircraft_id'] as String,
        startedAt: DateTime.parse(json['started_at'] as String),
      );
}
