import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/core/widgets/color_tag_picker.dart';
import 'package:life_os/features/alarms/models/alarm.dart';
import 'package:life_os/features/alarms/providers/alarms_provider.dart';
import 'package:life_os/features/alarms/widgets/alarm_sound_picker.dart';

class AlarmEditorPage extends ConsumerStatefulWidget {
  const AlarmEditorPage({super.key, this.alarmId});

  final String? alarmId;

  @override
  ConsumerState<AlarmEditorPage> createState() => _AlarmEditorPageState();
}

class _AlarmEditorPageState extends ConsumerState<AlarmEditorPage> {
  late Alarm _alarm;
  late final TextEditingController _labelController;
  bool get _isNew => widget.alarmId == null;

  @override
  void initState() {
    super.initState();
    final existing = widget.alarmId == null ? null : _find(widget.alarmId!);
    final now = TimeOfDay.now();
    _alarm = existing ?? Alarm(hour: now.hour, minute: now.minute);
    _labelController = TextEditingController(text: _alarm.label);
  }

  Alarm? _find(String id) {
    for (final a in ref.read(alarmsProvider)) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _alarm.hour, minute: _alarm.minute),
    );
    if (picked == null) return;
    setState(() => _alarm = _alarm.copyWith(hour: picked.hour, minute: picked.minute));
  }

  void _toggleDay(int weekday) {
    setState(() {
      final days = [..._alarm.daysOfWeek];
      if (days.contains(weekday)) {
        days.remove(weekday);
      } else {
        days.add(weekday);
      }
      _alarm = _alarm.copyWith(daysOfWeek: days);
    });
  }

  void _save() {
    _alarm = _alarm.copyWith(label: _labelController.text.trim());
    if (_isNew) {
      ref.read(alarmsProvider.notifier).add(_alarm);
    } else {
      ref.read(alarmsProvider.notifier).update(_alarm);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dayLabels = [
      l10n.alarmsMon,
      l10n.alarmsTue,
      l10n.alarmsWed,
      l10n.alarmsThu,
      l10n.alarmsFri,
      l10n.alarmsSat,
      l10n.alarmsSun,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.alarmsNewAlarm : l10n.alarmsEditAlarm),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () {
                ref.read(alarmsProvider.notifier).delete(_alarm.id);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Center(
            child: TextButton(
              onPressed: _pickTime,
              child: Text(
                '${_alarm.hour.toString().padLeft(2, '0')}:${_alarm.minute.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(l10n.alarmsRepeat, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: List.generate(7, (i) {
              final weekday = i + 1; // 1..7 Mon..Sun
              final selected = _alarm.daysOfWeek.contains(weekday);
              return ChoiceChip(
                label: Text(dayLabels[i]),
                selected: selected,
                onSelected: (_) => _toggleDay(weekday),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.alarmsNoDaysMeansDaily,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _labelController,
            decoration: InputDecoration(
              hintText: l10n.alarmsLabelHint,
              prefixIcon: const Icon(Icons.label_outline_rounded),
            ),
          ),
          const SizedBox(height: 20),

          Text(l10n.alarmsColor, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          ColorTagPicker(
            selected: Color(_alarm.colorValue),
            onChanged: (c) => setState(() => _alarm = _alarm.copyWith(colorValue: c.value)),
          ),
          const SizedBox(height: 20),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.alarmsVibrate),
            value: _alarm.vibrate,
            onChanged: (v) => setState(() => _alarm = _alarm.copyWith(vibrate: v)),
          ),
          const SizedBox(height: 8),

          Text(l10n.alarmsSnooze, style: Theme.of(context).textTheme.titleSmall),
          _StepperRow(
            label: l10n.alarmsSnoozeDuration,
            value: _alarm.snoozeMinutes,
            suffix: l10n.commonMinutesShort,
            min: 1,
            max: 30,
            onChanged: (v) => setState(() => _alarm = _alarm.copyWith(snoozeMinutes: v)),
          ),
          _StepperRow(
            label: l10n.alarmsSnoozeMaxCount,
            value: _alarm.snoozeMaxCount,
            min: 1,
            max: 10,
            onChanged: (v) => setState(() => _alarm = _alarm.copyWith(snoozeMaxCount: v)),
          ),
          _StepperRow(
            label: l10n.alarmsAutoDismiss,
            value: _alarm.autoDismissMinutes,
            suffix: l10n.commonMinutesShort,
            min: 0,
            max: 60,
            onChanged: (v) => setState(() => _alarm = _alarm.copyWith(autoDismissMinutes: v)),
          ),
          const SizedBox(height: 20),

          AlarmSoundPicker(
            source: _alarm.soundSource,
            value: _alarm.soundValue,
            onChanged: (source, value) => setState(
              () => _alarm = _alarm.copyWith(soundSource: source, soundValue: value),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(onPressed: _save, child: Text(l10n.commonSave)),
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final String? suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 48,
            child: Text(
              suffix == null ? '$value' : '$value $suffix',
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
