import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import 'admin_providers.dart';
import 'admin_article_management_view.dart';
import 'admin_clinic_management_view.dart';
import 'quizzes_admin_screen.dart';
import 'admin_doctor_approval_screen.dart';
import 'admin_users_view.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(adminMetricsProvider);
          ref.invalidate(pendingDoctorsProvider);
          ref.invalidate(recentScansProvider);
          await Future.delayed(const Duration(seconds: 1));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(context, ref),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📊 Sección de Métricas Premium
                    const Text(
                      "Métricas Globales",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildMetricsSection(context, ref),
                    const SizedBox(height: 30),

                    // 🛠️ Hub de Gestión (Grid 2x2)
                    const Text(
                      "Consola de Gestión",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildManagementGrid(context, ref),
                    const SizedBox(height: 30),

                    // 🤖 Auditoría IA (Últimos Escaneos)
                    const Text(
                      "Auditoría IA (Últimos Escaneos)",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildRecentScansSection(ref),
                    const SizedBox(height: 35),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- COMPONENTES ---

  SliverAppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Panel Administrativo",
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.normal,
            ),
          ),
          Text(
            "Centro de Mando",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: AppColors.danger, size: 22),
          onPressed: () {
            ref.read(authProvider.notifier).logout();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildMetricsSection(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminMetricsProvider);

    return metricsAsync.when(
      data: (metrics) => Row(
        children: [
          Expanded(
            child: _metricCard(
              "Pacientes",
              metrics['patients'].toString(),
              Icons.people_outline_rounded,
              AppColors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminUserListScreen(role: 'patient'),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _metricCard(
              "Médicos",
              metrics['doctors'].toString(),
              Icons.medical_services_outlined,
              AppColors.secondary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminUserListScreen(role: 'doctor'),
                ),
              ),
            ),
          ),
        ],
      ),
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementGrid(BuildContext context, WidgetRef ref) {
    final pendingDoctorsAsync = ref.watch(pendingDoctorsProvider);
    final int pendingCount = pendingDoctorsAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _managementCard(
                title: "Artículos",
                subtitle: "CMS Educativo",
                icon: Icons.article_outlined,
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminArticleManagementView()),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _managementCard(
                title: "Clínicas",
                subtitle: "Mapa y Radar",
                icon: Icons.local_hospital_outlined,
                color: AppColors.secondary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminClinicManagementView()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _managementCard(
                title: "Cuestionarios",
                subtitle: "CMS Clínico",
                icon: Icons.quiz_outlined,
                color: Colors.orangeAccent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizzesAdminScreen()),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _managementCard(
                title: "Solicitudes",
                subtitle: pendingCount > 0 ? "$pendingCount Pendientes" : "Aprobación",
                icon: Icons.assignment_turned_in_outlined,
                color: AppColors.success,
                badgeCount: pendingCount,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDoctorApprovalScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _managementCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: badgeCount > 0 ? AppColors.success : AppColors.textSecondary,
                          fontWeight: badgeCount > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentScansSection(WidgetRef ref) {
    final scansAsync = ref.watch(recentScansProvider);

    return scansAsync.when(
      data: (scans) {
        if (scans.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            ),
            child: const Center(
              child: Text(
                "No hay escaneos recientes.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: scans.map((scan) {
              final patientName = scan['profiles']?['full_name'] ?? 'Paciente';
              final date = scan['created_at'] != null
                  ? DateFormat('dd MMM, HH:mm').format(DateTime.parse(scan['created_at']).toLocal())
                  : 'Fecha desc.';
              final String rawRisk = (scan['risk_level'] ?? 'low').toString().toLowerCase().trim();
              final isRisk = rawRisk.contains('high') ||
                  rawRisk.contains('urgent') ||
                  rawRisk.contains('alto') ||
                  rawRisk.contains('urgente');

              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.document_scanner_rounded, color: AppColors.primary),
                    ),
                    title: Text(
                      patientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      "${scan['ai_diagnosis']} • $date",
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isRisk
                            ? AppColors.danger.withValues(alpha: 0.1)
                            : AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isRisk ? "ALTO RIESGO" : "NORMAL",
                        style: TextStyle(
                          color: isRisk ? AppColors.danger : AppColors.success,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (scan != scans.last)
                    const Divider(
                      height: 10,
                      indent: 60,
                    ),
                ],
              );
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Center(child: Text("Error: $e")),
    );
  }
}