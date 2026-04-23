import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/auth_provider.dart';
import '../../auth/profile_provider.dart'; // Importamos el nuevo provider

class PatientProfileView extends ConsumerWidget {
  const PatientProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos los datos del perfil
    final profileAsync = ref.watch(userProfileProvider);
    final authState = ref.watch(authProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 80,
          floating: true,
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          flexibleSpace: const FlexibleSpaceBar(
            titlePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            title: Text(
                "Tu Perfil",
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18)
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.power_settings_new, color: AppColors.danger),
              onPressed: () => ref.read(authProvider.notifier).logout(),
            )
          ],
        ),

        SliverToBoxAdapter(
          child: profileAsync.when(
            // 1. ESTADO: DATOS CARGADOS
            data: (profile) {
              final String name = profile?['full_name'] ?? "Usuario";
              final String email = authState.session?.user.email ?? "Sin correo";

              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, size: 60, color: AppColors.primary)
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                        name, // NOMBRE REAL DE SUPABASE
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)
                    ),
                    Text(
                        email, // EMAIL REAL DE SUPABASE
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)
                    ),
                    const SizedBox(height: 40),

                    _buildSettingsTile(
                        Icons.medical_information_outlined,
                        "Historial Médico",
                        "Piel: ${profile?['skin_type'] ?? 'No definido'}", // MOSTRAR TIPO DE PIEL
                        AppColors.primary
                    ),
                    _buildSettingsTile(
                        Icons.shield_moon_outlined,
                        "Privacidad",
                        "Datos y consentimiento",
                        AppColors.secondary
                    ),
                    _buildSettingsTile(
                        Icons.notifications_none_rounded,
                        "Notificaciones",
                        "Alertas de IA y citas",
                        AppColors.warning
                    ),
                    _buildSettingsTile(
                        Icons.help_outline_rounded,
                        "Ayuda y Soporte",
                        "Preguntas frecuentes",
                        AppColors.success
                    ),

                    const SizedBox(height: 20),
                    const Text(
                        "HealSkin v1.0.26",
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 10)
                    ),
                  ],
                ),
              );
            },
            // 2. ESTADO: CARGANDO
            loading: () => const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            // 3. ESTADO: ERROR
            error: (err, stack) => Center(child: Text("Error al cargar perfil: $err")),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
            ]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      title,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                  Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 14),
          ],
        ),
      ),
    );
  }
}