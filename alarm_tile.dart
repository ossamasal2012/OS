import 'package:flutter/material.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/features/alarms/models/alarm.dart';

class AlarmTile extends StatelessWidget {
  const AlarmTile({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onTap,
  });

  final Alarm alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  String _daysLabel(BuildContext context) {
    final l10n = context.l10n;
    if (alarm.daysOfWeek.isEmpty) return l10n.alarmsEveryDay;
    const names = ['', 'alarmsMon', 'alarmsTue', 'alarmsWed', 'alarmsThu', 'alarmsFri', 'alarmsSat', 'alarmsSun'];
    final labels = <String, String>{
      'alarmsMon': l10n.alarmsMon,
      'alarmsTue': l10n.alarmsTue,
      'alarmsWed': l10n.alarmsWed,
      'alarmsThu': l10n.alarmsThu,
      'alarmsFri': l10n.alarmsFri,
      'alarmsSat': l10n.alarmsSat,
      'alarmsSun': l10n.alarmsSun,
    };
    final sorted = [...alarm.daysOfWeek]..sort();
    return sorted.map((d) => labels[names[d]]).join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = Color(alarm.colorValue);
    final disabled = !alarm.isEnabled;
    final h = alarm.hour.toString().padLeft(2, '0');
    final m = alarm.minute.toString().padLeft(2, '0');

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(width: 4, height: 42, color: color.withOpacity(disabled ? 0.3 : 1)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$h:$m',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: disabled ? scheme.onSurface.withOpacity(0.4) : scheme.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alarm.label.isEmpty ? _daysLabel(context) : '${alarm.label} • ${_daysLabel(context)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Switch(value: alarm.isEnabled, onChanged: onToggle),
            ],
          ),
        ),
      ),
    );
  }
}
