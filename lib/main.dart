import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/splash_screen.dart'; // Importante tenerlo aquí
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar formateo de fechas localizadas en español
  await initializeDateFormatting('es_ES', null);

  // 1. Carga de variables de entorno
  await dotenv.load(fileName: ".env");

  // 2. Inicialización de Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 3. Inicialización de Notificaciones Locales
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();

  runApp(const ProviderScope(child: HealSkinApp()));
}

class HealSkinApp extends ConsumerWidget {
  const HealSkinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'HealSkin',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundLight,
        // Configuración global de fuentes
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: Colors.white,
        ),
        useMaterial3: true, // Habilitamos Material 3 para un look más moderno
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // Inglés
      ],
      locale: const Locale('es', 'ES'), // Forzar Español por defecto
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
      // 3. CAMBIO CLAVE: El punto de entrada ahora es el Splash
      // Él decidirá si va a Login, Onboarding o Dashboard
      home: const SplashScreen(),
    );
  }
}