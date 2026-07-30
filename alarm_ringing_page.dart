import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/builtin_tones.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/core/utils/shared_enums.dart';
import 'package:life_os/features/alarms/models/alarm.dart';
import 'package:life_os/features/alarms/providers/alarms_provider.dart';

/// Shown when the user taps a firing alarm's notification (or opens the app
/// while one is ringing). The scheduled Android notification is the part
/// that reliably wakes the device and plays a sound even if the app isn't
/// open; this screen is the rich "stop the alarm" experience once the user
/// is actually looking at the phone.
class AlarmRingingPage extends ConsumerStatefulWidget {
  const AlarmRingingPage({super.key, required this.alarmId});

  final String alarmId;

  @override
  ConsumerState<AlarmRingingPage> createState() => _AlarmRingingPageState();
}

class _AlarmRingingPageState extends ConsumerState<AlarmRingingPage> {
  final _player = AudioPlayer();
  Timer? _vibrateTimer;
  Timer? _autoDismissTimer;
  int _snoozesUsed = 0;

  Alarm? get _alarm {
    for (final a in ref.read(alarmsProvider)) {
      if (a.id == widget.alarmId) return a;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _startRinging();
  }

  Future<void> _startRinging() async {
    final alarm = _alarm;
    if (alarm == null) return;

    await _player.setReleaseMode(ReleaseMode.loop);
    final assetName = alarm.soundSource == AlarmSoundSource.builtIn
        ? 'sounds/${BuiltInTones.byKey(alarm.soundValue).rawResourceName}.wav'
        : null;
    if (assetName != null) {
      await _player.play(AssetSource(assetName));
    } else {
      // Custom/device file: play directly from its device path.
      await _player.play(DeviceFileSource(alarm.soundValue));
    }

    if (alarm.vibrate) {
      _vibrateTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
        HapticFeedback.heavyImpact();
      });
    }

    if (alarm.autoDismissMinutes > 0) {
      _autoDismissTimer = Timer(Duration(minutes: alarm.autoDismissMinutes), _stopAndClose);
    }
  }

  void _stopAndClose() {
    _player.stop();
    _vibrateTimer?.cancel();
    _autoDismissTimer?.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _snooze() async {
    final alarm = _alarm;
    if (alarm == null) return _stopAndClose();
    if (alarm.snoozeMaxCount != -1 && _snoozesUsed >= alarm.snoozeMaxCount) {
      _stopAndClose();
      return;
    }
    _snoozesUsed++;
    await ref.read(alarmsProvider.notifier).snooze(alarm.id);
    _stopAndClose();
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    _vibrateTimer?.cancel();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final alarm = _alarm;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.colorScheme.primary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.alarm_rounded, size: 72, color: theme.colorScheme.onPrimary),
                const SizedBox(height: 24),
                Text(
                  alarm == null || alarm.label.isEmpty ? l10n.alarmsRingingTitle : alarm.label,
                  style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.onPrimary),
                  textAlign: TextAlign.center,
                ),
                if (alarm != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.displayLarge?.copyWith(color: theme.colorScheme.onPrimary),
                  ),
                ],
                const Spacer(),
                if (alarm == null || alarm.snoozeMaxCount == -1 || _snoozesUsed < alarm.snoozeMaxCount)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: _snooze,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                      child: Text(l10n.alarmsSnoozeAction),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _stopAndClose,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.onPrimary,
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Text(l10n.alarmsStopAction),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
