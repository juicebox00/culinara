import 'package:culinara/services/data_management_service.dart';
import 'package:culinara/widgets/gingham_pattern_background.dart';
import 'package:culinara/widgets/stroked_button_label.dart';
import 'package:culinara/widgets/tap_bounce.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DataManagementPage extends StatefulWidget {
  const DataManagementPage({super.key});

  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  bool _isExporting = false;
  bool _isImporting = false;

  bool get _isBusy => _isExporting || _isImporting;

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFF9C2D2D) : null,
      ),
    );
  }

  Future<void> _exportData() async {
    if (_isBusy) return;
    setState(() => _isExporting = true);

    try {
      final path = await DataManagementService.exportData();
      if (path == null) {
        _showMessage('Export cancelled.');
        return;
      }
      _showMessage('Data exported successfully.');
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importData() async {
    if (_isBusy) return;

    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5E6D3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
        ),
        title: Text(
          'Import Backup?',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        content: Text(
          'This will replace current recipes, drafts, and saved settings.',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const StrokedButtonLabel(
              'Cancel',
              fillColor: Color(0xFF5D4A3A),
              strokeColor: Color(0xFFF5E6D3),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const StrokedButtonLabel(
              'Import',
              fillColor: Color(0xFF9C2D2D),
              strokeColor: Color(0xFFF5E6D3),
            ),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    setState(() => _isImporting = true);
    try {
      await DataManagementService.importData();
      _showMessage('Backup imported successfully.');
    } catch (e) {
      final text = e.toString();
      final cancelled = text.contains('No backup file selected.');
      _showMessage(cancelled ? 'Import cancelled.' : text, isError: !cancelled);
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const GinghamPatternBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PressBounce(
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          color: const Color(0xFF5D4A3A),
                        ),
                      ),
                      const StrokedButtonLabel(
                        'Data Management',
                        fillColor: Color(0xFF5D4A3A),
                        strokeColor: Color(0xFFF5E6D3),
                        fontSize: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5E6D3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF8B6F47),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Backup and restore your app data.',
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D4A3A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Export saves recipes, drafts, and music/SFX settings. Import replaces the current local data.',
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7A6450),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: PressBounce(
                      enabled: !_isBusy,
                      child: ElevatedButton.icon(
                        onPressed: _isBusy ? null : _exportData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5E3C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: _isExporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.upload_file),
                        label: const StrokedButtonLabel('Export Data'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: PressBounce(
                      enabled: !_isBusy,
                      child: ElevatedButton.icon(
                        onPressed: _isBusy ? null : _importData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB96E3A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: _isImporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download_for_offline),
                        label: const StrokedButtonLabel('Import Data'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
