import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import 'patient_clinical_detail_screen.dart'; // 🚀 IMPORTAMOS EL EXPEDIENTE
import 'telemedicine_room_screen.dart';

// ============================================================================
// 🚀 CAPA DE DATOS (PROVIDERS & CONTROLLERS)
// ============================================================================

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// 🚀 FIX: Actualizado con las columnas reales (appointment_date, etc.)
final dailyAppointmentsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final selectedDate = ref.watch(selectedDateProvider);
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return [];

  final startOfDay = selectedDate.toIso8601String();
  final endOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59).toIso8601String();

  final response = await supabase
      .from('appointments')
      .select('*, patient:profiles!patient_id(full_name)')
      .eq('doctor_id', user.id)
      .eq('status', 'scheduled') // Solo citas activas
      .gte('appointment_date', startOfDay) // 🛠️ FIX
      .lte('appointment_date', endOfDay)   // 🛠️ FIX
      .order('appointment_date', ascending: true);

  return List<Map<String, dynamic>>.from(response);
});

// 🌟 NUEVO: El controlador que le abre la puerta al paciente
class AgendaController {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> openVirtualRoom(String appointmentId) async {
    try {
      // Al poner esto en true, el celular del paciente reacciona en tiempo real
      await supabase
          .from('appointments')
          .update({'doctor_in_room': true})
          .eq('id', appointmentId);
    } catch (e) {
      throw Exception("Error al abrir la sala: $e");
    }
  }
}

final agendaControllerProvider = Provider((ref) => AgendaController());

// ============================================================================
// 📱 CAPA DE PRESENTACIÓN (UI)
// ============================================================================

