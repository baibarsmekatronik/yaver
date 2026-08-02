import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';

/// Demo dashboard — hava aracı kartları ve sayaçlar.
///
/// Faz 1'de burada Supabase'den gerçek hava aracı listesi gelecek.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('baibars FleetCare'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              'Hava Araçlarınız',
              style: textTheme.headlineMedium
                  ?.copyWith(color: BaibarsColors.deepGreen),
            ),
            const SizedBox(height: 16),

            // Demo hava aracı kartı
            _AircraftCard(
              model: 'CT110',
              serialNumber: 'BAI-2024-001',
              sorties: 45,
              flightHours: 7.5,
              status: 'Uçuşa hazır',
              statusColor: BaibarsColors.statusReady,
            ),
            const SizedBox(height: 12),
            _AircraftCard(
              model: 'CT110',
              serialNumber: 'BAI-2024-002',
              sorties: 92,
              flightHours: 15.3,
              status: 'Kontrol yaklaşıyor',
              statusColor: BaibarsColors.statusDue,
            ),
            const SizedBox(height: 12),
            _AircraftCard(
              model: 'CT110',
              serialNumber: 'BAI-2024-003',
              sorties: 156,
              flightHours: 26.2,
              status: 'Uçma — önce kontrol',
              statusColor: BaibarsColors.statusGrounded,
            ),
          ],
        ),
      ),
    );
  }
}

/// Hava aracı kartı — model, seri no, sayaçlar ve sağlık durumu.
class _AircraftCard extends StatelessWidget {
  final String model;
  final String serialNumber;
  final int sorties;
  final double flightHours;
  final String status;
  final Color statusColor;

  const _AircraftCard({
    required this.model,
    required this.serialNumber,
    required this.sorties,
    required this.flightHours,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık: model + seri no
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  model,
                  style: textTheme.titleLarge
                      ?.copyWith(color: BaibarsColors.blue),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              serialNumber,
              style: textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // Sayaçlar: sorties ve flight hours
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sorti',
                      style: textTheme.labelSmall,
                    ),
                    Text(
                      sorties.toString(),
                      style: textTheme.headlineSmall
                          ?.copyWith(fontFeatures: [
                        FontFeature.tabularFigures(),
                      ]),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uçuş saati',
                      style: textTheme.labelSmall,
                    ),
                    Text(
                      '${flightHours.toStringAsFixed(1)} sa',
                      style: textTheme.headlineSmall
                          ?.copyWith(fontFeatures: [
                        FontFeature.tabularFigures(),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Durum
            Text(
              status,
              style: textTheme.bodyMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
