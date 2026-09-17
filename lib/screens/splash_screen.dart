import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

/// A premium, animated Splash Screen for the Evoke app.
/// Featuring a typewriter animation for the brand name.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the Animation Controller for the logo
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.8, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    // Navigate after exactly 3 seconds
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Exact 3-second display duration
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    final authService = AuthService();
    final bool loggedIn = await authService.isLoggedIn();

    if (!mounted) return;

    // Seamless Fade Transition to the next screen
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            loggedIn ? const MainNavigationScreen() : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFFF9030); // Toxic Violex
    const Color backgroundColor = Color(0xFF111827); // Soft Chrome

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with Fade and Scale Animation
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Image.asset(
                      'assets/icon.png',
                      width: 120, // Adjusted for balanced layout
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Typewriter Animation for "Evoke"
            AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  'Evoke',
                  textStyle: GoogleFonts.montserrat(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 4.0,
                  ),
                  speed: const Duration(milliseconds: 200),
                ),
              ],
              totalRepeatCount: 1,
              displayFullTextOnTap: true,
              stopPauseOnTap: true,
            ),
          ],
        ),
      ),
    );
  }
}
