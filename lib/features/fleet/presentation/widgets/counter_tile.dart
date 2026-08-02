import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

/// Sayaç gösterimi — etiket üstte küçük, değer altta büyük ve tabular.
///
/// Rakamlar tabular çünkü sayaç değiştikçe basamaklar yerinden oynamamalı.
class CounterTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const CounterTile({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: BaibarsColors.deepGreen,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                unit,
                style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
