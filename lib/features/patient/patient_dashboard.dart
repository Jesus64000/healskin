import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';

// 🚀 IMPORT CRÍTICO: Asegúrate de que esta ruta apunte a donde tienes tu userProfileProvider
import '../auth/profile_provider.dart';

import 'views/patient_home_view.dart';
import 'views/patient_timeline_view.dart';
import 'views/patient_appointments_view.dart';
import 'views/patient_map_view.dart'; // 🚀 NUEVO IMPORT: Clínicas
import '../ai_scanner/views/ai_scanner_view.dart';

// Provider global para controlar reactivamente la pestaña activa del dashboard (2 es Inicio por defecto)
final patientTabProvider = StateProvider<int>((ref) => 2);

class PatientDashboard extends ConsumerStatefulWidget {
  const PatientDashboard({super.key});

  @override
  ConsumerState<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends ConsumerState<PatientDashboard> {
  late final List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _views = [
      const PatientAppointmentsView(), // 0
      const PatientTimelineView(),     // 1
      const PatientHomeView(),         // 2 - Inicio en el centro
      const PatientMapView(),          // 3 - Clínicas
      const AiScannerView(),           // 4 - IA
    ];
  }

  Widget _buildBody(int currentIndex) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _views[currentIndex],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final currentIndex = ref.watch(patientTabProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: profileAsync.when(
        data: (_) => _buildBody(currentIndex),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text("Error de sincronización: $err")),
      ),
      bottomNavigationBar: _buildBottomNav(currentIndex),
    );
  }

  // --- COMPONENTES DE UI ---

  Widget _buildBottomNav(int currentIndex) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))
          ]
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 10, right: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildNavItem(Icons.calendar_month_outlined, "Citas", 0, currentIndex),
              _buildNavItem(Icons.monitor_heart_outlined, "Evolución", 1, currentIndex),
              _buildCenterNavItem(Icons.home_rounded, "Inicio", 2, currentIndex), // 🚀 Centralizado
              _buildNavItem(Icons.map_outlined, "Clínicas", 3, currentIndex),
              _buildNavItem(Icons.document_scanner_outlined, "IA", 4, currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, int currentIndex) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(patientTabProvider.notifier).state = index,
      child: SizedBox(
        width: 64, // Incrementado para ajuste espacioso de 5 botones
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(bottom: isSelected ? 4.0 : 0.0),
              child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: isSelected ? 26 : 22
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10, // Aumentado a 10 para mejor legibilidad
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavItem(IconData icon, String label, int index, int currentIndex) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(patientTabProvider.notifier).state = index,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14), // Espaciado premium para el botón de marca central
            decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  if (isSelected)
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))
                ]
            ),
            child: Icon(
                icon,
                color: Colors.white,
                size: 26
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}