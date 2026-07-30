/// One entry per built-in alarm tone. `rawResourceName` must match the
/// filename (without extension) placed under
/// `android/app/src/main/res/raw/` — see android_setup/ANDROID_SETUP.md.
///
/// To add a new built-in tone: drop a new .wav/.mp3 into
/// `android/app/src/main/res/raw/` (lowercase, `[a-z0-9_]` only, no
/// extension when referenced) and add one line below. That's the entire
/// process — nothing else in the app needs to change.
class BuiltInTone {
  const BuiltInTone(this.key, this.labelAr, this.rawResourceName);

  /// Stable internal key, stored on the Alarm model — never rename this
  /// once alarms using it exist on a real device, or their saved sound
  /// choice will fail to resolve.
  final String key;
  final String labelAr;
  final String rawResourceName;
}

class BuiltInTones {
  BuiltInTones._();

  static const List<BuiltInTone> all = [
    BuiltInTone('classic_beep', 'نغمة كلاسيكية', 'tone_classic_beep'),
    BuiltInTone('gentle_chime', 'جرس هادئ', 'tone_gentle_chime'),
    BuiltInTone('digital_alarm', 'منبه رقمي', 'tone_digital_alarm'),
    BuiltInTone('soft_bell', 'جرس ناعم', 'tone_soft_bell'),
  ];

  static BuiltInTone byKey(String key) {
    return all.firstWhere((t) => t.key == key, orElse: () => all.first);
  }

  static const String defaultKey = 'gentle_chime';
}
