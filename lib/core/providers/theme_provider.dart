import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/hive_boxes.dart';
import 'package:life_os/core/services/hive_service.dart';
import 'package:life_os/core/theme/app_colors.dart';

class AppThemeSettings {
  const AppThemeSettings({
    required this.themeMode,
    required this.useMaterialYou,
    required this.seedColor,
    required this.fontScale,
  });

  final ThemeMode themeMode;
  final bool useMaterialYou;
  final Color seedColor;
  final double fontScale; // 0.9 / 1.0 / 1.15 (small/medium/large)

  AppThemeSettings copyWith({
    ThemeMode? themeMode,
    bool? useMaterialYou,
    Color? seedColor,
    double? fontScale,
  }) {
    return AppThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      useMaterialYou: useMaterialYou ?? this.useMaterialYou,
      seedColor: seedColor ?? this.seedColor,
      fontScale: fontScale ?? this.fontScale,
    );
  }
}

class ThemeSettingsNotifier extends Notifier<AppThemeSettings> {
  @override
  AppThemeSettings build() {
    final box = HiveService.settings;
    final modeStr = box.get(SettingsKeys.themeMode, defaultValue: 'system') as String;
    final useMaterialYou = box.get(SettingsKeys.useMaterialYou, defaultValue: false) as bool;
    final seedValue = box.get(SettingsKeys.seedColorValue) as int?;
    final fontScale = box.get(SettingsKeys.fontScale, defaultValue: 1.0) as double;

    return AppThemeSettings(
      themeMode: _modeFromString(modeStr),
      useMaterialYou: useMaterialYou,
      seedColor: seedValue != null ? Color(seedValue) : AppColors.brass,
      fontScale: fontScale,
    );
  }

  static ThemeMode _modeFromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _modeToString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await HiveService.settings.put(SettingsKeys.themeMode, _modeToString(mode));
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setUseMaterialYou(bool value) async {
    await HiveService.settings.put(SettingsKeys.useMaterialYou, value);
    state = state.copyWith(useMaterialYou: value);
  }

  Future<void> setSeedColor(Color color) async {
    await HiveService.settings.put(SettingsKeys.seedColorValue, color.value);
    state = state.copyWith(seedColor: color);
  }

  Future<void> setFontScale(double scale) async {
    await HiveService.settings.put(SettingsKeys.fontScale, scale);
    state = state.copyWith(fontScale: scale);
  }
}

final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, AppThemeSettings>(ThemeSettingsNotifier.new);
