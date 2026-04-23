import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PatientMapView extends StatelessWidget {
  const PatientMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header Luminoso
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

        // Contenido Principal
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

                // Lista de Centros (Adaptada al nuevo diseño)
                _buildCenterTile("Clínica Dermatológica Zulia", "Av. Universidad", "Abierto", true),
                _buildCenterTile("Centro Estético HealSkin", "Centro Cívico Cabimas", "Cierra a las 5pm", false),
                _buildCenterTile("Dermatología Especializada COL", "Carretera H", "Abierto", true),

                const SizedBox(height: 40), // Espacio extra para el scroll de la barra inferior
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 1. Placeholder del Mapa
  Widget _buildMapPlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight, // Gris ultra claro
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1), // Salmón muy suave
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

  // 2. Tarjeta del Centro Médico
  Widget _buildCenterTile(String name, String location, String status, bool isOpen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white, // Blanco puro
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
          ]
      ),
      child: Row(
        children: [
          // Icono de ubicación
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.15), // Lavanda suave
                borderRadius: BorderRadius.circular(12)
            ),
            child: const Icon(Icons.location_on, color: AppColors.secondary),
          ),
          const SizedBox(width: 15),

          // Información del centro
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    name,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)
                ),
                const SizedBox(height: 4),
                Text(
                    location,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)
                ),
              ],
            ),
          ),

          // Estado (Abierto/Cerrado)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: isOpen ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
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