import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_os/core/providers/locale_provider.dart';
import 'package:life_os/core/providers/theme_provider.dart';
import 'package:life_os/core/services/notification_service.dart';
import 'package:life_os/core/theme/app_theme.dart';
import 'package:life_os/core/widgets/app_shell.dart';
import 'package:life_os/features/alarms/alarm_ringing_page.dart';
import 'package:life_os/features/alarms/providers/alarms_provider.dart';
import 'package:life_os/l10n/generated/app_localizations.dart';

/// Global navigator key so services (notification taps) can push routes
/// without needing a BuildContext of their own.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class LifeOsApp extends ConsumerStatefulWidget {
  const LifeOsApp({super.key});

  @override
  ConsumerState<LifeOsApp> createState() => _LifeOsAppState();
}

class _LifeOsAppState extends ConsumerState<LifeOsApp> {
  @override
  void initState() {
    super.initState();
    NotificationService.lastTap.addListener(_handleNotificationTap);
    // Cheap and idempotent — guarantees every enabled alarm's OS-level
    // schedule matches what's saved in Hive, every time the app starts.
    Future.microtask(() => ref.read(alarmsProvider.notifier).rescheduleAll());
  }

  @override
  void dispose() {
    NotificationService.lastTap.removeListener(_handleNotificationTap);
    super.dispose();
  }

  void _handleNotificationTap() {
    final event = NotificationService.lastTap.value;
    if (event == null) return;
    final payload = event.payload;
    if (payload == null) return;
    final parts = payload.split(':'); // "type:id" e.g. "alarm:<uuid>"
    if (parts.isEmpty) return;

    if (parts[0] == 'alarm' && parts.length > 1) {
      final alarmId = parts[1];
      if (event.actionId == 'snooze') {
        ref.read(alarmsProvider.notifier).snooze(alarmId);
        return;
      }
      if (event.actionId == 'dismiss') {
        return; // notification already auto-cancelled itself
      }
      // Plain tap (or app opened from a full-screen alarm): show the big
      // ringing screen with Stop/Snooze, same as a real alarm clock.
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => AlarmRingingPage(alarmId: alarmId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(themeSettingsProvider);
    final locale = ref.watch(localeProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final useDynamic = settings.useMaterialYou && lightDynamic != null && darkDynamic != null;

        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Life OS',
          theme: AppTheme.light(dynamicScheme: useDynamic ? lightDynamic : null),
          darkTheme: AppTheme.dark(dynamicScheme: useDynamic ? darkDynamic : null),
          themeMode: settings.themeMode,
          locale: locale,
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            // Applies the user's in-app font-scale preference (small/medium/
            // large from Settings). Deliberately *replaces* rather than
            // multiplies with the system accessibility text scale, so the
            // two settings can't compound into runaway text size on top of
            // the app's own fixed-layout screens (calculator, timers).
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(textScaler: TextScaler.linear(settings.fontScale)),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const AppShell(),
        );
      },
    );
  }
}
