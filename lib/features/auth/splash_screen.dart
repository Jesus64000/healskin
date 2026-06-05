import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'onboarding_screen.dart';
import 'auth_provider.dart';
import 'initial_quiz_screen.dart';
import 'login_screen.dart';
import '../doctor/doctor_dashboard.dart';
import '../doctor/doctor_setup_screen.dart';
import '../doctor/doctor_pending_approval_screen.dart';
import '../patient/patient_dashboard.dart';
import '../admin/admin_dashboard.dart'; // IMPORTAMOS EL PANEL DE ADMIN

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _minDurationElapsed = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // 2 segundos mínimos de animación estética
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _minDurationElapsed = true;
      });
      _checkAndNavigate();
    });
  }

  void _checkAndNavigate() {
    if (_hasNavigated || !_minDurationElapsed) return;

    final authState = ref.read(authProvider);
    if (!authState.isInitialized) return; // Esperar a que la autenticación cargue completamente

    _hasNavigated = true;

    Widget nextScreen;

    if (authState.isPasswordRecovery) {
      nextScreen = const LoginScreen();
    } else if (authState.session != null) {
      if (authState.role == UserRole.admin) {
        nextScreen = const AdminDashboard();
      } else if (authState.role == UserRole.doctor) {
        if (!authState.hasCompletedSetup) {
          nextScreen = const DoctorSetupScreen();
        } else if (!authState.isApproved) {
          nextScreen = const DoctorPendingApprovalScreen();
        } else {
          nextScreen = const DoctorDashboard();
        }
      } else {
        nextScreen = authState.hasCompletedQuiz ? const PatientDashboard() : const InitialQuizScreen();
      }
    } else {
      nextScreen = const OnboardingScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, _, __) => nextScreen,
        transitionsBuilder: (context, anim, _, child) => FadeTransition(opacity: anim, child: child),
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
    // Escuchar reactivamente los cambios en el estado de autenticación
    ref.listen<HealSkinAuthState>(authProvider, (previous, next) {
      if (next.isInitialized) {
        _checkAndNavigate();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              AppColors.surfaceDark.withValues(alpha: 0.3),
              AppColors.backgroundLight,
            ],
            center: Alignment.center,
            radius: 1.2,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                        Icons.health_and_safety,
                        size: 100,
                        color: AppColors.primary
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text('HealSkin', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Inteligencia dermatológica', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.secondary)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}