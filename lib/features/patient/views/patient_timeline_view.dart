import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/profile_provider.dart';
import '../../ai_scanner/views/patient_ai_chat_screen.dart'; // 🚀 NUEVO IMPORT PARA EL CHAT DIRECTO
import '../patient_dashboard.dart';
import 'skin_comparator_view.dart';
import 'patient_appointments_view.dart';
import '../../../core/utils/image_utils.dart';

class PatientTimelineView extends ConsumerWidget {
  const PatientTimelineView({super.key});

  // Analizador Clínico Inteligente de Evolución Dérmica de HealSkin
  Map<String, dynamic> _analyzeEvolution(Map<String, dynamic> current, Map<String, dynamic> previous) {
    final curTitle = (current['title'] ?? '').toString().toLowerCase();
    final prevTitle = (previous['title'] ?? '').toString().toLowerCase();
    
    final bool curWarning = current['event_type'] == 'warning';
    final bool prevWarning = previous['event_type'] == 'warning';

    String status = "Estable";
    String message = "No se detectan cambios drásticos en tus patrones dérmicos. Mantén tu rutina de skincare y protección habitual.";
    Color color = AppColors.success;
    IconData icon = Icons.trending_flat_rounded;
    bool urgent = false;

    if (curWarning && !prevWarning) {
      status = "Desmejora Significativa";
      message = "Se ha detectado un incremento notable en la inflamación, irritación o riesgo dérmico en comparación con tu escaneo anterior. Es un cambio importante.";
      color = AppColors.danger;
      icon = Icons.trending_down_rounded;
      urgent = true;
    } else if (!curWarning && prevWarning) {
      status = "Mejora Notable";
      message = "¡Excelente progreso! Se observa una reducción significativa de la sintomatología de riesgo y el eritema cutáneo con respecto al último escaneo.";
      color = AppColors.success;
      icon = Icons.trending_up_rounded;
    } else if (curWarning && prevWarning) {
      status = "Persistente (Alerta)";
      message = "Tu piel continúa mostrando signos de irritación o riesgo alto de forma persistente. Te sugerimos firmemente acudir al dermatólogo.";
      color = AppColors.warning;
      icon = Icons.warning_rounded;
      urgent = true;
    } else {
      // Ambas son de bajo riesgo (info/success)
      if (curTitle != prevTitle) {
        status = "Variaciones Leves";
        message = "Se aprecian ligeras fluctuaciones en los patrones clínicos superficiales. Continúa con tu hidratación y fotoprotección diaria.";
        color = AppColors.secondary;
        icon = Icons.swap_horizontal_circle_outlined;
      } else {
        status = "Estable";
        message = "Tu barrera cutánea se mantiene en condiciones estables y equilibradas. Sigue cuidándola con el dermotip recomendado.";
        color = AppColors.success;
        icon = Icons.check_circle_outline_rounded;
      }
    }

    return {
      'status': status,
      'message': message,
      'color': color,
      'icon': icon,
      'urgent': urgent,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(skinTimelineProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(skinTimelineProvider);
          await Future.delayed(const Duration(seconds: 1));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverAppBar(
              floating: true,
              backgroundColor: AppColors.backgroundLight,
              elevation: 0,
              centerTitle: true,
              title: Text(
                  "Tu Evolución",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18)
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: timelineAsync.when(
                  data: (events) {
                    if (events.isEmpty) {
                      return _buildEmptyState(context, ref);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- PANEL DE MONITOREO INTELIGENTE DE EVOLUCIÓN ---
                        if (events.length >= 2) ...[
                          _buildEvolutionMonitoringPanel(context, ref, events),
                          const SizedBox(height: 20),
                          _buildComparatorBanner(context, events),
                          const SizedBox(height: 25),
                        ],
                        
                        // --- ENCABEZADO DE HISTORIAL ---
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 15),
                          child: Text(
                            "Historial Clínico",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                          ),
                        ),

                        ...List.generate(events.length, (index) {
                          final event = events[index];
                          final isLast = index == events.length - 1;

                          String dateLabel = "Fecha desconocida";
                          if (event['created_at'] != null) {
                            final DateTime utcDate = DateTime.parse(event['created_at']);
                            final DateTime localDate = utcDate.toLocal();
                            dateLabel = DateFormat('dd MMM, yyyy - hh:mm a', 'es').format(localDate);
                          }

                          return _buildTimelineItem(
                            context: context,
                            ref: ref,
                            date: dateLabel,
                            title: event['title'] ?? 'Análisis Guardado',
                            desc: event['description'] ?? 'Sin detalles adicionales.',
                            imageUrl: event['image_url'],
                            isSuccess: event['event_type'] == 'success' || event['event_type'] == 'info',
                            isWarning: event['event_type'] == 'warning',
                            isLast: isLast,
                          );
                        })
                      ],
                    );
                  },
                  loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 50.0),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                  ),
                  error: (err, stack) => Center(child: Text("Error al cargar evolución: $err")),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- COMPONENTES ---

