import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🚀 IMPORT CRÍTICO: Asegúrate de que esta ruta apunte a donde tienes tu userProfileProvider
import '../auth/profile_provider.dart';

import 'views/patient_home_view.dart';
import 'views/patient_timeline_view.dart';
import 'views/patient_appointments_view.dart';
import 'views/patient_map_view.dart'; // 🚀 NUEVO IMPORT: Clínicas
import 'views/patient_procedures_provider.dart';
import 'views/patient_appointments_provider.dart';
import 'views/doctor_detail_screen.dart';
import '../ai_scanner/views/ai_scanner_view.dart';
import '../chat/chat_notification_listener.dart';
import '../chat/chat_view.dart';

// Provider global para controlar reactivamente la pestaña activa del dashboard (2 es Inicio por defecto)
final patientTabProvider = StateProvider<int>((ref) => 2);

class PatientDashboard extends ConsumerStatefulWidget {
  const PatientDashboard({super.key});

  @override
  ConsumerState<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends ConsumerState<PatientDashboard> {
  late final List<Widget> _views;
  StreamSubscription? _notificationSubscription;
  final Set<String> _scheduledProcedures = {};

  @override
  void initState() {
    super.initState();
    _views = [
      const PatientAppointmentsView(), // 0
      const PatientTimelineView(),     // 1
      const PatientHomeView(),         // 2 - Inicio en el centro
      const PatientMapView(),          // 3 - Clínicas
      const AiScannerView(),           // 4 - IA
    ];

    // Iniciar escucha de chat en tiempo real para el paciente
    ChatNotificationListener().startListening();

    // Escuchar notificaciones clickeadas
    _notificationSubscription = NotificationService.selectNotificationStream.stream.listen((payload) {
      if (payload != null) {
        if (payload.startsWith('filter_map:')) {
          final query = payload.substring('filter_map:'.length);
          ref.read(patientTabProvider.notifier).state = 3; // Ir a Clínicas (Mapa)
          ref.read(mapSearchQueryProvider.notifier).state = query; // Aplicar filtro de búsqueda
        } else if (payload.startsWith('chat:')) {
          final parts = payload.substring('chat:'.length).split('|');
          final otherUserId = parts[0];
          final otherUserName = parts.length > 1 ? parts[1] : 'Especialista';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatView(
                otherUserId: otherUserId,
                otherUserName: otherUserName,
              ),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    ChatNotificationListener().stopListening();
    super.dispose();
  }

  Widget _buildBody(int currentIndex) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _views[currentIndex],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final currentIndex = ref.watch(patientTabProvider);

    // Programar/Cancelar recordatorios reactivamente
    ref.listen<AsyncValue<List<Map<String, dynamic>>>>(patientProceduresProvider, (previous, next) {
      next.whenData((procedures) {
        final activeIds = procedures.where((p) => p['status'] == 'active').map((p) => p['id'] as String).toSet();
        
        // Cancelar recordatorios que ya no están activos
        final toCancel = _scheduledProcedures.difference(activeIds);
        for (final id in toCancel) {
          _scheduledProcedures.remove(id);
          NotificationService().cancelProcedureReminder(id);
        }

        // Programar recordatorios para procedimientos activos nuevos
        for (final proc in procedures) {
          final id = proc['id'];
          if (proc['status'] == 'active' && !_scheduledProcedures.contains(id)) {
            _scheduledProcedures.add(id);
            NotificationService().scheduleProcedureReminder(
              procedureId: id,
              procedureName: proc['procedure_name'] ?? 'Tratamiento',
              frequencyDays: proc['frequency_days'] ?? 7,
            );
          }
        }
      });
    });

    // Escuchar citas canceladas administrativamente para notificar disculpas
    ref.listen<AsyncValue<List<Map<String, dynamic>>>>(myAppointmentsProvider, (previous, next) {
      next.whenData((appointments) {
        _checkAndShowApologyDialog(appointments);
      });
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: profileAsync.when(
        data: (_) => _buildBody(currentIndex),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text("Error de sincronización: $err")),
      ),
      bottomNavigationBar: _buildBottomNav(currentIndex),
    );
  }

  Future<void> _checkAndShowApologyDialog(List<Map<String, dynamic>> appointments) async {
    final prefs = await SharedPreferences.getInstance();
    final notifiedIds = prefs.getStringList('notified_cancelled_appointments') ?? [];

    for (final apt in appointments) {
      final status = apt['status'];
      final id = apt['id']?.toString();
      final reason = apt['reason']?.toString() ?? '';

      if (status == 'cancelled' && 
          id != null && 
          reason.startsWith('Cancelada por bloqueo administrativo:') && 
          !notifiedIds.contains(id)) {
        
        notifiedIds.add(id);
        await prefs.setStringList('notified_cancelled_appointments', notifiedIds);

        if (!mounted) return;
        _showCancellationApologyDialog(apt);
        break; // Mostramos uno por uno
      }
    }
  }

  String _formatAptDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd/MM/yyyy hh:mm a').format(date);
    } catch (_) {
      return dateStr.toString();
    }
  }

  void _showCancellationApologyDialog(Map<String, dynamic> apt) {
    final doctor = apt['doctor'];
    final doctorName = doctor?['full_name'] ?? 'tu médico';
    final doctorId = apt['doctor_id'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 28),
              SizedBox(width: 8),
              Text(
                "Cita Cancelada",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Lamentamos informarle que su cita con $doctorName programada para el ${_formatAptDate(apt['appointment_date'])} ha sido cancelada debido a un bloqueo de agenda administrativa del médico.",
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                "Le ofrecemos nuestras más sinceras disculpas por los inconvenientes causados. Puede reagendar su cita con el médico en cualquier otro horario disponible.",
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar", style: TextStyle(color: AppColors.textSecondary)),
            ),
            if (doctorId != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorDetailScreen(doctorId: doctorId),
                    ),
                  );
                },
                child: const Text("Reagendar"),
              ),
          ],
        );
      },
    );
  }

  // --- COMPONENTES DE UI ---

  Widget _buildBottomNav(int currentIndex) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))
          ]
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 10, right: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildNavItem(Icons.calendar_month_outlined, "Citas", 0, currentIndex),
              _buildNavItem(Icons.monitor_heart_outlined, "Evolución", 1, currentIndex),
              _buildCenterNavItem(Icons.home_rounded, "Inicio", 2, currentIndex), // 🚀 Centralizado
              _buildNavItem(Icons.map_outlined, "Clínicas", 3, currentIndex),
              _buildNavItem(Icons.document_scanner_outlined, "IA", 4, currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, int currentIndex) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(patientTabProvider.notifier).state = index,
      child: SizedBox(
        width: 64, // Incrementado para ajuste espacioso de 5 botones
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(bottom: isSelected ? 4.0 : 0.0),
              child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: isSelected ? 26 : 22
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10, // Aumentado a 10 para mejor legibilidad
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavItem(IconData icon, String label, int index, int currentIndex) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(patientTabProvider.notifier).state = index,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14), // Espaciado premium para el botón de marca central
            decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  if (isSelected)
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))
                ]
            ),
            child: Icon(
                icon,
                color: Colors.white,
                size: 26
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}