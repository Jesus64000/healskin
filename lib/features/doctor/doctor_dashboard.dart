import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import '../chat/chat_notification_listener.dart';
import '../chat/chat_view.dart';
import '../chat/chat_inbox_screen.dart';

// IMPORTACIONES DE LAS 3 PESTAÑAS (Asegúrate de tener estos archivos o crearlos luego)
import 'doctor_patients_view.dart';
import 'doctor_agenda_view.dart';
import 'doctor_profile_view.dart';
import 'patient_clinical_detail_screen.dart';

// ============================================================================
// 🚀 CAPA DE DATOS (PROVIDERS)
// ============================================================================

final urgentAlertsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final doctorId = supabase.auth.currentUser?.id;

  if (doctorId == null) return [];

  // 🔒 PRIVACIDAD: Obtener solo pacientes asociados a este doctor
  final appointmentsResponse = await supabase
      .from('appointments')
      .select('patient_id')
      .eq('doctor_id', doctorId);

  final List<dynamic> appts = appointmentsResponse as List<dynamic>;
  final List<String> patientIds = appts
      .map((item) => (item['patient_id'] ?? '').toString())
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();

  if (patientIds.isEmpty) return [];

  // Traer alertas urgentes únicamente para MIS pacientes
  final response = await supabase
      .from('ai_scans')
      .select('*, profiles(full_name)')
      .inFilter('patient_id', patientIds)
      .inFilter('risk_level', ['high', 'urgent'])
      .order('created_at', ascending: false)
      .limit(5);

  return List<Map<String, dynamic>>.from(response);
});

// 🚀 REFACTOR: Conectado a la columna 'status' correcta y filtrado por doctor
final doctorKpiProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final supabase = Supabase.instance.client;
  final doctorId = supabase.auth.currentUser?.id;

  if (doctorId == null) return {'totalPatients': 0, 'consultationsToday': 0};

  // 🔒 PRIVACIDAD: Pacientes únicos con citas agendadas con este doctor (excluyendo auto-bloqueos)
  final appointmentsResponse = await supabase
      .from('appointments')
      .select('patient_id')
      .eq('doctor_id', doctorId)
      .neq('patient_id', doctorId); // 🔒 EXCLUDE AUTO-BLOCKS

  final List<dynamic> appts = appointmentsResponse as List<dynamic>;
  final uniquePatientIds = appts
      .map((item) => (item['patient_id'] ?? '').toString())
      .where((id) => id.isNotEmpty && id != doctorId)
      .toSet();

  int totalPatients = 0;
  if (uniquePatientIds.isNotEmpty) {
    try {
      final profilesRes = await supabase
          .from('profiles')
          .select('id')
          .inFilter('id', uniquePatientIds.toList());
      totalPatients = (profilesRes as List).length;
    } catch (e) {
      debugPrint("Error al verificar perfiles de pacientes en KPI: $e");
      totalPatients = uniquePatientIds.length;
    }
  }

  // Citas activas programadas PARA HOY (excluyendo auto-bloqueos)
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day).toIso8601String();
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

  final appointmentsRes = await supabase
      .from('appointments')
      .select('id')
      .eq('doctor_id', doctorId)
      .neq('patient_id', doctorId) // 🔒 EXCLUDE AUTO-BLOCKS
      .eq('status', 'scheduled')
      .gte('appointment_date', startOfToday)
      .lte('appointment_date', endOfToday);

  return {
    'totalPatients': totalPatients,
    'consultationsToday': appointmentsRes.length,
  };
});

// 🚀 REFACTOR: Conectado a 'appointment_date' y filtrado estrictamente para citas FUTURAS
final todayAgendaPreviewProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final doctorId = supabase.auth.currentUser?.id;

  if (doctorId == null) return [];

  final String nowIso = DateTime.now().toUtc().toIso8601String();

  final response = await supabase
      .from('appointments')
      .select('*, patient:profiles!patient_id(full_name)')
      .eq('doctor_id', doctorId)
      .neq('patient_id', doctorId) // 🔒 EXCLUDE AUTO-BLOCKS
      .eq('status', 'scheduled')
      .gte('appointment_date', nowIso) // Solo citas futuras o a partir de hoy!
      .order('appointment_date', ascending: true)
      .limit(3);

  return List<Map<String, dynamic>>.from(response);
});

// ============================================================================
// 📱 CAPA DE PRESENTACIÓN (UI)
// ============================================================================

final doctorTabProvider = StateProvider<int>((ref) => 0);

class DoctorDashboard extends ConsumerStatefulWidget {
  const DoctorDashboard({super.key});

  @override
  ConsumerState<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends ConsumerState<DoctorDashboard> {
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    // Iniciar escucha de chat en tiempo real para el doctor
    ChatNotificationListener().startListening();

    // Escuchar notificaciones clickeadas
    _notificationSubscription = NotificationService.selectNotificationStream.stream.listen((payload) {
      if (payload != null && payload.startsWith('chat:')) {
        final parts = payload.substring('chat:'.length).split('|');
        final otherUserId = parts[0];
        final otherUserName = parts.length > 1 ? parts[1] : 'Paciente';
        if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(doctorTabProvider);

    final List<Widget> screens = [
      const _DoctorHomeTab(),
      const DoctorPatientsView(),
      const DoctorAgendaView(),
      const DoctorProfileView(),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
        currentIndex: currentIndex,
        onTap: (index) => ref.read(doctorTabProvider.notifier).state = index,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Panel"),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: "Pacientes"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: "Agenda"),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Ajustes"),
        ],
      ),
    );
  }
}

