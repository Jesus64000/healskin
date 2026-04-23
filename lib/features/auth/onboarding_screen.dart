import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Datos actualizados basados en la visión del cliente
  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Bienvenido a HealSkin",
      "desc": "Tu compañero inteligente para el cuidado y preservación de la salud de tu piel.",
      "icon": "spa_outlined"
    },
    {
      "title": "Análisis con IA",
      "desc": "Realiza diagnósticos asistidos y monitoreo longitudinal con tecnología de vanguardia.",
      "icon": "biotech_outlined"
    },
    {
      "title": "Red de Guardianes",
      "desc": "Conéctate con especialistas a través de telemedicina y encuentra centros dermatológicos cercanos.",
      "icon": "medical_services_outlined"
    }
  ];

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case "spa_outlined": return Icons.spa_outlined;
      case "biotech_outlined": return Icons.biotech_outlined;
      case "medical_services_outlined": return Icons.medical_services_outlined;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight, // Ahora es blanco
      body: Stack(
        children: [
          // Ondas de color decorativas de fondo (típico del diseño skincare)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),

          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono estilizado
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Icon(
                        _getIcon(_onboardingData[index]["icon"]!),
                        size: 80,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 60),
                    Text(
                      _onboardingData[index]["title"]!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _onboardingData[index]["desc"]!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Indicadores y Botón de Acción
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _onboardingData.length,
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppColors.primary : AppColors.secondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _onboardingData.length - 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    child: Text(
                      _currentPage == _onboardingData.length - 1 ? "Comenzar" : "Siguiente",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (_currentPage != _onboardingData.length - 1)
                  TextButton(
                    onPressed: () => _pageController.jumpToPage(_onboardingData.length - 1),
                    child: const Text(
                      "Saltar",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}