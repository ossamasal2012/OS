import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_os/app.dart';
import 'package:life_os/core/services/hive_service.dart';
import 'package:life_os/core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Both must finish before runApp(): every feature's Riverpod Notifier
  // reads its Hive box synchronously inside build(), and the dashboard
  // needs NotificationService ready to display "next alarm" correctly.
  await HiveService.init();
  await NotificationService.init();

  runApp(const ProviderScope(child: LifeOsApp()));
}
