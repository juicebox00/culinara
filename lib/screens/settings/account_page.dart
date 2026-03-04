import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import '../../widgets/moving_tile_pattern.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _authService = AuthService();
  final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  InputDecoration _dialogInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.fredoka(
        fontWeight: FontWeight.bold,
        color: const Color(0xFF5D4A3A),
      ),
      filled: true,
      fillColor: const Color(0xFFF8EFE3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8B6F47), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8B6F47), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5D4A3A), width: 2),
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
              backgroundColor: const Color(0xFFF5E6D3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
              ),
              title: Text(
                'Change Email',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D4A3A),
                ),
              ),
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
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5D4A3A),
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
                            if (!mounted) return;
                            Navigator.pop(dialogContext);
                            _showMessage(
                              'Verification sent. Your email updates after you confirm the link.',
                            );
                          } catch (e) {
                            _showMessage(e.toString(), isError: true);
                          } finally {
                            if (context.mounted) {
                              setState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Save',
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D4A3A),
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
              backgroundColor: const Color(0xFFF5E6D3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
              ),
              title: Text(
                'Change Password',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D4A3A),
                ),
              ),
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
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5D4A3A),
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
                            if (!mounted) return;
                            Navigator.pop(dialogContext);
                            _showMessage('Password updated successfully.');
                          } catch (e) {
                            _showMessage(e.toString(), isError: true);
                          } finally {
                            if (context.mounted) {
                              setState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Save',
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D4A3A),
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
              backgroundColor: const Color(0xFFF5E6D3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
              ),
              title: Text(
                'Delete Account',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF9C2D2D),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This action is permanent and cannot be undone.',
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5D4A3A),
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
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5D4A3A),
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
                            if (!mounted) return;
                            Navigator.of(dialogContext).pop();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                              (route) => false,
                            );
                          } catch (e) {
                            _showMessage(e.toString(), isError: true);
                          } finally {
                            if (context.mounted) {
                              setState(() => isSubmitting = false);
                            }
                          }
                        },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Delete',
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF9C2D2D),
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
          const MovingTilePattern(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        color: const Color(0xFF5D4A3A),
                      ),
                      Text(
                        'Account Settings',
                        style: GoogleFonts.fredoka(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5D4A3A),
                        ),
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
