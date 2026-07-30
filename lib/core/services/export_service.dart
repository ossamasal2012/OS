import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle, Clipboard, ClipboardData;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Export / share / print / copy — used by Notes today, generic enough for
/// any feature that later wants "share as text/PDF" (e.g. a Goal or a
/// Statistics summary).
class ExportService {
  ExportService._();

  static pw.Font? _cachedFont;

  static Future<pw.Font> _cairoFont() async {
    if (_cachedFont != null) return _cachedFont!;
    final data = await rootBundle.load('assets/fonts/Cairo-Variable.ttf');
    _cachedFont = pw.Font.ttf(data);
    return _cachedFont!;
  }

  static Future<void> copyToClipboard(String text) {
    return Clipboard.setData(ClipboardData(text: text));
  }

  static Future<void> shareText(String text, {String? subject}) {
    return SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  /// Writes [content] to a temporary .txt file and opens the native share
  /// sheet — the standard mobile way to let the user "save" a file (to
  /// Drive, Files, WhatsApp, etc.) without the app needing broad storage
  /// permissions.
  static Future<void> exportAndShareTxt({
    required String filenameWithoutExtension,
    required String content,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filenameWithoutExtension.txt');
    await file.writeAsString(content);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  static Future<Uint8List> _buildPdfBytes({
    required String title,
    required String body,
    required String dateLabel,
    required bool rtl,
  }) async {
    final font = await _cairoFont();
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: font),
    );
    doc.addPage(
      pw.MultiPage(
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            title.isEmpty ? '-' : title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            dateLabel,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Divider(height: 20),
          pw.Text(body, style: const pw.TextStyle(fontSize: 13, lineSpacing: 3)),
        ],
      ),
    );
    return doc.save();
  }

  static Future<void> exportAndSharePdf({
    required String filenameWithoutExtension,
    required String title,
    required String body,
    required String dateLabel,
    required bool rtl,
  }) async {
    final bytes = await _buildPdfBytes(title: title, body: body, dateLabel: dateLabel, rtl: rtl);
    await Printing.sharePdf(bytes: bytes, filename: '$filenameWithoutExtension.pdf');
  }

  static Future<void> printDocument({
    required String title,
    required String body,
    required String dateLabel,
    required bool rtl,
  }) async {
    await Printing.layoutPdf(
      onLayout: (format) => _buildPdfBytes(title: title, body: body, dateLabel: dateLabel, rtl: rtl),
    );
  }
}
