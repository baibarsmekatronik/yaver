import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../application/fleet_controller.dart';
import '../domain/aircraft_summary.dart';
import 'aircraft_detail_screen.dart';
import 'aircraft_form_screen.dart';
import 'widgets/counter_tile.dart';
import 'widgets/health_chip.dart';

/// Ana ekran — filodaki tüm İHA'lar, sayaçları ve yaklaşan kontrolleri.
class FleetScreen extends ConsumerWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final fleet = ref.watch(fleetControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.fleetTitle)),
      body: fleet.isEmpty
          ? const _EmptyFleet()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: fleet.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _AircraftCard(summary: fleet[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AircraftFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: Text(l10n.addAircraft),
      ),
    );
  }
}

class _EmptyFleet extends StatelessWidget {
  const _EmptyFleet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.flight_takeoff,
              size: 64,
              color: BaibarsColors.lime,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.fleetEmptyTitle,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge
                  ?.copyWith(color: BaibarsColors.deepGreen),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.fleetEmptyBody,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _AircraftCard extends StatelessWidget {
  final AircraftSummary summary;

  const _AircraftCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final aircraft = summary.aircraft;
    final check = summary.nextCheck;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E6EA)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AircraftDetailScreen(aircraftId: aircraft.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aircraft.model,
                          style: textTheme.titleLarge
                              ?.copyWith(color: BaibarsColors.blue),
                        ),
                        Text(
                          aircraft.serialNo,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
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
              Row(
                children: [
                  const Icon(Icons.build_outlined,
                      size: 16, color: Colors.black45),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      switch (check.basis) {
                        UpcomingCheckBasis.sortie =>
                          l10n.nextCheckSortie(check.remaining),
                        UpcomingCheckBasis.hours =>
                          l10n.nextCheckHours(check.remaining),
                      },
                      style: textTheme.bodySmall
                          ?.copyWith(color: Colors.black54),
                    ),
                  ),
                ],
              ),
              if (summary.hasActiveFlight) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.radio_button_checked,
                        size: 16, color: BaibarsColors.statusDue),
                    const SizedBox(width: 6),
                    Text(
                      l10n.flightInProgress,
                      style: textTheme.labelLarge?.copyWith(
                        color: BaibarsColors.statusDue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
