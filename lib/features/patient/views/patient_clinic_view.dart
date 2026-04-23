import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/profile_provider.dart'; // Importamos el provider

class PatientClinicView extends ConsumerWidget {
  const PatientClinicView({super.key});

  // Función auxiliar para mapear el string del icono a un IconData real
  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'person_3': return Icons.person_3;
      case 'person_4': return Icons.person_4;
      case 'person_2': return Icons.person_2;
      default: return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(doctorsListProvider);

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
                "Red de Guardianes de la Piel",
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18)
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPriorityBanner(),
                const SizedBox(height: 30),

                // LÓGICA DINÁMICA DE SUPABASE
                doctorsAsync.when(
                  data: (doctors) => Column(
                    children: doctors.map((doc) => _buildDoctorTile(
                        doc['full_name'],
                        doc['availability'] ?? 'No disponible',
                        _getIconData(doc['avatar_type'])
                    )).toList(),
                  ),
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary)
                  ),
                  error: (err, stack) => Center(
                      child: Text("Error al cargar médicos: $err")
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Los widgets _buildPriorityBanner y _buildDoctorTile se quedan IGUAL
  // (Solo recuerda cambiar .withOpacity a .withValues para evitar warnings)

  Widget _buildPriorityBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tu salud, es", style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
                Text("Nuestra Prioridad", style: TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 10)]
            ),
            child: const Icon(Icons.favorite, color: AppColors.primary, size: 30),
          )
        ],
      ),
    );
  }

  Widget _buildDoctorTile(String name, String schedule, IconData avatarIcon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
          ]
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(avatarIcon, color: AppColors.textSecondary, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(schedule, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_month_outlined, color: AppColors.secondary),
          )
        ],
      ),
    );
  }
}