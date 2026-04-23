import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PatientTimelineView extends StatelessWidget {
  const PatientTimelineView({super.key});

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
                "Tu Evolución",
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18)
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimelineItem(
                  date: "Hoy",
                  title: "Mejora detectada",
                  desc: "La IA detecta una reducción del 15% en la inflamación de la zona T.",
                  isSuccess: true,
                ),
                _buildTimelineItem(
                  date: "Hace 1 semana",
                  title: "Alerta Leve",
                  desc: "Brote de acné detectado en la mejilla derecha. Se recomienda limpieza profunda.",
                  isWarning: true,
                ),
                _buildTimelineItem(
                  date: "Hace 1 mes",
                  title: "Escaneo Inicial",
                  desc: "Registro base del estado de la piel completado satisfactoriamente.",
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String date,
    required String title,
    required String desc,
    bool isSuccess = false,
    bool isWarning = false
  }) {
    Color itemColor = AppColors.textSecondary;
    IconData itemIcon = Icons.radio_button_checked;

    if (isSuccess) {
      itemColor = AppColors.success;
      itemIcon = Icons.check_circle_rounded;
    } else if (isWarning) {
      itemColor = AppColors.warning;
      itemIcon = Icons.error_rounded;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna de la línea (Indicador visual)
        Column(
          children: [
            Icon(itemIcon, color: itemColor, size: 22),
            Container(
              width: 2,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [itemColor.withOpacity(0.5), AppColors.secondary.withOpacity(0.1)],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 15),
        // Tarjeta de información
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4)
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    date,
                    style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5
                    )
                ),
                const SizedBox(height: 6),
                Text(
                    title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold
                    )
                ),
                const SizedBox(height: 6),
                Text(
                    desc,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4
                    )
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}