import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/number_input.dart';
import '../../../l10n/app_localizations.dart';
import '../application/fleet_controller.dart';
import '../data/fleet_repository.dart';
import '../domain/aircraft.dart';

/// İHA ekleme / düzenleme formu.
///
/// [aircraft] verilirse düzenleme, verilmezse yeni kayıt modudur.
class AircraftFormScreen extends ConsumerStatefulWidget {
  final Aircraft? aircraft;

  const AircraftFormScreen({super.key, this.aircraft});

  @override
  ConsumerState<AircraftFormScreen> createState() => _AircraftFormScreenState();
}

class _AircraftFormScreenState extends ConsumerState<AircraftFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _serialNo;
  late final TextEditingController _model;
  late final TextEditingController _shgm;
  late final TextEditingController _baselineSorties;
  late final TextEditingController _baselineHours;

  /// Seri numarası çakışması ancak kaydetme anında anlaşılır; doğrulayıcı
  /// bu değeri okuyarak hatayı alanın altında gösterir.
  String? _serialNoError;
  bool _saving = false;

  bool get _isEdit => widget.aircraft != null;

  @override
  void initState() {
    super.initState();
    final a = widget.aircraft;
    _serialNo = TextEditingController(text: a?.serialNo ?? '');
    // Uygulama CT110 ile başlıyor; model yine de düzenlenebilir bırakıldı.
    _model = TextEditingController(text: a?.model ?? 'CT110');
    _shgm = TextEditingController(text: a?.shgmRegistrationNo ?? '');
    _baselineSorties =
        TextEditingController(text: '${a?.baselineSorties ?? 0}');
    _baselineHours = TextEditingController(
      text: a == null
          ? '0'
          : (a.baselineFlightMinutes / 60).toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _serialNo.dispose();
    _model.dispose();
    _shgm.dispose();
    _baselineSorties.dispose();
    _baselineHours.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _serialNoError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final controller = ref.read(fleetControllerProvider.notifier);
    final sorties = parseIntInput(_baselineSorties.text) ?? 0;
    final minutes = ((parseDecimalInput(_baselineHours.text) ?? 0) * 60).round();

    try {
      if (_isEdit) {
        await controller.updateAircraft(
          widget.aircraft!,
          serialNo: _serialNo.text,
          model: _model.text,
          shgmRegistrationNo: _shgm.text,
          baselineSorties: sorties,
          baselineFlightMinutes: minutes,
        );
      } else {
        await controller.addAircraft(
          serialNo: _serialNo.text,
          model: _model.text,
          shgmRegistrationNo: _shgm.text,
          baselineSorties: sorties,
          baselineFlightMinutes: minutes,
        );
      }
    } on DuplicateSerialNoException {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serialNoError = l10n.serialNoExists;
      });
      _formKey.currentState!.validate();
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.aircraftSaved)));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editAircraft : l10n.addAircraft),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              TextFormField(
                controller: _serialNo,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: l10n.serialNoLabel,
                  hintText: l10n.serialNoHint,
                ),
                // Numara değişince çakışma uyarısı kalksın.
                onChanged: (_) {
                  if (_serialNoError != null) {
                    setState(() => _serialNoError = null);
                  }
                },
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) return l10n.fieldRequired;
                  return _serialNoError;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _model,
                decoration: InputDecoration(labelText: l10n.modelLabel),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shgm,
                decoration: InputDecoration(
                  labelText: '${l10n.shgmLabel} (${l10n.optionalSuffix})',
                  helperText: l10n.shgmHelp,
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _baselineSorties,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.baselineSortiesLabel,
                  helperText: l10n.baselineSortiesHelp,
                  helperMaxLines: 2,
                ),
                validator: (v) => parseIntInput(v) == null
                    ? l10n.invalidNumber
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _baselineHours,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${l10n.baselineHoursLabel} (${l10n.hoursUnit})',
                  helperText: l10n.baselineHoursHelp,
                  helperMaxLines: 2,
                ),
                validator: (v) {
                  final value = parseDecimalInput(v);
                  return (value == null || value < 0)
                      ? l10n.invalidNumber
                      : null;
                },
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
