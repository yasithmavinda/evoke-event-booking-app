import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'add_event_screen.dart';
import 'organizer_dashboard_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF1F2937),
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          // Stream of auth state to show current user email
          StreamBuilder(
            stream: authService.userStream,
            builder: (context, snapshot) {
              final user = snapshot.data;
              return Text(user?.email ?? 'User', style: Theme.of(context).textTheme.titleLarge);
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrganizerDashboardScreen()),
              );
            },
            child: const Text('Organizer Dashboard'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              await authService.logout();
              // AuthWrapper in main.dart handles the UI switch
            },
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
