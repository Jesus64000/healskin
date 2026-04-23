import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PatientClinicView extends StatelessWidget {
  const PatientClinicView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Nuevo Header Luminoso
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

        // Contenido Principal
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPriorityBanner(),
                const SizedBox(height: 30),

                // Lista de Médicos (Extraídos exactamente del PDF)
                _buildDoctorTile("Dr. Bailey Dupont", "Consultas: Lunes", Icons.person),
                _buildDoctorTile("Dra. Donna Stroupe", "Consultas: Viernes", Icons.person_3),
                _buildDoctorTile("Dra. Juliana Silva", "Consultas: Miércoles", Icons.person_4),
                _buildDoctorTile("Dr. Connor Hamilton", "Consultas: Jueves", Icons.person_2),

                const SizedBox(height: 40), // Espacio extra para el scroll de la barra inferior
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 1. Banner "Tu salud, es Nuestra Prioridad"
  Widget _buildPriorityBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark, // El tono durazno ultra claro
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    "Tu salud, es",
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 18)
                ),
                Text(
                  "Nuestra Prioridad",
                  style: TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Icono decorativo para el banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10)]
            ),
            child: const Icon(Icons.favorite, color: AppColors.primary, size: 30),
          )
        ],
      ),
    );
  }

  // 2. Tarjeta de Médico Estilizada
  Widget _buildDoctorTile(String name, String schedule, IconData avatarIcon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white, // Blanco puro para resaltar sobre el fondo light
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
          ]
      ),
      child: Row(
        children: [
          // Avatar del Médico
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

          // Datos del Médico
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    name,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)
                ),
                const SizedBox(height: 4),
                Text(
                    schedule,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)
                ),
              ],
            ),
          ),

          // Botón de Acción (Agendar/Chat)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1), // Lavanda muy suave
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_month_outlined, color: AppColors.secondary),
          )
        ],
      ),
    );
  }
}