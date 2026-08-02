import '../domain/aircraft.dart';
import '../domain/flight.dart';

/// Filo verisinin kaynağı.
///
/// Ekranlar yalnızca bu arayüzü tanır. Faz 1'de yerel depo, ileride
/// Supabase senkronu bu arayüzün arkasına takılacak — ekran kodu değişmeyecek.
abstract interface class FleetRepository {
  List<Aircraft> listAircraft();

  List<Flight> listFlights({String? aircraftId});

  ActiveFlight? activeFlight();

  Future<void> saveAircraft(Aircraft aircraft);

  /// Hava aracını ve ona bağlı tüm uçuş kayıtlarını siler.
  Future<void> deleteAircraft(String aircraftId);

  Future<void> addFlight(Flight flight);

  Future<void> deleteFlight(String flightId);

  Future<void> startFlight(ActiveFlight active);

  /// Süren uçuşu iptal eder (kayıt oluşturmadan).
  Future<void> clearActiveFlight();
}

/// Aynı seri numarası filoda ikinci kez kaydedilmeye çalışıldığında atılır.
class DuplicateSerialNoException implements Exception {
  final String serialNo;
  const DuplicateSerialNoException(this.serialNo);

  @override
  String toString() => 'DuplicateSerialNoException($serialNo)';
}
