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
    // Persistent controllers for dialogs
    final TextEditingController _changeEmailController = TextEditingController();
    final TextEditingController _changeEmailPasswordController = TextEditingController();
    final TextEditingController _changePasswordCurrentController = TextEditingController();
    final TextEditingController _changePasswordNewController = TextEditingController();
    final TextEditingController _changePasswordConfirmController = TextEditingController();
    final TextEditingController _deleteAccountPasswordController = TextEditingController();
    @override
    void dispose() {
      _changeEmailController.dispose();
      _changeEmailPasswordController.dispose();
      _changePasswordCurrentController.dispose();
      _changePasswordNewController.dispose();
      _changePasswordConfirmController.dispose();
      _deleteAccountPasswordController.dispose();
      super.dispose();
    }
  static const Color _primaryTextColor = Color(0xFF5D4A3A);
  static const Color _dangerTextColor = Color(0xFF9C2D2D);
  static const Color _dialogBorderColor = Color(0xFF8B6F47);
  static const Color _dialogBackgroundColor = Color(0xFFF5E6D3);

  final _authService = AuthService();
  final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  // Check if user has a password (email/password auth, not Google sign-in)
  bool _userHasPassword() {
    final user = _authService.currentUser;
    if (user == null) return false;
    
    // Check if user has email/password provider
    for (var provider in user.providerData) {
      if (provider.providerId == 'password') {
        return true;
      }
    }
    return false;
  }

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
      labelStyle: const TextStyle(
        fontFamily: 'Fredoka',
        fontWeight: FontWeight.bold,
        color: _primaryTextColor,
      ),
      filled: true,
      fillColor: const Color(0xFFF8EFE3),
      enabledBorder: UnderlineInputBorder(
        borderSide: const BorderSide(color: _dialogBorderColor, width: 1.5),
      ),
      focusedBorder: UnderlineInputBorder(
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
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
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
                    controller: _changeEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                      color: _primaryTextColor,
                    ),
                    decoration: _dialogInputDecoration('New email'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _changeEmailPasswordController,
                    obscureText: true,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                      color: _primaryTextColor,
                    ),
                    decoration: _dialogInputDecoration('Current password'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const StrokedButtonLabel(
                    'Cancel',
                    fillColor: _primaryTextColor,
                    strokeColor: _dialogBackgroundColor,
                  ),
                ),
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final newEmail = _changeEmailController.text.trim();
                          final currentPassword = _changeEmailPasswordController.text;

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
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog() async {
    bool isSubmitting = false;
    bool hasPassword = _userHasPassword();
    final dialogTitle = hasPassword ? 'Change Password' : 'Set Password';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: _dialogBackgroundColor,
              shape: _dialogShape(),
              title: _dialogTitle(dialogTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Only show "Current password" field if user has a password
                  if (hasPassword)
                    Column(
                      children: [
                        TextField(
                          controller: _changePasswordCurrentController,
                          obscureText: true,
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.bold,
                            color: _primaryTextColor,
                          ),
                          decoration: _dialogInputDecoration('Current password'),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  TextField(
                    controller: _changePasswordNewController,
                    obscureText: true,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                      color: _primaryTextColor,
                    ),
                    decoration: _dialogInputDecoration(
                      hasPassword ? 'New password' : 'Password',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _changePasswordConfirmController,
                    obscureText: true,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                      color: _primaryTextColor,
                    ),
                    decoration: _dialogInputDecoration(
                      hasPassword ? 'Confirm new password' : 'Confirm password',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const StrokedButtonLabel(
                    'Cancel',
                    fillColor: _primaryTextColor,
                    strokeColor: _dialogBackgroundColor,
                  ),
                ),
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final newPassword = _changePasswordNewController.text;
                          final confirmPassword = _changePasswordConfirmController.text;
                          final currentPassword = _changePasswordCurrentController.text;

                          // For "Change Password" - require current password
                          if (hasPassword && currentPassword.isEmpty) {
                            _showMessage(
                              'Please enter your current password.',
                              isError: true,
                            );
                            return;
                          }

                          if (newPassword.isEmpty || confirmPassword.isEmpty) {
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
                              'Password does not match confirmation.',
                              isError: true,
                            );
                            return;
                          }

                          setState(() => isSubmitting = true);
                          try {
                            await _authService.changePassword(
                              currentPassword: hasPassword ? currentPassword : '',
                              newPassword: newPassword,
                            );
                            if (!mounted || !dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            final message = hasPassword
                                ? 'Password updated successfully.'
                                : 'Password set successfully.';
                            _showMessage(message);
                            // Clear controllers
                            _changePasswordCurrentController.clear();
                            _changePasswordNewController.clear();
                            _changePasswordConfirmController.clear();
                          } catch (e) {
                            _showMessage(e.toString(), isError: true);
                          } finally {
                            if (mounted) {
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
                      : StrokedButtonLabel(
                          hasPassword ? 'Save' : 'Set Password',
                          fillColor: _primaryTextColor,
                          strokeColor: _dialogBackgroundColor,
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    bool isSubmitting = false;
    bool hasPassword = _userHasPassword();

    await showDialog(
      context: context,
      barrierDismissible: false,
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
                    hasPassword
                        ? 'This action is permanent and cannot be undone.'
                        : 'Are you sure you want to delete your account? This action cannot be undone.',
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.bold,
                      color: _primaryTextColor,
                    ),
                  ),
                  // Only show password field for email/password users
                  if (hasPassword) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _deleteAccountPasswordController,
                      obscureText: true,
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.bold,
                        color: _primaryTextColor,
                      ),
                      decoration: _dialogInputDecoration('Current password'),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: StrokedButtonLabel(
                    hasPassword ? 'Cancel' : 'No',
                    fillColor: _primaryTextColor,
                    strokeColor: _dialogBackgroundColor,
                  ),
                ),
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setState(() => isSubmitting = true);
                          
                          try {
                            // Prepare password (empty for Google users)
                            final password = hasPassword 
                                ? _deleteAccountPasswordController.text 
                                : '';
                            
                            if (hasPassword && password.isEmpty) {
                              _showMessage(
                                'Current password is required.',
                                isError: true,
                              );
                              setState(() => isSubmitting = false);
                              return;
                            }

                            // Delete account
                            await _authService.deleteAccount(
                              currentPassword: password,
                            );
                            
                            if (!mounted || !dialogContext.mounted) return;
                            
                            // Show success message before navigation
                            _showMessage('Account deleted successfully.');
                            
                            // Wait a moment for Firebase to complete deletion and UI to update
                            await Future.delayed(const Duration(milliseconds: 800));
                            
                            if (!mounted) return;
                            
                            // Close dialog
                            Navigator.of(dialogContext).pop();
                            
                            // Navigate to login page
                            Navigator.of(this.context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                              (route) => false,
                            );
                          } catch (e) {
                            if (mounted) {
                              _showMessage(e.toString(), isError: true);
                            }
                          } finally {
                            if (mounted) {
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
                      : StrokedButtonLabel(
                          hasPassword ? 'Delete' : 'Yes',
                          fillColor: _dangerTextColor,
                          strokeColor: _dialogBackgroundColor,
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
                  // Only show "Change Email" for email/password users
                  if (_userHasPassword()) ...[
                    _buildActionButton(
                      icon: Icons.alternate_email,
                      label: 'Change Email',
                      onTap: _showChangeEmailDialog,
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Show "Change Password" only if user has password (email/password auth)
                  if (_userHasPassword()) ...[
                    _buildActionButton(
                      icon: Icons.lock,
                      label: 'Change Password',
                      onTap: _showChangePasswordDialog,
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 24),
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
