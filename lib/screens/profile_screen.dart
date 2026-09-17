import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'organizer_dashboard_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    const Color primaryAccent = Color(0xFFD73B22);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: Icon(Icons.person_rounded, size: 60, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            StreamBuilder(
              stream: authService.userStream,
              builder: (context, snapshot) {
                final user = snapshot.data;
                return Text(
                  user?.email ?? 'User',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                );
              },
            ),
            const SizedBox(height: 40),
            
            _buildProfileMenu(
              context,
              icon: Icons.dashboard_customize_rounded,
              title: 'Organizer Dashboard',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrganizerDashboardScreen())),
            ),
            _buildProfileMenu(
              context,
              icon: Icons.logout_rounded,
              title: 'Logout',
              color: Colors.redAccent,
              onTap: () async => await authService.logout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tileColor: Colors.white,
        leading: Icon(icon, color: color ?? const Color(0xFFD73B22)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? const Color(0xFF1A1A1A))),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      ),
    );
  }
}
