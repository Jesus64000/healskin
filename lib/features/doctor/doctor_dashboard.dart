import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_provider.dart';

class DoctorDashboard extends ConsumerWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, ref),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKPIs(),
                  const SizedBox(height: 30),
                  _buildSectionTitle("Alertas Prioritarias IA", isUrgent: true),
                  const SizedBox(height: 15),
                  _buildCriticalAlerts(),
                  const SizedBox(height: 30),
                  _buildSectionTitle("Agenda de Hoy", isUrgent: false),
                  const SizedBox(height: 15),
                  _buildDailyAgenda(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Panel Médico",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            IconButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.power_settings_new, color: AppColors.danger, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIs() {
    return Row(
      children: [
        _kpiCard("Pacientes", "142", Icons.people_outline, AppColors.secondary),
        const SizedBox(width: 15),
        _kpiCard("Consultas Hoy", "8", Icons.videocam_outlined, AppColors.primary),
      ],
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {required bool isUrgent}) {
    return Row(
      children: [
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        if (isUrgent) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Text("URGENTE", style: TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.bold)),
          )
        ]
      ],
    );
  }

  Widget _buildCriticalAlerts() {
    return _alertCard("Mariana Sandrea", "Sospecha de Lesión Premaligna (87%)", "Revisión Inmediata");
  }

  Widget _alertCard(String patientName, String aiDiagnosis, String action) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patientName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(aiDiagnosis, style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: AppColors.danger, size: 14)
        ],
      ),
    );
  }

  Widget _buildDailyAgenda() {
    return Column(
      children: [
        _agendaItem("10:30 AM", "Carlos Pérez", "Control de Acné cosmético"),
        const SizedBox(height: 12),
        _agendaItem("02:00 PM", "Lucía Gómez", "Revisión Dermatitis Atópica"),
      ],
    );
  }

  Widget _agendaItem(String time, String patient, String reason) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Text(time, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 16),
          Container(width: 1, height: 40, color: Colors.black.withValues(alpha: 0.05)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                Text(reason, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.videocam_outlined, color: AppColors.secondary),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 20,
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Panel"),
        BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: "Pacientes"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: "Agenda"),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Ajustes"),
      ],
    );
  }
}