class DoctorAgendaView extends ConsumerWidget {
  const DoctorAgendaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final appointmentsAsync = ref.watch(dailyAppointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            expandedHeight: 80,
            floating: true,
            backgroundColor: AppColors.backgroundLight,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              title: Text("Mi Agenda",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18)),
            ),
          ),

          // SELECTOR DE FECHA HORIZONTAL
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: 30,
                  itemBuilder: (context, index) {
                    final date = DateTime.now().add(Duration(days: index));
                    final normalizedDate = DateTime(date.year, date.month, date.day);
                    final isSelected = normalizedDate.isAtSameMomentAs(selectedDate);

                    return GestureDetector(
                      onTap: () {
                        ref.read(selectedDateProvider.notifier).state = normalizedDate;
                      },
                      child: Container(
                        width: 70,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? AppColors.primary : Colors.black.withValues(alpha: 0.05)),
                          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_getDayName(date.weekday), style: TextStyle(color: isSelected ? Colors.white70 : AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 5),
                            Text(date.day.toString(), style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // LISTADO DE CITAS DESDE SUPABASE
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: appointmentsAsync.when(
              data: (appointments) {
                if (appointments.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50.0),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.event_busy, size: 60, color: AppColors.textSecondary),
                            const SizedBox(height: 15),
                            const Text("Día libre", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const Text("No tienes citas agendadas para esta fecha.", style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final apt = appointments[index];

                      return _appointmentTile(context, ref, apt);
                    },
                    childCount: appointments.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                )),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: Center(child: Text("Error al cargar agenda: $err", style: const TextStyle(color: AppColors.danger))),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBlockHourBottomSheet(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showBlockHourBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _BlockHourBottomSheet();
      },
    );
  }

  void _showUnlockDialog(BuildContext context, WidgetRef ref, String appointmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Desbloquear Horario", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("¿Estás seguro de que deseas eliminar este bloqueo administrativo y liberar el horario?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client
                    .from('appointments')
                    .delete()
                    .eq('id', appointmentId);
                
                ref.invalidate(dailyAppointmentsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Horario desbloqueado correctamente."),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error al desbloquear: $e"),
                    backgroundColor: AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Desbloquear", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- WIDGET DE LA CITA REFACTORIZADO ---
  Widget _appointmentTile(BuildContext context, WidgetRef ref, Map<String, dynamic> apt) {
    // 🚀 FIX: Variables corregidas según BD
    final DateTime aptDate = DateTime.parse(apt['appointment_date']).toLocal();
    final String timeFormatted = DateFormat('hh:mm a').format(aptDate);
    final patientName = apt['patient']?['full_name'] ?? 'Paciente Desconocido';
    final bool isTelemedicine = apt['type'] == 'telemedicine';
    final reason = apt['reason'] ?? 'Consulta general';
    final patientId = apt['patient_id'];
    final appointmentId = apt['id'];
    final bool isRoomOpen = apt['doctor_in_room'] ?? false; // 🌟 Saber si ya abrió la sala
    final String? currentDoctorId = Supabase.instance.client.auth.currentUser?.id;
    final bool isBlocked = patientId == currentDoctorId;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
          color: isBlocked ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isBlocked
                ? Colors.grey.shade200
                : (isRoomOpen ? AppColors.success.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.05)),
            width: isRoomOpen && !isBlocked ? 2 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isBlocked
              ? () => _showUnlockDialog(context, ref, appointmentId)
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientClinicalDetailScreen(
                          patientId: patientId,
                          appointmentId: appointmentId
                      ),
                    ),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 1. INFO DE LA CITA
                Row(
                  children: [
                    Column(
                      children: [
                        Text(timeFormatted, style: TextStyle(fontWeight: FontWeight.bold, color: isBlocked ? AppColors.textSecondary : AppColors.textPrimary)),
                        const SizedBox(height: 5),
                        Icon(
                          isBlocked
                              ? Icons.block
                              : (isTelemedicine ? Icons.videocam_outlined : Icons.location_on_outlined),
                          color: isBlocked
                              ? Colors.grey
                              : (isTelemedicine ? AppColors.secondary : AppColors.primary),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Container(width: 1, height: 40, color: Colors.black12),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBlocked ? "Bloqueo Administrativo" : patientName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isBlocked ? AppColors.textSecondary : AppColors.textPrimary,
                            ),
                          ),
                          Text(reason, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isBlocked
                            ? Colors.grey.shade200
                            : (isTelemedicine ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isBlocked ? "Bloqueo" : (isTelemedicine ? "Video" : "Clínica"),
                        style: TextStyle(
                          color: isBlocked ? Colors.grey.shade700 : (isTelemedicine ? AppColors.secondary : AppColors.primary),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // 2. 🚀 BOTÓN MÁGICO DE VIDEOLLAMADA (Si es telemedicina)
                if (isTelemedicine && !isBlocked) ...[
                  const Divider(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!isRoomOpen) {
                          // Disparamos el update en Supabase
                          await ref.read(agendaControllerProvider).openVirtualRoom(appointmentId);
                          // Forzamos la actualización de la lista
                          ref.invalidate(dailyAppointmentsProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Sala virtual abierta. El paciente ya puede entrar."), backgroundColor: AppColors.success)
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TelemedicineRoomScreen(
                                patientId: patientId,
                                patientName: patientName,
                                appointmentId: appointmentId,
                                isDoctor: true,
                              ),
                            ),
                          );
                        }
                      },
                      icon: Icon(isRoomOpen ? Icons.video_call : Icons.sensor_door_outlined, color: Colors.white),
                      label: Text(
                          isRoomOpen ? "Entrar a Videollamada" : "Abrir Sala Virtual",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRoomOpen ? AppColors.success : AppColors.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
    return days[weekday - 1];
  }
}

class _BlockHourBottomSheet extends ConsumerStatefulWidget {
  const _BlockHourBottomSheet();

  @override
  ConsumerState<_BlockHourBottomSheet> createState() => _BlockHourBottomSheetState();
}

class _BlockHourBottomSheetState extends ConsumerState<_BlockHourBottomSheet> {
  final _reasonController = TextEditingController();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Indicador de arrastre
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Bloquear Horario",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Se reservará este espacio para actividades administrativas. Los pacientes no podrán agendar citas en esta hora.",
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Selector de fecha (deshabilitado, muestra la fecha actual de la agenda)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Fecha Seleccionada", style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Selector de Hora interactivo
            InkWell(
              onTap: () => _selectTime(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Hora de Inicio", style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          Text(
                            _selectedTime.format(context),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Campo de texto de Motivo
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _reasonController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.edit_note, color: AppColors.primary),
                  labelText: "Motivo del Bloqueo",
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Botón de Guardar
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                final reason = _reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Por favor ingresa un motivo para el bloqueo."),
                      backgroundColor: AppColors.danger,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                setState(() => _isLoading = true);

                try {
                  final supabase = Supabase.instance.client;
                  final user = supabase.auth.currentUser;
                  if (user == null) return;

                  // Crear el DateTime correspondiente a la fecha y hora seleccionada
                  final blockDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  );

                  await supabase.from('appointments').insert({
                    'patient_id': user.id, // El médico como su propio paciente
                    'doctor_id': user.id,  // Para asociarlo a su agenda
                    'appointment_date': blockDateTime.toUtc().toIso8601String(),
                    'type': 'in_person',  // Valor compatible con la base de datos
                    'reason': "Bloqueo: $reason",
                    'status': 'scheduled',
                  });

                  ref.invalidate(dailyAppointmentsProvider);

                  if (!context.mounted) return;
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Horario bloqueado con éxito."),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error al bloquear: $e"),
                      backgroundColor: AppColors.danger,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Bloquear Horario", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}