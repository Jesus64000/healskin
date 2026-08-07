import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/profile_provider.dart';
import 'patient_appointments_provider.dart';

class DoctorDetailScreen extends ConsumerStatefulWidget {
  final String doctorId;

  const DoctorDetailScreen({
    super.key,
    required this.doctorId,
  });

  @override
  ConsumerState<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends ConsumerState<DoctorDetailScreen> {
  final bool _isBooking = false;

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'person_3': return Icons.person_3;
      case 'person_4': return Icons.person_4;
      case 'person_2': return Icons.person_2;
      default: return Icons.person;
    }
  }

  String _formatAvailability(dynamic availability) {
    if (availability == null) return 'Consultar horario';
    if (availability is String) {
      if (availability.startsWith('{')) {
        try {
          final Map<String, dynamic> map = jsonDecode(availability);
          final List<String> parts = [];
          map.forEach((key, value) {
            if (value != null && value != "Cerrado") {
              parts.add("$key: $value");
            }
          });
          if (parts.isEmpty) return 'No laborable';
          return parts.join("\n");
        } catch (e) {
          return availability;
        }
      }
      return availability;
    }
    return 'Consultar horario';
  }

  // 🚀 APERTURA DEL MODAL INTERACTIVO DE HORARIOS (CHIPS)
  void _processBooking(BuildContext context, String type, String doctorName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookingModal(
        doctorId: widget.doctorId,
        doctorName: doctorName,
        appointmentType: type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(doctorDetailProvider(widget.doctorId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: doctorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text("Error al cargar perfil: $err")),
        data: (doctorData) {
          if (doctorData == null) return const Center(child: Text("Médico no encontrado"));

          final name = doctorData['full_name'] ?? 'Doctor';
          final avatarIcon = _getIconData(doctorData['avatar_type']);
          final availability = _formatAvailability(doctorData['availability']);
          final specialty = doctorData['specialty'] ?? 'Especialista en Dermatología';
          final bio = doctorData['bio'] ?? 'Especialista clínico con amplia experiencia en el diagnóstico temprano y tratamiento de patologías de la piel asistido por tecnología.';
          final patientsCount = doctorData['patient_count']?.toString() ?? 'N/A';
          final experienceYears = doctorData['years_experience']?.toString() ?? '-';
          final rating = doctorData['rating']?.toString() ?? '-.-';

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 250,
                    pinned: true,
                    backgroundColor: AppColors.primary,
                    leading: CircleAvatar(
                      backgroundColor: Colors.black26,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 30),
                            CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.white24,
                              child: Icon(avatarIcon, size: 50, color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Text("Dr. $name", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(specialty, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ESTADÍSTICAS
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5))],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatCard("Pacientes", patientsCount, Icons.people),
                                _buildStatCard("Experiencia", "$experienceYears años", Icons.work_history),
                                _buildStatCard("Calificación", rating, Icons.star),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),

                          // BIOGRAFÍA
                          const Text("Sobre el Especialista", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 10),
                          Text(bio, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
                          const SizedBox(height: 25),

                          // HORARIOS Y UBICACIÓN
                          const Text("Disponibilidad General", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_filled, color: AppColors.primary, size: 28),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(availability, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 120), // Espacio para botones flotantes
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // BOTONES INFERIORES
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _processBooking(context, 'telemedicine', name),
                            icon: const Icon(Icons.video_camera_front, color: Colors.white),
                            label: const Text("Agendar Videoconsulta", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _processBooking(context, 'in_person', name),
                            icon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                            label: const Text("Cita Presencial en Clínica", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: AppColors.surfaceLight, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

// 🚀 MODAL INTERACTIVO PARA SELECCIÓN DE HORARIOS DISPONIBLES (CHIPS)
class _BookingModal extends ConsumerStatefulWidget {
  final String doctorId;
  final String doctorName;
  final String appointmentType;

  const _BookingModal({
    required this.doctorId,
    required this.doctorName,
    required this.appointmentType,
  });

  @override
  ConsumerState<_BookingModal> createState() => _BookingModalState();
}

class _BookingModalState extends ConsumerState<_BookingModal> {
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;
  final TextEditingController _reasonController = TextEditingController(text: "Consulta general");

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  List<TimeOfDay> _generateStandardTimeSlots() {
    final List<TimeOfDay> slots = [];
    for (int hour = 8; hour <= 17; hour++) {
      slots.add(TimeOfDay(hour: hour, minute: 0));
      if (hour != 17) {
        slots.add(TimeOfDay(hour: hour, minute: 30));
      }
    }
    return slots;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  bool _isSameTime(TimeOfDay t1, TimeOfDay t2) {
    return t1.hour == t2.hour && t1.minute == t2.minute;
  }

  @override
  Widget build(BuildContext context) {
    final availabilityAsync = ref.watch(
      doctorDayAvailabilityProvider((doctorId: widget.doctorId, date: _selectedDate)),
    );

    final isTelemedicine = widget.appointmentType == 'telemedicine';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTelemedicine ? "Agendar Videoconsulta" : "Agendar Cita Presencial",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      "Dr. ${widget.doctorName}",
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            const Text(
              "1. Selecciona la Fecha",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('EEEE d MMMM, yyyy', 'es_ES').format(_selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 60)),
                              locale: const Locale('es', 'ES'),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDate = DateTime(picked.year, picked.month, picked.day);
                                _selectedTime = null;
                              });
                            }
                          },
                          child: const Text("Cambiar", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              "2. Selecciona el Horario",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            availabilityAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text("Error al cargar horarios: $err", style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
              ),
              data: (availability) {
                if (availability.isAllDayBlocked) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Jornada Bloqueada por el Médico",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                availability.blockReason ?? "El médico no atenderá consultas en esta fecha.",
                                style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final slots = _generateStandardTimeSlots();

                return Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: slots.map((slot) {
                    final isOccupied = availability.occupiedSlots.any((o) => _isSameTime(o, slot));
                    final isBlocked = availability.blockedSlots.any((b) => _isSameTime(b, slot));
                    final isSelected = _selectedTime != null && _isSameTime(_selectedTime!, slot);

                    final bool isDisabled = isOccupied || isBlocked;

                    Color bgColor;
                    Color textColor;
                    BorderSide borderSide;
                    String labelExtra = '';

                    if (isBlocked) {
                      bgColor = Colors.red.shade50;
                      textColor = Colors.red.shade700;
                      borderSide = BorderSide(color: Colors.red.shade200);
                      labelExtra = ' 🚫';
                    } else if (isOccupied) {
                      bgColor = Colors.grey.shade200;
                      textColor = Colors.grey.shade600;
                      borderSide = BorderSide(color: Colors.grey.shade300);
                      labelExtra = ' 🔒';
                    } else if (isSelected) {
                      bgColor = AppColors.primary;
                      textColor = Colors.white;
                      borderSide = const BorderSide(color: AppColors.primary, width: 2);
                    } else {
                      bgColor = Colors.white;
                      textColor = AppColors.textPrimary;
                      borderSide = BorderSide(color: AppColors.primary.withValues(alpha: 0.3));
                    }

                    return InkWell(
                      onTap: isDisabled
                          ? () {
                              final String msg = isBlocked
                                  ? "Horario bloqueado por el médico"
                                  : "Horario ya reservado por otro paciente";
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(msg),
                                  backgroundColor: Colors.orange.shade800,
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          : () {
                              setState(() {
                                _selectedTime = slot;
                              });
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.fromBorderSide(borderSide),
                        ),
                        child: Text(
                          "${_formatTimeOfDay(slot)}$labelExtra",
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: textColor,
                            fontSize: 13,
                            decoration: isDisabled ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            const Text(
              "3. Motivo de la Consulta",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: "Ej. Control dermatológico, erupción cutánea...",
                fillColor: AppColors.backgroundLight,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedTime == null || _isSubmitting)
                    ? null
                    : () async {
                        setState(() => _isSubmitting = true);
                        try {
                          final appointmentDateTime = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                            _selectedTime!.hour,
                            _selectedTime!.minute,
                          );

                          final controller = ref.read(appointmentControllerProvider);

                          await controller.bookAppointment(
                            doctorId: widget.doctorId,
                            date: appointmentDateTime,
                            type: widget.appointmentType,
                            reason: _reasonController.text.trim().isEmpty ? "Consulta general" : _reasonController.text.trim(),
                          );

                          ref.invalidate(primaryDoctorProvider);
                          ref.invalidate(availableDoctorsProvider);
                          ref.invalidate(myAppointmentsProvider);

                          if (mounted) {
                            Navigator.pop(context); // Cerrar Modal
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("¡Cita agendada con éxito con el Dr. ${widget.doctorName}!"),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Navigator.pop(context); // Volver de la pantalla del doctor
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error al agendar: $e"),
                                backgroundColor: AppColors.danger,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isSubmitting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTelemedicine ? AppColors.secondary : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _selectedTime == null ? "Selecciona un horario libre" : "Confirmar Cita para ${_formatTimeOfDay(_selectedTime!)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}