class _DoctorHomeTab extends ConsumerWidget {
  const _DoctorHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpiAsync = ref.watch(doctorKpiProvider);
    final alertsAsync = ref.watch(urgentAlertsProvider);
    final agendaAsync = ref.watch(todayAgendaPreviewProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(doctorKpiProvider);
        ref.invalidate(urgentAlertsProvider);
        ref.invalidate(todayAgendaPreviewProvider);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.backgroundLight,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              "Panel Médico",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            actions: [
              IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                constraints: const BoxConstraints(),
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                },
                icon: const Icon(Icons.power_settings_new, color: AppColors.danger, size: 24),
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  kpiAsync.when(
                    data: (kpis) => _buildKPIs(
                      ref,
                      patientsCount: kpis['totalPatients'].toString(),
                      consultationsCount: kpis['consultationsToday'].toString(),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (err, stack) => const Text("Error al cargar KPIs", style: TextStyle(color: AppColors.danger)),
                  ),

                  const SizedBox(height: 15),
                  _buildChatCard(context),
                  const SizedBox(height: 30),
                  _buildSectionTitle("Alertas Prioritarias IA", isUrgent: true),
                                    alertsAsync.when(
                    data: (alerts) {
                      if (alerts.isEmpty) {
                        return _buildEmptyState("Todo en orden", "No hay alertas urgentes de la IA en este momento.", Icons.check_circle_outline);
                      }
                      return Column(
                        children: alerts.map((alert) {
                          final patientName = alert['profiles']?['full_name'] ?? 'Paciente Desconocido';
                          final patientId = alert['patient_id'];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _alertCard(
                              patientName: patientName,
                              aiDiagnosis: alert['ai_diagnosis'] ?? 'Análisis Pendiente',
                              action: alert['recommendation'] ?? 'Requiere revisión',
                              onTap: () {
                                if (patientId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PatientClinicalDetailScreen(
                                        patientId: patientId,
                                        appointmentId: null, // Revisión libre de IA
                                      ),
                                    ),
                                  ).then((_) {
                                     ref.invalidate(todayAgendaPreviewProvider);
                                   });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.danger)),
                    error: (err, stack) => const Text("Error al cargar alertas", style: TextStyle(color: AppColors.danger)),
                  ),

                  const SizedBox(height: 30),
                  _buildSectionTitle("Próximas Citas", isUrgent: false),
                  const SizedBox(height: 15),

                  agendaAsync.when(
                    data: (appointments) {
                      if (appointments.isEmpty) {
                        return _buildEmptyState("Agenda libre", "No tienes citas programadas próximamente.", Icons.coffee);
                      }
                      return Column(
                        children: appointments.map((appt) {
                          final patientName = appt['patient']?['full_name'] ?? 'Desconocido';
                          final reason = appt['reason'] ?? 'Consulta general';
                          final isVideo = appt['type'] == 'telemedicine';
                          final patientId = appt['patient_id'];
                          final appointmentId = appt['id'];

                          final date = DateTime.parse(appt['appointment_date']).toLocal();
                          final timeString = DateFormat('hh:mm a').format(date);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _agendaItem(
                              timeString,
                              patientName,
                              reason,
                              isVideo,
                              onTap: () {
                                if (patientId != null && appointmentId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PatientClinicalDetailScreen(
                                        patientId: patientId,
                                        appointmentId: appointmentId,
                                      ),
                                    ),
                                  ).then((_) {
                                     ref.invalidate(todayAgendaPreviewProvider);
                                   });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (err, stack) => const Text("Error al cargar agenda", style: TextStyle(color: AppColors.danger)),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatInboxScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 18),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bandeja de Consultas (Chat)",
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Responde dudas y mantén contacto con tus pacientes",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  // --- COMPONENTES ---

  Widget _buildKPIs(WidgetRef ref, {required String patientsCount, required String consultationsCount}) {
    return Row(
      children: [
        _kpiCard("Pacientes", patientsCount, Icons.people_outline, AppColors.secondary, onTap: () {
          ref.read(doctorTabProvider.notifier).state = 1;
        }),
        const SizedBox(width: 15),
        _kpiCard("Consultas", consultationsCount, Icons.videocam_outlined, AppColors.primary, onTap: () {
          ref.read(doctorTabProvider.notifier).state = 2;
        }),
      ],
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold)),
                  Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {required bool isUrgent}) {
    return Row(
      children: [
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        if (isUrgent) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Text("URGENTE", style: TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.bold)),
          )
        ]
      ],
    );
  }

  Widget _alertCard({required String patientName, required String aiDiagnosis, required String action, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.05),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patientName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(aiDiagnosis, style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(action, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: AppColors.danger, size: 14)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.success, size: 40),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _agendaItem(String time, String patient, String reason, bool isVideo, {required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Text(time, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 16),
              Container(width: 1, height: 40, color: Colors.black.withValues(alpha: 0.05)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    Text(reason, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Icon(isVideo ? Icons.videocam_outlined : Icons.business, color: isVideo ? AppColors.secondary : AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}