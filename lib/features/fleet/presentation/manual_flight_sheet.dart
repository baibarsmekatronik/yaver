import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/number_input.dart';
import '../../../l10n/app_localizations.dart';
import '../application/fleet_controller.dart';

/// Kronometre kullanılmadan yapılmış bir uçuşu elle eklemek için form.
///
/// Tarlada telefon cepteyken uçuş yapılmış olabilir; sayaç eksik kalmasın.
class ManualFlightSheet extends ConsumerStatefulWidget {
  final String aircraftId;

  const ManualFlightSheet({super.key, required this.aircraftId});

  @override
  ConsumerState<ManualFlightSheet> createState() => _ManualFlightSheetState();
}

class _ManualFlightSheetState extends ConsumerState<ManualFlightSheet> {
  final _formKey = GlobalKey<FormState>();
  final _duration = TextEditingController();
  final _area = TextEditingController();

  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = ref.read(nowProvider)();
  }

  @override
  void dispose() {
    _duration.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = ref.read(nowProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      // Geçmişe dönük kayıt serbest, geleceğe uçuş girilemez.
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    // Sayfa kapandıktan sonra bu context geçersiz olacağı için
    // bildirim kanalı önceden alınıyor.
    final messenger = ScaffoldMessenger.of(context);

    await ref.read(fleetControllerProvider.notifier).addManualFlight(
          aircraftId: widget.aircraftId,
          startedAt: _date,
          durationMin: parseIntInput(_duration.text)!,
          areaCoveredDa: parseDecimalInput(_area.text),
        );

    if (!mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.flightSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.manualFlightTitle, style: textTheme.titleLarge),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                '${l10n.dateLabel}: ${DateFormat('dd.MM.yyyy').format(_date)}',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _duration,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: l10n.durationLabel),
              validator: (v) {
                final minutes = parseIntInput(v);
                return (minutes == null || minutes < 1)
                    ? l10n.invalidNumber
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _area,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '${l10n.areaLabel} (${l10n.optionalSuffix})',
              ),
              validator: (v) {
                if ((v?.trim() ?? '').isEmpty) return null;
                final area = parseDecimalInput(v);
                return (area == null || area < 0) ? l10n.invalidNumber : null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}
