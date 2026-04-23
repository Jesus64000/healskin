import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener intl en pubspec.yaml
import '../../../core/theme/app_colors.dart';
import '../../auth/profile_provider.dart';

class PatientTimelineView extends ConsumerWidget {
  const PatientTimelineView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(skinTimelineProvider);

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
                "Tu Evolución",
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18)
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: timelineAsync.when(
              data: (events) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: events.map((event) {
                  // Formateo básico de fecha
                  final DateTime date = DateTime.parse(event['created_at']);
                  final String dateLabel = DateFormat('dd MMM, yyyy').format(date);

                  return _buildTimelineItem(
                    date: dateLabel,
                    title: event['title'],
                    desc: event['description'] ?? '',
                    isSuccess: event['event_type'] == 'success',
                    isWarning: event['event_type'] == 'warning',
                  );
                }).toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(child: Text("Error al cargar evolución: $err")),
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
        Column(
          children: [
            Icon(itemIcon, color: itemColor, size: 22),
            Container(
              width: 2,
              height: 100, // Ajustado para dar más espacio
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    itemColor.withValues(alpha: 0.5),
                    AppColors.secondary.withValues(alpha: 0.1)
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
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