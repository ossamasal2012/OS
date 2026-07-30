import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:life_os/core/constants/builtin_tones.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/core/utils/shared_enums.dart';

class AlarmSoundPicker extends StatefulWidget {
  const AlarmSoundPicker({
    super.key,
    required this.source,
    required this.value,
    required this.onChanged,
  });

  final AlarmSoundSource source;
  final String value;
  final void Function(AlarmSoundSource source, String value) onChanged;

  @override
  State<AlarmSoundPicker> createState() => _AlarmSoundPickerState();
}

class _AlarmSoundPickerState extends State<AlarmSoundPicker> {
  final _player = AudioPlayer();
  String? _previewingKey;

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _preview(String assetKey, String rawResourceName) async {
    if (_previewingKey == assetKey) {
      await _player.stop();
      setState(() => _previewingKey = null);
      return;
    }
    setState(() => _previewingKey = assetKey);
    // The bundled tones also exist as Flutter assets under assets/sounds/
    // purely so this in-app preview can play them without touching Android
    // resources — the *actual* alarm sound at ring-time uses the Android
    // raw resource (android/app/src/main/res/raw/), which is required for
    // a NotificationChannel's sound. See ANDROID_SETUP.md.
    await _player.play(AssetSource('sounds/$rawResourceName.wav'));
  }

  Future<void> _pickCustomFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    final path = result?.files.single.path;
    if (path == null) return;
    widget.onChanged(AlarmSoundSource.customFile, path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.alarmsBuiltInTones, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ...BuiltInTones.all.map((tone) {
          final selected = widget.source == AlarmSoundSource.builtIn && widget.value == tone.key;
          return Card(
            color: selected ? theme.colorScheme.primary.withOpacity(0.12) : null,
            child: ListTile(
              title: Text(tone.labelAr),
              leading: Radio<String>(
                value: tone.key,
                groupValue: widget.source == AlarmSoundSource.builtIn ? widget.value : null,
                onChanged: (_) => widget.onChanged(AlarmSoundSource.builtIn, tone.key),
              ),
              trailing: IconButton(
                icon: Icon(_previewingKey == tone.key ? Icons.stop_circle_rounded : Icons.play_circle_outline_rounded),
                onPressed: () => _preview(tone.key, tone.rawResourceName),
              ),
              onTap: () => widget.onChanged(AlarmSoundSource.builtIn, tone.key),
            ),
          );
        }),
        const SizedBox(height: 16),
        Text(l10n.alarmsOtherSounds, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.folder_open_rounded),
            title: Text(l10n.alarmsChooseFile),
            subtitle: widget.source == AlarmSoundSource.customFile
                ? Text(widget.value, maxLines: 1, overflow: TextOverflow.ellipsis)
                : null,
            onTap: _pickCustomFile,
          ),
        ),
      ],
    );
  }
}
