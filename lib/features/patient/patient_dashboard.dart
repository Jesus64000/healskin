import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// Importamos las vistas (por ahora usaremos el Home actualizado y placeholders para el resto)
import 'views/patient_home_view.dart';
import 'views/patient_timeline_view.dart';
import 'views/patient_clinic_view.dart';
import 'views/patient_map_view.dart';
import 'views/patient_profile_view.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _currentIndex = 2; // Inicia en la posición 2 (Inicio)

  late final List<Widget> _views;

  @override
  void initState() {
    super.initState();
    // Orden exacto según el diseño del cliente: Médicos, Monitoreo, Inicio, IA, Perfil
    _views = [
      const PatientClinicView(),    // 0: Médicos (Telemedicina)
      const PatientTimelineView(),  // 1: Monitoreo
      const PatientHomeView(),      // 2: Inicio (Hub)
      const Center(child: Text("Módulo IA en construcción", style: TextStyle(color: AppColors.textPrimary))), // 3: IA
      const PatientProfileView(),   // 4: Perfil
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
            ]
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.medical_services_outlined, "Médicos", 0),
                _buildNavItem(Icons.monitor_heart_outlined, "Monitoreo", 1),
                _buildCenterNavItem(Icons.home_outlined, "Inicio", 2),
                _buildNavItem(Icons.psychology_outlined, "IA", 3),
                _buildNavItem(Icons.person_outline, "Perfil", 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          )
        ],
      ),
    );
  }

  // El botón central ("Inicio") tiene un círculo salmón de fondo según el diseño
  Widget _buildCenterNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 28
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          )
        ],
      ),
    );
  }
}