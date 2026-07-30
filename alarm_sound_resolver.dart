import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:life_os/core/constants/builtin_tones.dart';
import 'package:life_os/core/services/notification_service.dart';
import 'package:life_os/core/utils/shared_enums.dart';
import 'package:life_os/features/alarms/models/alarm.dart';

class ResolvedAlarmSound {
  const ResolvedAlarmSound({required this.channelId, required this.sound});
  final String channelId;
  final AndroidNotificationSound sound;
}

class AlarmSoundResolver {
  AlarmSoundResolver._();

  static ResolvedAlarmSound resolve(Alarm alarm) {
    switch (alarm.soundSource) {
      case AlarmSoundSource.builtIn:
        final tone = BuiltInTones.byKey(alarm.soundValue);
        return ResolvedAlarmSound(
          channelId: NotificationService.channelIdForBuiltInTone(tone.key),
          sound: RawResourceAndroidNotificationSound(tone.rawResourceName),
        );
      case AlarmSoundSource.deviceRingtone:
      case AlarmSoundSource.customFile:
        return ResolvedAlarmSound(
          channelId: NotificationService.channelIdForCustomSound(alarm.soundValue),
          sound: UriAndroidNotificationSound(alarm.soundValue),
        );
    }
  }
}
