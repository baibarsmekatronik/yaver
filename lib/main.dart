import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/storage/prefs_local_store.dart';
import 'features/fleet/application/fleet_controller.dart';
import 'features/fleet/data/local_fleet_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Yerel veri açılıştan önce okunur; böylece uygulama ilk karede
  // filoyu gösterir — tarlada bekleme ekranı görünmez.
  final store = await PrefsLocalStore.open();
  final repository = LocalFleetRepository.open(store);

  runApp(
    ProviderScope(
      overrides: [fleetRepositoryProvider.overrideWithValue(repository)],
      child: const FleetCareApp(),
    ),
  );
}
