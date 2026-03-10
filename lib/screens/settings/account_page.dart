import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import '../../widgets/gingham_pattern_background.dart';
import '../../widgets/stroked_button_label.dart';
import '../../widgets/tap_bounce.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  static const Color _primaryTextColor = Color(0xFF5D4A3A);
  static const Color _dangerTextColor = Color(0xFF9C2D2D);
  static const Color _dialogBorderColor = Color(0xFF8B6F47);
  static const Color _dialogBackgroundColor = Color(0xFFF5E6D3);

  final _authService = AuthService();
  final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  RoundedRectangleBorder _dialogShape() {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: _dialogBorderColor, width: 2),
    );
  }

  Text _dialogTitle(String title, {Color? color}) {
    return Text(
      title,
      style: GoogleFonts.fredoka(
        fontWeight: FontWeight.bold,
        color: color ?? _primaryTextColor,
      ),
    );
  }

  InputDecoration _dialogInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.fredoka(
        fontWeight: FontWeight.bold,
        color: _primaryTextColor,
      ),
      filled: true,
      fillColor: const Color(0xFFF8EFE3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _dialogBorderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _dialogBorderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryTextColor, width: 2),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFF9C2D2D) : null,
      ),
    );
  }

  Future<void> _showChangeEmailDialog() async {
    final newEmailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: _dialogBackgroundColor,
              shape: _dialogShape(),
              title: _dialogTitle('Change Email'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                    decoration: _dialogInputDecoration('New email'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                    decoration: _dialogInputDecoration('Current password'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: PressBounce(
                    enabled: !isSubmitting,
                    child: const StrokedButtonLabel(
                      'Cancel',
                      fillColor: _primaryTextColor,
                      strokeColor: _dialogBackgroundColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final newEmail = newEmailController.text.trim();
                          final currentPassword = passwordController.text;

                          if (!_emailRegex.hasMatch(newEmail)) {
                            _showMessage(
                              'Please enter a valid email address.',
                              isError: true,
                            );
                            return;
                          }

                          if (currentPassword.isEmpty) {
                            _showMessage(
                              'Current password is required.',
                              isError: true,
                            );
                            return;
                          }

                          setState(() => isSubmitting = true);
                          try {
                            await _authService.changeEmail(
                              currentPassword: currentPassword,
                              newEmail: newEmail,
                            );
                            if (!mounted || !dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            _showMessage(
                              'Verification sent. Your email updates after you confirm the link.',
                            );
                          } catch (e) {
                            _showMessage(e.toString(), isError: true);
                          } finally {
                            if (mounted) {
                              setState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: PressBounce(
                    enabled: !isSubmitting,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const StrokedButtonLabel(
                            'Save',
                            fillColor: _primaryTextColor,
                            strokeColor: _dialogBackgroundColor,
                          ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    newEmailController.dispose();
    passwordController.dispose();
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: _dialogBackgroundColor,
              shape: _dialogShape(),
              title: _dialogTitle('Change Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: true,
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                    decoration: _dialogInputDecoration('Current password'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                    decoration: _dialogInputDecoration('New password'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                    decoration: _dialogInputDecoration('Confirm new password'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: PressBounce(
                    enabled: !isSubmitting,
                    child: const StrokedButtonLabel(
                      'Cancel',
                      fillColor: _primaryTextColor,
                      strokeColor: _dialogBackgroundColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final currentPassword =
                              currentPasswordController.text;
                          final newPassword = newPasswordController.text;
                          final confirmPassword =
                              confirmPasswordController.text;

                          if (currentPassword.isEmpty ||
                              newPassword.isEmpty ||
                              confirmPassword.isEmpty) {
                            _showMessage(
                              'Please complete all fields.',
                              isError: true,
                            );
                            return;
                          }

                          if (newPassword.length < 6) {
                            _showMessage(
                              'New password must be at least 6 characters.',
                              isError: true,
                            );
                            return;
                          }

                          if (newPassword != confirmPassword) {
                            _showMessage(
                              'New password and confirmation do not match.',
                              isError: true,
                            );
                            return;
                          }

                          setState(() => isSubmitting = true);
                          try {
                            await _authService.changePassword(
                              currentPassword: currentPassword,
                              newPassword: newPassword,
                            );
                            if (!mounted || !dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            _showMessage('Password updated successfully.');
                          } catch (e) {
                            _showMessage(e.toString(), isError: true);
                          } finally {
                            if (mounted) {
                              setState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: PressBounce(
                    enabled: !isSubmitting,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const StrokedButtonLabel(
                            'Save',
                            fillColor: _primaryTextColor,
                            strokeColor: _dialogBackgroundColor,
                          ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _showDeleteAccountDialog() async {
    final passwordController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: _dialogBackgroundColor,
              shape: _dialogShape(),
              title: _dialogTitle('Delete Account', color: _dangerTextColor),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This action is permanent and cannot be undone.',
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.bold,
                      color: _primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                    decoration: _dialogInputDecoration('Current password'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: PressBounce(
                    enabled: !isSubmitting,
                    child: const StrokedButtonLabel(
                      'Cancel',
                      fillColor: _primaryTextColor,
                      strokeColor: _dialogBackgroundColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final currentPassword = passwordController.text;
                          if (currentPassword.isEmpty) {
                            _showMessage(
                              'Current password is required.',
                              isError: true,
                            );
                            return;
                          }

                          setState(() => isSubmitting = true);
                          try {
                            await _authService.deleteAccount(
                              currentPassword: currentPassword,
                            );
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
                              setState(() => isSubmitting = false);
                            }
                          }
                        },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: PressBounce(
                    enabled: !isSubmitting,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const StrokedButtonLabel(
                            'Delete',
                            fillColor: _dangerTextColor,
                            strokeColor: _dialogBackgroundColor,
                          ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
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
                        'Account Settings',
                        fillColor: Color(0xFF5D4A3A),
                        strokeColor: Color(0xFFF5E6D3),
                        fontSize: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildActionButton(
                    icon: Icons.alternate_email,
                    label: 'Change Email',
                    onTap: _showChangeEmailDialog,
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    icon: Icons.lock,
                    label: 'Change Password',
                    onTap: _showChangePasswordDialog,
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Danger Zone',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF9C2D2D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildActionButton(
                    icon: Icons.delete_forever,
                    label: 'Delete Account',
                    isDanger: true,
                    onTap: _showDeleteAccountDialog,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final Color backgroundColor = isDanger
        ? const Color(0xFFD36B6B)
        : const Color.fromARGB(255, 194, 143, 96);
    final Color borderColor = isDanger
        ? const Color(0xFF9C2D2D)
        : const Color.fromARGB(255, 93, 74, 58);

    return TapBounce(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
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
                strokeColor: borderColor,
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
