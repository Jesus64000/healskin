import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

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
      "title": "Diagnóstico por IA",
      "desc": "Escanea tu piel en segundos y recibe un análisis preventivo impulsado por redes neuronales.",
      "icon": "auto_awesome"
    },
    {
      "title": "Conexión Médica",
      "desc": "Telemedicina integrada. Habla con especialistas y comparte tus resultados de forma encriptada.",
      "icon": "videocam"
    },
    {
      "title": "Monitoreo Evolutivo",
      "desc": "Sigue tu progreso en el tiempo con una línea de tiempo clínica inteligente.",
      "icon": "timeline"
    }
  ];

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case "auto_awesome": return Icons.auto_awesome;
      case "videocam": return Icons.videocam;
      case "timeline": return Icons.timeline;
      default: return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
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
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.glassOverlay),
                      ),
                      child: Icon(
                        _getIcon(_onboardingData[index]["icon"]!),
                        size: 48,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      _onboardingData[index]["title"]!,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.surfaceLight,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _onboardingData[index]["desc"]!,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.surfaceLight.withOpacity(0.7),
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
            bottom: 50,
            left: 40,
            right: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    _onboardingData.length,
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppColors.secondary : AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_currentPage == _onboardingData.length - 1) {
                      // Aquí navegaremos al Login en el próximo Sprint
                      debugPrint("Navegar al Login");
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Text(
                      _currentPage == _onboardingData.length - 1 ? "Comenzar" : "Siguiente",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}