  Widget _buildEvolutionMonitoringPanel(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> events) {
    final analysis = _analyzeEvolution(events[0], events[1]);
    final Color statusColor = analysis['color'];
    final IconData statusIcon = analysis['icon'];
    final bool isUrgent = analysis['urgent'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del Panel
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Monitoreo Inteligente",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        analysis['status'],
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Mensaje de la IA
          Text(
            analysis['message'],
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.45),
          ),
          
          // Alerta Clínica y Botón de Derivación Médica
          if (isUrgent) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Cambio clínico detectado. Se aconseja descartar complicaciones cutáneas.",
                          style: TextStyle(color: AppColors.danger.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Cambiamos a la pestaña de Citas (Index 0) reactiva 🚀
                        ref.read(patientTabProvider.notifier).state = 0;
                      },
                      icon: const Icon(Icons.calendar_month, color: Colors.white, size: 14),
                      label: const Text("Agendar Cita Médica", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: AppColors.secondary.withValues(alpha: 0.3)),
          const SizedBox(height: 20),
          const Text(
            "Tu historial está vacío",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          const Text(
            "Realiza tu primer escaneo con IA para\nempezar a monitorear tu piel.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => ref.read(patientTabProvider.notifier).state = 4, // Cambiar a pestaña de IA (Index 4) 🚀
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            label: const Text("Escanear ahora", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required WidgetRef ref,
    required String date,
    required String title,
    required String desc,
    String? imageUrl,
    bool isSuccess = false,
    bool isWarning = false,
    bool isLast = false,
  }) {
    Color itemColor = AppColors.primary;
    IconData itemIcon = Icons.radio_button_checked;

    if (isWarning) {
      itemColor = AppColors.warning;
      itemIcon = Icons.error_rounded;
    } else if (isSuccess) {
      itemColor = AppColors.success;
      itemIcon = Icons.check_circle_rounded;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Icon(itemIcon, color: itemColor, size: 24),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.only(top: 4),
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
                ),
            ],
          ),
          const SizedBox(width: 15),

          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 25),
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
                  Text(
                      date,
                      style: const TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                  ),
                  const SizedBox(height: 6),
                  Text(
                      title,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 6),
                  _buildRichDescription(desc),
                  if (imageUrl != null && imageUrl.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: () => showFullScreenImage(context, imageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 150,
                              color: AppColors.surfaceLight,
                              child: const Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 100,
                            color: Colors.grey.shade200,
                            child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  // 💬 BOTÓN CONDICIONAL SEGÚN EL TIPO DE HITO (NUEVO)
                  if (title.startsWith("Diagnóstico Médico:")) ...[
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Cambiamos a la pestaña de Citas (Index 0) reactiva 🚀
                          ref.read(patientTabProvider.notifier).state = 0;
                          // Cambiamos a la sub-pestaña "Indicaciones" (Index 2) 🚀
                          ref.read(citasSubTabProvider.notifier).state = 2;
                        },
                        icon: const Icon(Icons.assignment_outlined, size: 16, color: Colors.white),
                        label: const Text(
                          "Ver tratamiento y receta",
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ] else ...[
                    // 💬 BOTÓN PARA ABRIR EL CHAT DE IA DIRECTO DEL ESCANEO CON DATOS DEL HISTORIAL
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Limpiamos y traducimos descripciones y riesgos
                          String cleanTitle = title.replaceAll('Análisis IA: ', '').trim();
                          
                          // Extraemos risk_level de los metadatos si existe
                          String extractedRisk = isWarning ? 'high' : 'low';
                          final regExp = RegExp(r'\[risk_level:\s*([a-zA-Z]+)\]');
                          final match = regExp.firstMatch(desc);
                          if (match != null) {
                            extractedRisk = match.group(1) ?? extractedRisk;
                          }

                          // Limpiamos los metadatos de la recomendación
                          final cleanDesc = desc.replaceAll(RegExp(r'\n\n\[risk_level:\s*[a-zA-Z]+\]'), '').trim();

                          final Map<String, dynamic> scanData = {
                            'ai_diagnosis': cleanTitle,
                            'risk_level': extractedRisk,
                            'image_url': imageUrl,
                            'recommendation': cleanDesc,
                            'is_from_history': true,
                          };
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PatientAIChatScreen(scanData: scanData),
                            ),
                          );
                        },
                        icon: const Icon(Icons.forum_outlined, size: 16, color: AppColors.primary),
                        label: const Text(
                          "Consultar a la IA sobre este escaneo",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.04),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRichDescription(String desc) {
    // Limpiamos los metadatos de risk_level para que no aparezcan en la interfaz
    final cleanDesc = desc.replaceAll(RegExp(r'\n\n\[risk_level:\s*[a-zA-Z]+\]'), '').trim();
    if (cleanDesc.contains("🛡️") || cleanDesc.contains("🔬")) {
      final cleanText = cleanDesc.replaceAll("**", "");
      return Text(
        cleanText,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.5,
        ),
      );
    }
    return Text(
      cleanDesc,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        height: 1.4,
      ),
    );
  }

  Widget _buildComparatorBanner(BuildContext context, List<Map<String, dynamic>> events) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "✨ Comparador de Evolución",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Visualiza interactivamente los cambios en tu piel deslizando tus fotos históricas.",
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SkinComparatorSelectionScreen(
                          items: events,
                          title: "Comparar mi Evolución",
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text("Comparar Fotos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                )
              ],
            ),
          ),
          const SizedBox(width: 15),
          const Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 45),
        ],
      ),
    );
  }
}