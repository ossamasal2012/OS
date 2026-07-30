import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:life_os/core/providers/locale_provider.dart';
import 'package:life_os/core/providers/theme_provider.dart';
import 'package:life_os/core/services/backup_service.dart';
import 'package:life_os/core/services/notification_service.dart';
import 'package:life_os/core/theme/app_colors.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(themeSettingsProvider);
    final themeNotifier = ref.read(themeSettingsProvider.notifier);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _SectionTitle(l10n.settingsAppearance),
          ListTile(
            title: Text(l10n.settingsTheme),
            trailing: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.system, label: Text(l10n.settingsThemeSystem)),
                ButtonSegment(value: ThemeMode.light, label: Text(l10n.settingsThemeLight)),
                ButtonSegment(value: ThemeMode.dark, label: Text(l10n.settingsThemeDark)),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => themeNotifier.setThemeMode(s.first),
            ),
          ),
          SwitchListTile(
            title: Text(l10n.settingsMaterialYou),
            subtitle: Text(l10n.settingsMaterialYouDesc),
            value: settings.useMaterialYou,
            onChanged: themeNotifier.setUseMaterialYou,
          ),
          if (!settings.useMaterialYou)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.settingsAccentColor, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: AppColors.tagPalette.map((c) {
                      final selected = c == settings.seedColor;
                      return GestureDetector(
                        onTap: () => themeNotifier.setSeedColor(c),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: selected ? Border.all(color: theme.colorScheme.onSurface, width: 2) : null,
                          ),
                          child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.settingsFontSize, style: theme.textTheme.titleSmall),
                Slider(
                  value: settings.fontScale,
                  min: 0.85,
                  max: 1.3,
                  divisions: 3,
                  label: settings.fontScale <= 0.9
                      ? l10n.settingsFontSizeSmall
                      : settings.fontScale >= 1.15
                          ? l10n.settingsFontSizeLarge
                          : l10n.settingsFontSizeMedium,
                  onChanged: themeNotifier.setFontScale,
                ),
              ],
            ),
          ),
          const Divider(height: 32),

          _SectionTitle(l10n.settingsLanguage),
          RadioListTile<String>(
            title: Text(l10n.settingsLanguageArabic),
            value: 'ar',
            groupValue: locale.languageCode,
            onChanged: (v) => ref.read(localeProvider.notifier).setLocale(v!),
          ),
          RadioListTile<String>(
            title: Text(l10n.settingsLanguageEnglish),
            value: 'en',
            groupValue: locale.languageCode,
            onChanged: (v) => ref.read(localeProvider.notifier).setLocale(v!),
          ),
          const Divider(height: 32),

          _SectionTitle(l10n.settingsReliability),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(l10n.settingsEnableNotifications),
            subtitle: Text(l10n.settingsEnableNotificationsDesc),
            onTap: () => NotificationService.requestNotificationPermission(),
          ),
          ListTile(
            leading: const Icon(Icons.alarm_on_outlined),
            title: Text(l10n.settingsExactAlarms),
            subtitle: Text(l10n.settingsExactAlarmsDesc),
            onTap: () => NotificationService.requestExactAlarmPermission(),
          ),
          ListTile(
            leading: const Icon(Icons.battery_charging_full_outlined),
            title: Text(l10n.settingsBatteryOptimization),
            subtitle: Text(l10n.settingsBatteryOptimizationDesc),
            onTap: () => openAppSettings(),
          ),
          const Divider(height: 32),

          _SectionTitle(l10n.settingsBackup),
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: Text(l10n.settingsBackupExport),
            subtitle: Text(l10n.settingsBackupExportDesc),
            onTap: () => BackupService.exportAndShare(),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l10n.settingsBackupImport),
            subtitle: Text(l10n.settingsBackupImportDesc),
            onTap: () => _importFlow(context, ref),
          ),
          const Divider(height: 32),

          _SectionTitle(l10n.settingsAbout),
          const _AboutTile(),
        ],
      ),
    );
  }

  Future<void> _importFlow(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final merge = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsBackupImport),
        content: Text(l10n.settingsImportMergeQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.settingsImportReplace),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.settingsImportMerge),
          ),
        ],
      ),
    );
    if (merge == null || !context.mounted) return;
    final counts = await BackupService.pickFileAndImport(merge: merge);
    if (counts == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsImportDone)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '1.0.0';
        return ListTile(
          leading: const Icon(Icons.info_outline_rounded),
          title: const Text('Life OS'),
          subtitle: Text('${l10n.settingsVersion} $version • 100% Offline • No AI'),
        );
      },
    );
  }
}
