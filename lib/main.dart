import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/doctor/doctor_dashboard.dart';
import 'features/patient/patient_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://uceithusnfqmcbxoptcu.supabase.co', // TODO: Pega aquí tu URL
    anonKey: 'sb_publishable_mvlT5LVYzKjmbyavFFmYYw_tTD0KF4e', // TODO: Pega aquí tu clave anónima
  );
  runApp(const ProviderScope(child: HealSkinApp()));
}

class HealSkinApp extends ConsumerWidget {
  const HealSkinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'HealSkin',
      debugShowCheckedModeBanner: false,
      // CAMBIO ESTÉTICO: Forzamos el modo claro
      themeMode: ThemeMode.light,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundLight,
        // Textos oscuros por defecto para el modo claro
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme).apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
      ),
      home: const AuthGatekeeper(),
    );
  }
}

class AuthGatekeeper extends ConsumerWidget {
  const AuthGatekeeper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (authState.session == null) {
      return const LoginScreen();
    }
    return authState.role == UserRole.doctor
        ? const DoctorDashboard()
        : const PatientDashboard();
  }
}