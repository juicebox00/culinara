import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../widgets/moving_tile_pattern.dart';
import '../auth/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _authService = AuthService();

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _authService.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
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
          const MovingTilePattern(),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  
                  // My Profile Section
                  Column(
                    children: [
                      // Profile Title
                      Text(
                        'My Profile',
                        style: GoogleFonts.fredoka(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5D4A3A),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Profile Picture Circle
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF8B6F47),
                            width: 4,
                          ),
                          color: const Color(0xFFF5E6D3),
                          image: const DecorationImage(
                            image: AssetImage('images/culinara_logo.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // User Email
                      Text(
                        userEmail,
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          color: const Color(0xFF5D4A3A),
                          fontWeight: FontWeight.w600,
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
                            // TODO: Navigate to Account settings
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account settings coming soon'),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        // About Us Button
                        _buildSettingsButton(
                          icon: Icons.info,
                          label: 'About Us',
                          onTap: () {
                            // TODO: Navigate to About Us
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('About Us coming soon'),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFDF9262),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF5D4A3A),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Stack(
                children: [
                  // Outline/stroke effect
                  Text(
                    label,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5D4A3A),
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 1.5
                        ..color = const Color(0xFF5D4A3A),
                    ),
                  ),
                  // Main text
                  Text(
                    label,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
