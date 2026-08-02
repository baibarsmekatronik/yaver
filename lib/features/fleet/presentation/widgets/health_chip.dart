import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/aircraft_summary.dart';

/// Sağlık durumu rozeti — renk + metin birlikte.
///
/// Renk tek başına anlam taşımıyor; güneş altında ve renk körlüğünde de
/// okunabilsin diye yanında her zaman yazı var.
class HealthChip extends StatelessWidget {
  final FleetHealth health;

  const HealthChip({super.key, required this.health});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (color, label) = switch (health) {
      FleetHealth.tracking => (BaibarsColors.statusReady, l10n.statusTracking),
      FleetHealth.dueSoon => (BaibarsColors.statusDue, l10n.statusDueSoon),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
