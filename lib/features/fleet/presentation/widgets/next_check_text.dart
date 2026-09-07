import 'package:flutter/widgets.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/aircraft_summary.dart';
import '../../domain/maintenance_rule.dart';

/// Yaklaşan kontrol satırının metni; değerlendirilebilir kural yoksa null.
///
/// Kural adı ARB'den değil veriden gelir (aralıklar koda gömülü değil),
/// bu yüzden dil seçimi burada yapılır.
String? nextCheckText(BuildContext context, AircraftSummary summary) {
  final check = summary.nextCheck;
  if (check == null) return null;

  final l10n = AppLocalizations.of(context)!;
  final label = check.rule.label(Localizations.localeOf(context).languageCode);

  return check.rule.intervalType == MaintenanceIntervalType.sortie
      ? l10n.nextCheckSortie(label, check.remaining)
      : l10n.nextCheckHours(label, check.remaining);
}
