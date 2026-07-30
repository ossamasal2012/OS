import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/hive_boxes.dart';
import 'package:life_os/core/services/hive_service.dart';

const List<String> supportedLocaleCodes = ['ar', 'en'];

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final saved = HiveService.settings.get(SettingsKeys.localeCode) as String?;
    if (saved != null && supportedLocaleCodes.contains(saved)) {
      return Locale(saved);
    }
    // Default to the device locale when it's one we support, otherwise
    // fall back to Arabic — this app's primary audience is Arabic-speaking.
    final deviceCode = PlatformDispatcher.instance.locale.languageCode;
    return Locale(supportedLocaleCodes.contains(deviceCode) ? deviceCode : 'ar');
  }

  Future<void> setLocale(String code) async {
    if (!supportedLocaleCodes.contains(code)) return;
    await HiveService.settings.put(SettingsKeys.localeCode, code);
    state = Locale(code);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
