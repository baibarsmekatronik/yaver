/// Tek bir uçuş kaydı (bir sorti).
///
/// Her uçuş kaydı sorti sayacını 1 artırır; süre dakika cinsinden tutulur.
class Flight {
  final String id;
  final String aircraftId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationMin;

  /// İşlenen alan (dekar). Zorunlu değil — çiftçi her uçuşta girmek zorunda
  /// kalmasın diye boş bırakılabilir.
  final double? areaCoveredDa;

  const Flight({
    required this.id,
    required this.aircraftId,
    required this.startedAt,
    required this.endedAt,
    required this.durationMin,
    this.areaCoveredDa,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'aircraft_id': aircraftId,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt.toIso8601String(),
        'duration_min': durationMin,
        'area_covered_da': areaCoveredDa,
      };

  factory Flight.fromJson(Map<String, dynamic> json) => Flight(
        id: json['id'] as String,
        aircraftId: json['aircraft_id'] as String,
        startedAt: DateTime.parse(json['started_at'] as String),
        endedAt: DateTime.parse(json['ended_at'] as String),
        durationMin: (json['duration_min'] as num).toInt(),
        areaCoveredDa: (json['area_covered_da'] as num?)?.toDouble(),
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
