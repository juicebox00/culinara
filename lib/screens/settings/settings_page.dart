import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/background_music_service.dart';
import '../../widgets/gingham_pattern_background.dart';
import '../../widgets/stroked_button_label.dart';
import '../../widgets/tap_bounce.dart';
import '../auth/login_page.dart';
import 'appearance_page.dart';
import 'account_page.dart';
import 'data_management_page.dart';
import 'system_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _authService = AuthService();
  bool _isLoggingOut = false;

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFF9C2D2D) : null,
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF5E6D3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
              ),
              title: Text(
                'Logout',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D4A3A),
                ),
              ),
              content: Text(
                'Are you sure you want to logout?',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D4A3A),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isLoggingOut
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: PressBounce(
                    enabled: !_isLoggingOut,
                    child: const StrokedButtonLabel(
                      'Cancel',
                      fillColor: Color(0xFF5D4A3A),
                      strokeColor: Color(0xFFF5E6D3),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isLoggingOut
                      ? null
                      : () async {
                          setState(() => _isLoggingOut = true);
                          setDialogState(() {});
                          try {
                            await _authService.logout();
                            await BackgroundMusicService.instance
                                .setAuthTrack();
                            if (!mounted || !dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            Navigator.of(this.context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                              (route) => false,
                            );
                          } catch (e) {
                            _showMessage(e.toString(), isError: true);
                          } finally {
                            if (mounted) {
                              setState(() => _isLoggingOut = false);
                              if (dialogContext.mounted) {
                                setDialogState(() {});
                              }
                            }
                          }
                        },
                  child: PressBounce(
                    enabled: !_isLoggingOut,
                    child: _isLoggingOut
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const StrokedButtonLabel(
                            'Logout',
                            fillColor: Color(0xFF9C2D2D),
                            strokeColor: Color(0xFFF5E6D3),
                          ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final userEmail = user?.email ?? '@example@gmail.com';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const GinghamPatternBackground(),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // My Profile Section
                  Column(
                    children: [
                      // User Email
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5E6D3),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF8B6F47),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.alternate_email,
                              color: Color(0xFF5D4A3A),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                userEmail,
                                style: GoogleFonts.fredoka(
                                  fontSize: 16,
                                  color: const Color(0xFF5D4A3A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Settings Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Settings',
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5D4A3A),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Settings Options
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        // Account Button
                        _buildSettingsButton(
                          icon: Icons.person,
                          label: 'Account',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AccountPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        _buildSettingsButton(
                          icon: Icons.tune_rounded,
                          label: 'System',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SystemPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        _buildSettingsButton(
                          icon: Icons.palette,
                          label: 'Appearance',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AppearancePage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // Data Management Button
                        _buildSettingsButton(
                          icon: Icons.storage_rounded,
                          label: 'Data Management',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DataManagementPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // Logout Button
                        _buildSettingsButton(
                          icon: Icons.logout,
                          label: 'Logout',
                          onTap: _logout,
                          isLogout: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return TapBounce(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 194, 143, 96),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: StrokedButtonLabel(
                label,
                fillColor: Colors.white,
                strokeColor: const Color(0xFF5D4A3A),
                fontSize: 18,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
