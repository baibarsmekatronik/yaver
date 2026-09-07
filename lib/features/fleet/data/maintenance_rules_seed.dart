import '../domain/maintenance_rule.dart';

/// Bakım kurallarının ilk kurulum tohumu.
///
/// Yol haritası v1.2: bu tablo **baibars onaylı varsayılan** olarak
/// işaretlidir — üreticinin talimatı değildir ve koda gömülü sayılmaz.
/// Platform bağlandığında kurallar `maintenance_rules` tablosundan okunacak;
/// burası yalnızca ilk açılışta ve çevrimdışı ilk kurulumda kullanılır.
///
/// `isTbd: true` olanlar baibars mühendislik onayı beklemektedir; onaylanana
/// kadar arayüzde kesin bilgi gibi gösterilmez (bkz. docs/OPEN_QUESTIONS.md).
final List<MaintenanceRule> maintenanceRulesSeed = [
  MaintenanceRule(
    id: 'arm_fold_bolt_torque',
    componentType: 'arm_fold',
    labelTr: 'Kol katlama aparatı vidası tork kontrolü',
    labelEn: 'Arm-fold bracket bolt torque check',
    intervalType: MaintenanceIntervalType.sortie,
    intervalValue: 100,
    warnBefore: 10,
    validResetActions: const {
      MaintenanceResetAction.inspected,
      MaintenanceResetAction.replaced,
    },
    effectiveFrom: DateTime.utc(2026, 1, 1),
  ),
  MaintenanceRule(
    id: 'motor_torque_bolts',
    componentType: 'motor',
    labelTr: 'Motor tork ve montaj cıvatası kontrolü',
    labelEn: 'Motor torque and mounting bolt check',
    intervalType: MaintenanceIntervalType.hours,
    intervalValue: 100,
    warnBefore: 10,
    validResetActions: const {
      MaintenanceResetAction.inspected,
      MaintenanceResetAction.replaced,
    },
    effectiveFrom: DateTime.utc(2026, 1, 1),
  ),
  MaintenanceRule(
    id: 'motor_cant_alignment',
    componentType: 'motor',
    labelTr: 'Motor montaj yönü kontrolü (3° içe eğim)',
    labelEn: 'Motor cant alignment check (3° inward)',
    intervalType: MaintenanceIntervalType.hours,
    intervalValue: 100,
    warnBefore: 10,
    // Motor/mount değişiminde de tetiklenir; olay tabanlı tetikleme Faz 2'de.
    validResetActions: const {
      MaintenanceResetAction.inspected,
      MaintenanceResetAction.replaced,
    },
    effectiveFrom: DateTime.utc(2026, 1, 1),
  ),
  MaintenanceRule(
    id: 'frame_crack_inspection',
    componentType: 'frame',
    labelTr: 'Şasi profil çatlak muayenesi',
    labelEn: 'Frame profile crack inspection',
    intervalType: MaintenanceIntervalType.sortie,
    intervalValue: 50,
    warnBefore: 5,
    isTbd: true,
    validResetActions: const {MaintenanceResetAction.inspected},
    effectiveFrom: DateTime.utc(2026, 1, 1),
  ),
  MaintenanceRule(
    id: 'pump_impeller_wear',
    componentType: 'pump',
    labelTr: 'Pompa çarkı aşınma kontrolü',
    labelEn: 'Pump impeller wear check',
    intervalType: MaintenanceIntervalType.hours,
    intervalValue: 100,
    warnBefore: 10,
    isTbd: true,
    validResetActions: const {
      MaintenanceResetAction.inspected,
      MaintenanceResetAction.replaced,
    },
    effectiveFrom: DateTime.utc(2026, 1, 1),
  ),
  MaintenanceRule(
    id: 'nozzle_disc',
    componentType: 'nozzle',
    labelTr: 'Nozül disk kontrolü / değişimi',
    labelEn: 'Nozzle disc check / replacement',
    intervalType: MaintenanceIntervalType.hours,
    intervalValue: 50,
    warnBefore: 5,
    isTbd: true,
    validResetActions: const {
      MaintenanceResetAction.inspected,
      MaintenanceResetAction.replaced,
    },
    effectiveFrom: DateTime.utc(2026, 1, 1),
  ),
  MaintenanceRule(
    id: 'propeller_damage',
    componentType: 'propeller',
    labelTr: 'Pervane hasar kontrolü',
    labelEn: 'Propeller damage check',
    intervalType: MaintenanceIntervalType.sortie,
    intervalValue: 25,
    warnBefore: 3,
    isTbd: true,
    validResetActions: const {
      MaintenanceResetAction.inspected,
      MaintenanceResetAction.replaced,
    },
    effectiveFrom: DateTime.utc(2026, 1, 1),
  ),
  MaintenanceRule(
    id: 'landing_gear_bolts',
    componentType: 'landing_gear',
    labelTr: 'İniş takımı cıvata kontrolü',
    labelEn: 'Landing gear bolt check',
    intervalType: MaintenanceIntervalType.sortie,
    intervalValue: 100,
    warnBefore: 10,
    isTbd: true,
    validResetActions: const {
      MaintenanceResetAction.inspected,
      MaintenanceResetAction.replaced,
    },
    effectiveFrom: DateTime.utc(2026, 1, 1),
  ),
  MaintenanceRule(
    id: 'flow_meter_calibration',
    componentType: 'flow_meter',
    labelTr: 'Akış metre kalibrasyonu',
    labelEn: 'Flow meter calibration',
    intervalType: MaintenanceIntervalType.calendar,
    intervalValue: 180,
    warnBefore: 14,
    validResetActions: const {MaintenanceResetAction.inspected},
    effectiveFrom: DateTime.utc(2026, 1, 1),
  ),
  MaintenanceRule(
    id: 'battery_health_review',
    componentType: 'battery',
    labelTr: 'Batarya sağlık değerlendirmesi',
    labelEn: 'Battery health assessment',
    intervalType: MaintenanceIntervalType.cycles,
    intervalValue: 50,
    warnBefore: 5,
    validResetActions: const {
      MaintenanceResetAction.inspected,
      MaintenanceResetAction.replaced,
    },
    effectiveFrom: DateTime.utc(2026, 1, 1),
  ),
];
