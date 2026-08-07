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
    },
    {
      "title": "Uso Personal e Individual",
      "desc": "HealSkin está diseñado para uso estrictamente personal. Evita prestar tu cuenta o dispositivo a terceros para preservar la precisión de tu historial clínico e IA.",
      "icon": "verified_user_outlined"
    }
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case "spa_outlined": return Icons.spa_outlined;
      case "biotech_outlined": return Icons.biotech_outlined;
      case "medical_services_outlined": return Icons.medical_services_outlined;
      case "verified_user_outlined": return Icons.verified_user_outlined;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea( // Protege contra el notch y bordes redondeados
        child: Stack(
          children: [
            // Círculo decorativo de fondo
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

            // Contenido principal estructurado
            Column(
              children: [
                // 1. PageView se expande solo en el espacio disponible superior
                Expanded(
                  child: PageView.builder(
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
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.2),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _onboardingData[index]["desc"]!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // 2. Sección inferior (fija) con indicadores y botones
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 20, 40, 30), // Espaciado seguro al fondo
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Ocupa solo lo necesario
                    children: [
                      // Indicadores
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
                      const SizedBox(height: 30), // Separación entre indicadores y botón

                      // Botón Principal
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 5,
                            shadowColor: AppColors.primary.withValues(alpha: 0.4),
                          ),
                          child: Text(
                            _currentPage == _onboardingData.length - 1 ? "Comenzar" : "Siguiente",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      // Espacio fijo para el botón saltar, evita que la altura total cambie
                      SizedBox(
                        height: 48,
                        child: _currentPage != _onboardingData.length - 1
                            ? TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: const Text("Saltar", style: TextStyle(color: AppColors.textSecondary)),
                        )
                            : null, // Si es la última página, deja el espacio vacío
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}