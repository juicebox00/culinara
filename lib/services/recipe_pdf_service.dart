import 'dart:io';

import 'package:culinara/models/recipe.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RecipePdfService {

  static Future<void> exportRecipeToPdf(Recipe recipe) async {
    final doc = pw.Document();

    pw.Widget section(String label, String value) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 4),
          pw.Text(value.isEmpty ? 'Not specified' : value),
          pw.SizedBox(height: 12),
        ],
      );
    }

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            recipe.title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24),
          ),
          pw.SizedBox(height: 12),
          section('Ingredients', recipe.ingredients),
          section('Directions', recipe.directions),
          section('Source', recipe.sourceUrl),
          section('Notes', recipe.notes),
          section(
            'Shelves',
            recipe.shelves.isEmpty
                ? 'No shelves added'
                : recipe.shelves.join(', '),
          ),
          section('Serving Size', recipe.servingSize),
          section('Cooking Time', recipe.cookingTime),
          section(
            'Tags',
            recipe.tags.isEmpty
                ? 'No tags added'
                : recipe.tags.map((e) => '#$e').join(', '),
          ),
        ],
      ),
    );

    final fileName =
        '${recipe.title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.pdf';
    final pdfBytes = await doc.save();

    try {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Recipe PDF',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        bytes: pdfBytes,
      );

      // Some platforms return a path but do not write bytes. Ensure file exists.
      if (savePath != null) {
        final file = File(savePath);
        if (!await file.exists()) {
          await file.writeAsBytes(pdfBytes, flush: true);
        }
        return;
      }
    } catch (_) {
      // Fallback below handles platforms without save-file support.
    }

    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }
}
