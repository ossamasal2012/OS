import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:life_os/core/services/export_service.dart';
import 'package:life_os/core/utils/date_time_utils.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/core/widgets/color_tag_picker.dart';
import 'package:life_os/features/notes/models/note.dart';
import 'package:life_os/features/notes/providers/notes_provider.dart';

/// Opens either a brand-new note (when [noteId] is null) or an existing one.
/// Every field autosaves ~500ms after the user stops typing — there is
/// deliberately no Save button anywhere in this screen.
class NoteEditorPage extends ConsumerStatefulWidget {
  const NoteEditorPage({super.key, this.noteId});

  final String? noteId;

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  late Note _note;
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _categoryController;
  Timer? _debounce;
  bool _dirtySinceCreate = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.noteId == null ? null : _findNote(widget.noteId!);
    _note = existing ?? Note(title: '', body: '');
    _titleController = TextEditingController(text: _note.title);
    _bodyController = TextEditingController(text: _note.body);
    _categoryController = TextEditingController(text: _note.category ?? '');

    if (existing == null) {
      // Persist immediately so autosave has a real row to update, and so
      // the note shows up right away if the user switches away and back.
      ref.read(notesProvider.notifier).add(_note);
    }

    _titleController.addListener(_scheduleSave);
    _bodyController.addListener(_scheduleSave);
    _categoryController.addListener(_scheduleSave);
  }

  Note? _findNote(String id) {
    for (final n in ref.read(notesProvider)) {
      if (n.id == id) return n;
    }
    return null;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _flushSave();
    _titleController.dispose();
    _bodyController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _scheduleSave() {
    _dirtySinceCreate = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _flushSave);
  }

  void _flushSave() {
    if (!_dirtySinceCreate) return;
    _dirtySinceCreate = false;
    final isEmpty = _titleController.text.trim().isEmpty && _bodyController.text.trim().isEmpty;
    if (isEmpty) {
      // Don't leave a completely blank note behind just because the user
      // opened the editor and left.
      ref.read(notesProvider.notifier).hardDelete(_note.id);
      return;
    }
    _note = _note.copyWith(
      title: _titleController.text,
      body: _bodyController.text,
      category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
    );
    ref.read(notesProvider.notifier).update(_note);
  }

  void _setColor(Color color) {
    setState(() => _note = _note.copyWith(colorValue: color.value));
    ref.read(notesProvider.notifier).update(_note);
  }

  Future<void> _importTxt() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    final content = await File(path).readAsString();
    setState(() {
      _bodyController.text = _bodyController.text.isEmpty
          ? content
          : '${_bodyController.text}\n$content';
    });
    _scheduleSave();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = Color(_note.colorValue);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: _note.isPinned ? l10n.notesUnpin : l10n.notesPin,
            icon: Icon(_note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined),
            onPressed: () {
              setState(() => _note = _note.copyWith(isPinned: !_note.isPinned));
              ref.read(notesProvider.notifier).update(_note);
            },
          ),
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'copy', child: Text(l10n.notesCopy)),
              PopupMenuItem(value: 'share', child: Text(l10n.notesShare)),
              PopupMenuItem(value: 'export_txt', child: Text(l10n.notesExportTxt)),
              PopupMenuItem(value: 'export_pdf', child: Text(l10n.notesExportPdf)),
              PopupMenuItem(value: 'print', child: Text(l10n.notesPrint)),
              PopupMenuItem(value: 'import_txt', child: Text(l10n.notesImportTxt)),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'archive', child: Text(l10n.notesArchive)),
              PopupMenuItem(value: 'delete', child: Text(l10n.notesMoveToTrash)),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ColorTagPicker(selected: color, onChanged: _setColor),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _titleController,
              style: Theme.of(context).textTheme.headlineSmall,
              maxLines: null,
              decoration: InputDecoration(
                hintText: l10n.notesTitleHint,
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _categoryController,
              style: Theme.of(context).textTheme.labelMedium,
              decoration: InputDecoration(
                hintText: l10n.notesCategoryHint,
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                prefixIcon: const Icon(Icons.label_outline_rounded, size: 18),
                prefixIconConstraints: const BoxConstraints(minWidth: 30),
              ),
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _bodyController,
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: l10n.notesBodyHint,
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onMenuSelected(String value) async {
    final l10n = context.l10n;
    final title = _titleController.text.trim().isEmpty ? l10n.notesUntitled : _titleController.text;
    final body = _bodyController.text;
    final dateLabel = DateTimeUtils.formatDateTime(_note.updatedAt, context.isArabic ? 'ar' : 'en');
    final combined = '$title\n\n$body';

    switch (value) {
      case 'copy':
        await ExportService.copyToClipboard(combined);
        if (mounted) _showSnack(l10n.notesCopied);
        break;
      case 'share':
        await ExportService.shareText(combined, subject: title);
        break;
      case 'export_txt':
        await ExportService.exportAndShareTxt(filenameWithoutExtension: title, content: combined);
        break;
      case 'export_pdf':
        await ExportService.exportAndSharePdf(
          filenameWithoutExtension: title,
          title: title,
          body: body,
          dateLabel: dateLabel,
          rtl: context.isArabic,
        );
        break;
      case 'print':
        await ExportService.printDocument(
          title: title,
          body: body,
          dateLabel: dateLabel,
          rtl: context.isArabic,
        );
        break;
      case 'import_txt':
        await _importTxt();
        break;
      case 'archive':
        ref.read(notesProvider.notifier).setArchived(_note, true);
        if (mounted) Navigator.of(context).pop();
        break;
      case 'delete':
        ref.read(notesProvider.notifier).moveToTrash(_note);
        if (mounted) Navigator.of(context).pop();
        break;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
