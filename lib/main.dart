import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  // ProviderScope: Riverpod durum yönetiminin kökü.
  // Faz 1'den itibaren auth, hava aracı ve sayaç durumları buradan akacak.
  runApp(const ProviderScope(child: FleetCareApp()));
}
