import 'dart:io';
import 'dart:typed_data';

import 'package:culinara/models/recipe.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class RecipePdfService {
  static Future<Recipe?> importRecipeFromPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final PlatformFile file = result.files.first;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) return null;

    final document = PdfDocument(inputBytes: bytes);
    final text = PdfTextExtractor(document).extractText();
    document.dispose();

    return _parseRecipeText(
      text,
      fallbackTitle: (file.name.isEmpty ? 'Imported Recipe' : file.name)
          .replaceAll('.pdf', ''),
    );
  }

  static Recipe _parseRecipeText(String text, {required String fallbackTitle}) {
    final normalized = text.replaceAll('\r\n', '\n').trim();
    final lines = normalized
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    String extractSingleLineField(String label) {
      final prefix = '$label:';
      for (final line in lines) {
        if (line.toLowerCase().startsWith(prefix.toLowerCase())) {
          return line.substring(prefix.length).trim();
        }
      }
      return '';
    }

    String extractSection(String startLabel, List<String> endLabels) {
      final lower = normalized.toLowerCase();
      final startToken = '$startLabel:';
      final start = lower.indexOf(startToken.toLowerCase());
      if (start == -1) return '';

      final contentStart = start + startToken.length;
      int end = normalized.length;

      for (final endLabel in endLabels) {
        final token = '\n$endLabel:';
        final candidate = lower.indexOf(token.toLowerCase(), contentStart);
        if (candidate != -1 && candidate < end) {
          end = candidate;
        }
      }

      return normalized.substring(contentStart, end).trim();
    }

    final titleFromField = extractSingleLineField('title');
    final ingredientsFromField = extractSection(
      'ingredients',
      const ['directions', 'instructions', 'serving size', 'cooking time', 'tags'],
    );
    final directionsFromField = extractSection(
      'directions',
      const ['serving size', 'cooking time', 'tags'],
    ).isNotEmpty
        ? extractSection(
            'directions',
            const ['serving size', 'cooking time', 'tags'],
          )
        : extractSection(
            'instructions',
            const ['serving size', 'cooking time', 'tags'],
          );

    final servingFromField = extractSingleLineField('serving size');
    final cookingFromField = extractSingleLineField('cooking time');
    final tagsFromField = extractSingleLineField('tags');

    final String title = titleFromField.isNotEmpty
        ? titleFromField
        : (lines.isNotEmpty ? lines.first : fallbackTitle);

    final String ingredients = ingredientsFromField.isNotEmpty
        ? ingredientsFromField
        : '';

    final String directions = directionsFromField.isNotEmpty
        ? directionsFromField
        : (ingredients.isEmpty ? normalized : '');

    final List<String> tags = tagsFromField
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    return Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      imagePath: 'images/placeholder_thumbnail.png',
      ingredients: ingredients,
      directions: directions,
      servingSize: servingFromField,
      cookingTime: cookingFromField,
      tags: tags,
    );
  }

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
          section('Serving Size', recipe.servingSize),
          section('Cooking Time', recipe.cookingTime),
          section(
            'Tags',
            recipe.tags.isEmpty ? 'No tags added' : recipe.tags.map((e) => '#$e').join(', '),
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
