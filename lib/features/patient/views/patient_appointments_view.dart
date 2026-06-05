import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import 'patient_appointments_provider.dart';
import 'patient_clinic_view.dart';
// 🚀 IMPORTAMOS LA PANTALLA DE VIDEOCONSULTA
import '../../../features/doctor/telemedicine_room_screen.dart';

class PatientAppointmentsView extends ConsumerWidget {
  const PatientAppointmentsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🧠 Escuchamos el StreamProvider (cambia de .watch a manejar un AsyncValue de Stream)
    final appointmentsAsync = ref.watch(myAppointmentsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          automaticallyImplyLeading: false, // Evita flechas fantasmas si viene del flujo de agendamiento
          title: const Text("Mis Citas Médicas", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Próximas"),
              Tab(text: "Historial"),
            ],
          ),
        ),
        body: appointmentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(child: Text("Error en la sala de espera: $err")),
          data: (appointments) {
            final now = DateTime.now();

            // Separamos las próximas de las pasadas o canceladas
            // Damos 2 horas de margen para que la cita no desaparezca de inmediato
            final upcoming = appointments.where((a) {
              final date = DateTime.parse(a['appointment_date']).toLocal();
              return date.isAfter(now.subtract(const Duration(hours: 2))) && a['status'] == 'scheduled';
            }).toList();

            final past = appointments.where((a) {
              final date = DateTime.parse(a['appointment_date']).toLocal();
              return date.isBefore(now.subtract(const Duration(hours: 2))) || a['status'] != 'scheduled';
            }).toList();

            return TabBarView(
              children: [
                _buildAppointmentsList(context, ref, upcoming, isPast: false),
                _buildAppointmentsList(context, ref, past, isPast: true),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PatientClinicView()));
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Nueva Cita", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> appointments, {required bool isPast}) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isPast ? Icons.history : Icons.event_busy, size: 60, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 15),
            Text(
                isPast ? "No tienes historial de consultas" : "No tienes citas programadas",
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500)
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final apt = appointments[index];
        final doctor = apt['doctor'] ?? {};
        final date = DateTime.parse(apt['appointment_date']).toLocal();
        final isVideo = apt['type'] == 'telemedicine';

        // 🚀 LA VARIABLE MÁGICA REALTIME
        final isDoctorInRoom = apt['doctor_in_room'] ?? false;

        // 🚀 VARIABLES PARA LA NAVEGACIÓN A AGORA
        final patientId = apt['patient_id'] ?? '';
        final appointmentId = apt['id'] ?? '';
        final doctorName = "Dr. ${doctor['full_name'] ?? 'Especialista'}";

        // Lógica de edición limitada a 1 hora
        final createdAtRaw = apt['created_at'];
        final DateTime? createdAt = createdAtRaw != null ? DateTime.parse(createdAtRaw).toLocal() : null;
        final bool canEdit = createdAt == null || DateTime.now().difference(createdAt).inHours < 1;

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CABECERA DE LA TARJETA
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isVideo ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(isVideo ? Icons.videocam : Icons.location_on, color: isVideo ? AppColors.secondary : AppColors.primary),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                          Text(doctor['specialty'] ?? 'Dermatología', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPast ? Colors.grey.withValues(alpha: 0.2) : (isVideo ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        isVideo ? "Videoconsulta" : "En Clínica",
                        style: TextStyle(
                            color: isPast ? Colors.grey : (isVideo ? AppColors.secondary : AppColors.primary),
                            fontSize: 11,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    )
                  ],
                ),
                const Divider(height: 30, thickness: 1),

                // FECHA Y HORA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(DateFormat('dd MMMM, yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(DateFormat('hh:mm a').format(date), style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      ],
                    ),
                  ],
                ),

                // 🚀 SECCIÓN DE ACCIONES DINÁMICAS (Solo para próximas citas)
                if (!isPast) ...[
                  const SizedBox(height: 20),
                  if (isVideo) ...[
                    // CASO A: ES VIDEOCONSULTA
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        // 🔐 SOLO SE ACTIVA SI EL DOCTOR ENTRÓ
                        onPressed: isDoctorInRoom ? () {
                          // 🚀 EL VIAJE MÁGICO A LA SALA VIRTUAL
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TelemedicineRoomScreen(
                                patientId: patientId,
                                patientName: doctorName,
                                appointmentId: appointmentId,
                                isDoctor: false, // 🔴 IMPORTANTE: Declaramos que es el Paciente
                              ),
                            ),
                          );
                        } : null,
                        icon: Icon(
                            isDoctorInRoom ? Icons.video_call : Icons.hourglass_empty,
                            color: Colors.white
                        ),
                        label: Text(
                            isDoctorInRoom ? "¡Médico en sala! Entrar Ahora" : "Esperando al médico en sala...",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDoctorInRoom ? AppColors.success : Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    )
                  ] else ...[
                    // CASO B: ES PRESENCIAL EN CLÍNICA
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showClinicDirections(context);
                        },
                        icon: const Icon(Icons.map_outlined, color: AppColors.primary),
                        label: const Text("Ver indicaciones de la Clínica", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    )
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // BOTÓN DE EDITAR
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            if (canEdit) {
                              _editAppointmentModal(context, ref, apt);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Por seguridad y disponibilidad, solo puedes editar una cita dentro de la primera hora tras agendarla."),
                                  backgroundColor: AppColors.warning,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: Icon(Icons.edit_outlined, color: canEdit ? AppColors.primary : Colors.grey, size: 16),
                          label: Text(
                            "Editar Cita",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: canEdit ? AppColors.primary : Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // BOTÓN DE CANCELAR
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _confirmCancelAppointment(context, ref, apt['id']),
                          icon: const Icon(Icons.cancel_outlined, color: AppColors.danger, size: 16),
                          label: const Text(
                            "Cancelar Cita",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  void _showClinicDirections(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_hospital, color: AppColors.primary, size: 44),
                  SizedBox(height: 12),
                  Text(
                    "Sede Central HealSkin", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text("📍 Dirección:", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text(
                "Av. Principal de la Salud, Edificio Medical Plaza, Piso 3, Consultorio 302.", 
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 15),
              const Text("📝 Notas para tu cita:", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text(
                "• Por favor llega 15 minutos antes.\n• No olvides traer tu documento de identidad.\n• Si tienes exámenes previos de la piel, llévalos.", 
                style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: const Text("Entendido", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      },
    );
  }

  void _confirmCancelAppointment(BuildContext context, WidgetRef ref, String appointmentId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 44),
              SizedBox(height: 12),
              Text(
                "¿Cancelar Cita?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "Esta acción no se puede deshacer. La disponibilidad del doctor volverá a abrirse para otros pacientes.",
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.justify,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: Colors.grey),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("Volver", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(appointmentControllerProvider).cancelAppointment(appointmentId);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Cita cancelada correctamente."),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error al cancelar la cita: $e"),
                        backgroundColor: AppColors.danger,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 2,
              ),
              child: const Text("Sí, Cancelar", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  void _editAppointmentModal(BuildContext context, WidgetRef ref, Map<String, dynamic> apt) {
    final DateTime initialDate = DateTime.parse(apt['appointment_date']).toLocal();
    DateTime selectedDate = initialDate;
    TimeOfDay selectedTime = TimeOfDay(hour: initialDate.hour, minute: initialDate.minute);
    String selectedType = apt['type'] ?? 'telemedicine';
    final reasonController = TextEditingController(text: apt['reason'] ?? 'Consulta general');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 25.0,
                right: 25.0,
                top: 25.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 25.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Editar Cita Médica",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // TIPO DE CONSULTA
                  const Text("Tipo de consulta:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("Videoconsulta"),
                          selected: selectedType == 'telemedicine',
                          onSelected: (selected) {
                            if (selected) setModalState(() => selectedType = 'telemedicine');
                          },
                          selectedColor: AppColors.secondary.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.secondary,
                          labelStyle: TextStyle(
                            color: selectedType == 'telemedicine' ? AppColors.secondary : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("En Clínica"),
                          selected: selectedType == 'in_person',
                          onSelected: (selected) {
                            if (selected) setModalState(() => selectedType = 'in_person');
                          },
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: selectedType == 'in_person' ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // SELECCIÓN DE FECHA Y HORA
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Fecha:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 60)),
                                );
                                if (picked != null) {
                                  setModalState(() => selectedDate = picked);
                                }
                              },
                              icon: const Icon(Icons.calendar_month, size: 16),
                              label: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Hora:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                );
                                if (picked != null) {
                                  setModalState(() => selectedTime = picked);
                                }
                              },
                              icon: const Icon(Icons.access_time, size: 16),
                              label: Text(selectedTime.format(context)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // MOTIVO
                  const Text("Motivo de consulta:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      hintText: "Ej. Revisión de lunares, erupción cutánea...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 25),

                  // BOTÓN GUARDAR
                  ElevatedButton(
                    onPressed: () async {
                      // Combinar fecha y hora
                      final finalDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );

                      try {
                        await ref.read(appointmentControllerProvider).updateAppointment(
                          appointmentId: apt['id'],
                          date: finalDateTime,
                          type: selectedType,
                          reason: reasonController.text.trim(),
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("✨ ¡Cita reprogramada con éxito!"),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error al reprogramar: $e"),
                              backgroundColor: AppColors.danger,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    child: const Text("Guardar Cambios", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }
}