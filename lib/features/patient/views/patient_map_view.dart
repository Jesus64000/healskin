import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/profile_provider.dart';

class PatientMapView extends ConsumerWidget {
  const PatientMapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos la lista de centros de Supabase
    final centersAsync = ref.watch(medicalCentersProvider);

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
                "Centros en Cabimas",
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
                _buildMapPlaceholder(),
                const SizedBox(height: 30),
                const Text(
                    "Sugeridos cerca de ti",
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 15),

                // LÓGICA DINÁMICA
                centersAsync.when(
                  data: (centers) => Column(
                    children: centers.map((center) => _buildCenterTile(
                        center['name'],
                        center['address'] ?? 'Dirección no disponible',
                        center['status_text'] ?? 'Desconocido',
                        center['is_open'] ?? false
                    )).toList(),
                  ),
                  loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                  ),
                  error: (err, stack) => Center(child: Text("Error: $err")),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.map_outlined, color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 15),
          const Text(
              "Mapa interactivo en desarrollo",
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }

  Widget _buildCenterTile(String name, String location, String status, bool isOpen) {
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12)
            ),
            child: const Icon(Icons.location_on, color: AppColors.secondary),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: isOpen ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)
            ),
            child: Text(
                status,
                style: TextStyle(
                    color: isOpen ? AppColors.success : AppColors.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.bold
                )
            ),
          ),
        ],
      ),
    );
  }
}