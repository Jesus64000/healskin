import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/splash_screen.dart'; // Lo crearemos ahora

void main() {
  runApp(
    // ProviderScope es obligatorio para usar Riverpod en toda la app
    const ProviderScope(
      child: HealSkinApp(),
    ),
  );
}

class HealSkinApp extends StatelessWidget {
  const HealSkinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealSkin',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // Forzamos el modo oscuro moderno por ahora
      darkTheme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundDark,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}