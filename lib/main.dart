import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirestoreService().seedInitialEvents();
  runApp(const EvokeApp());
}

class EvokeApp extends StatelessWidget {
  const EvokeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Premium Light Theme Palette
    const Color primaryAccent = Color(0xFFD73B22); // Deep Red-Orange
    const Color backgroundGray = Color(0xFFF5F5F7); // Off-white
    const Color charcoalBlack = Color(0xFF1A1A1A); // Dark Charcoal

    return MaterialApp(
      title: 'Evoke',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: backgroundGray,
        primaryColor: primaryAccent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryAccent,
          primary: primaryAccent,
          surface: Colors.white,
          background: backgroundGray,
        ),
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          displayLarge: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            color: charcoalBlack,
            fontSize: 32,
          ),
          titleLarge: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: charcoalBlack,
            fontSize: 20,
          ),
          bodyLarge: GoogleFonts.poppins(
            color: Colors.grey[800],
            fontSize: 16,
          ),
          bodyMedium: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundGray,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: charcoalBlack,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
          iconTheme: IconThemeData(color: charcoalBlack),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData) {
          return const MainNavigationScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BookingsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _screens[_selectedIndex],
          // Custom Floating Navigation Bar (Glassmorphism)
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: Container(
                  height: 75,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withOpacity(0.65),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.explore_rounded),
                      _buildNavItem(1, Icons.confirmation_number_rounded),
                      _buildNavItem(2, Icons.person_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD73B22) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
