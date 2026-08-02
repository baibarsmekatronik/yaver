import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../application/fleet_controller.dart';
import '../domain/aircraft_summary.dart';
import '../domain/flight.dart';
import 'aircraft_form_screen.dart';
import 'manual_flight_sheet.dart';
import 'widgets/counter_tile.dart';
import 'widgets/health_chip.dart';

/// Tek bir İHA'nın detayı: sayaçlar, uçuş kronometresi ve uçuş kayıtları.
class AircraftDetailScreen extends ConsumerStatefulWidget {
  final String aircraftId;

  const AircraftDetailScreen({super.key, required this.aircraftId});

  @override
  ConsumerState<AircraftDetailScreen> createState() =>
      _AircraftDetailScreenState();
}

class _AircraftDetailScreenState extends ConsumerState<AircraftDetailScreen> {
  /// Kronometre yalnızca uçuş sürerken çalışır — boşuna pil harcamasın.
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker({required bool running}) {
    if (running && _ticker == null) {
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    } else if (!running) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  Future<void> _startFlight() async {
    await ref
        .read(fleetControllerProvider.notifier)
        .startFlight(widget.aircraftId);
  }

  Future<void> _finishFlight() async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(fleetControllerProvider.notifier).finishActiveFlight();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.flightSaved)));
  }

  Future<void> _cancelFlight() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirm(
      title: l10n.cancelFlightTitle,
      body: l10n.cancelFlightBody,
      confirmLabel: l10n.cancelFlight,
    );
    if (!confirmed) return;
    await ref.read(fleetControllerProvider.notifier).cancelActiveFlight();
  }

  Future<void> _deleteAircraft(String serialNo) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirm(
      title: l10n.deleteAircraftTitle,
      body: l10n.deleteAircraftBody(serialNo),
      confirmLabel: l10n.deleteAction,
      destructive: true,
    );
    if (!confirmed) return;

    await ref
        .read(fleetControllerProvider.notifier)
        .deleteAircraft(widget.aircraftId);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.aircraftDeleted)));
  }

  Future<void> _deleteFlight(String flightId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirm(
      title: l10n.deleteFlightTitle,
      body: l10n.deleteFlightBody,
      confirmLabel: l10n.deleteAction,
      destructive: true,
    );
    if (!confirmed) return;

    await ref.read(fleetControllerProvider.notifier).deleteFlight(flightId);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.flightDeleted)));
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: BaibarsColors.statusGrounded)
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fleet = ref.watch(fleetControllerProvider);
    final summary = fleet
        .where((s) => s.aircraft.id == widget.aircraftId)
        .firstOrNull;

    // Hava aracı silindiyse (ör. başka ekrandan) boş bir iskelet göster.
    if (summary == null) {
      _syncTicker(running: false);
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }

    _syncTicker(running: summary.hasActiveFlight);

    final controller = ref.read(fleetControllerProvider.notifier);
    final flights = controller.flightsFor(widget.aircraftId);
    final active = controller.activeFlight;

    return Scaffold(
      appBar: AppBar(
        title: Text(summary.aircraft.serialNo),
        actions: [
          IconButton(
            tooltip: l10n.editAircraft,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    AircraftFormScreen(aircraft: summary.aircraft),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.deleteAction,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteAircraft(summary.aircraft.serialNo),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _CountersCard(summary: summary),
          const SizedBox(height: 16),
          _FlightControlCard(
            active: active,
            onStart: _startFlight,
            onFinish: _finishFlight,
            onCancel: _cancelFlight,
            onManualAdd: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ManualFlightSheet(aircraftId: widget.aircraftId),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.flightLogTitle,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: BaibarsColors.deepGreen),
          ),
          const SizedBox(height: 8),
          if (flights.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l10n.noFlightsYet,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.black54),
              ),
            )
          else
            ...flights.map(
              (f) => _FlightRow(
                flight: f,
                onDelete: () => _deleteFlight(f.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _CountersCard extends StatelessWidget {
  final AircraftSummary summary;

  const _CountersCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final check = summary.nextCheck;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E6EA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.countersTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                HealthChip(health: summary.health),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CounterTile(
                    label: l10n.sortiesLabel,
                    value: '${summary.totalSorties}',
                  ),
                ),
                Expanded(
                  child: CounterTile(
                    label: l10n.flightHoursLabel,
                    value: summary.totalFlightHours.toStringAsFixed(1),
                    unit: l10n.hoursUnit,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              switch (check.basis) {
                UpcomingCheckBasis.sortie =>
                  l10n.nextCheckSortie(check.remaining),
                UpcomingCheckBasis.hours => l10n.nextCheckHours(check.remaining),
              },
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlightControlCard extends ConsumerWidget {
  final ActiveFlight? active;
  final VoidCallback onStart;
  final VoidCallback onFinish;
  final VoidCallback onCancel;
  final VoidCallback onManualAdd;

  const _FlightControlCard({
    required this.active,
    required this.onStart,
    required this.onFinish,
    required this.onCancel,
    required this.onManualAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final running = active != null;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: running
          ? BaibarsColors.statusDue.withValues(alpha: 0.08)
          : BaibarsColors.lime.withValues(alpha: 0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (running) ...[
              Text(
                l10n.flightInProgress,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: BaibarsColors.statusDue,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatElapsed(
                  ref.read(nowProvider)().difference(active!.startedAt),
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: BaibarsColors.deepGreen,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onFinish,
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(l10n.finishFlight),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: onCancel, child: Text(l10n.cancelFlight)),
            ] else ...[
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_circle_outline),
                label: Text(l10n.startFlight),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onManualAdd,
                icon: const Icon(Icons.edit_calendar_outlined),
                label: Text(l10n.addManualFlight),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Süreyi sa:dk:sn olarak yazar; bir saatin altında dk:sn gösterir.
  static String _formatElapsed(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = two(d.inMinutes.remainder(60));
    final seconds = two(d.inSeconds.remainder(60));
    return d.inHours > 0
        ? '${d.inHours}:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}

class _FlightRow extends StatelessWidget {
  final Flight flight;
  final VoidCallback onDelete;

  const _FlightRow({required this.flight, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final area = flight.areaCoveredDa;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.flight_takeoff, color: BaibarsColors.blue),
      title: Text(
        DateFormat('dd.MM.yyyy').format(flight.startedAt),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      subtitle: Text(
        [
          l10n.flightRowSummary(flight.durationMin),
          if (area != null) l10n.flightRowArea(area.toStringAsFixed(1)),
        ].join(' · '),
      ),
      trailing: IconButton(
        tooltip: l10n.deleteAction,
        icon: const Icon(Icons.close, color: Colors.black38),
        onPressed: onDelete,
      ),
    );
  }
}
