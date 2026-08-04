import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/profile_provider.dart'; // Ajusta si el nombre de tu archivo es distinto
// 🚀 INCLUYE EL PROVIDER QUE CREAMOS EN EL PASO ANTERIOR
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
  bool _isBooking = false;

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

  // 🚀 LA LÓGICA MAESTRA DE AGENDAMIENTO
  Future<void> _processBooking(BuildContext context, String type, String doctorName) async {
    // 1. Pedimos al usuario que seleccione la fecha
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)), // Mañana por defecto
      firstDate: DateTime.now(), // No se puede viajar al pasado
      lastDate: DateTime.now().add(const Duration(days: 60)), // Hasta 2 meses
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return; // Canceló

    // 1.2. Pedimos al usuario que seleccione la hora para la cita
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0), // 9:00 AM por defecto
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (pickedTime == null || !mounted) return; // Canceló

    // Combinamos la fecha y la hora seleccionada
    final DateTime appointmentDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() => _isBooking = true);

    try {
      // 2. Ejecutamos el Controller
      final controller = ref.read(appointmentControllerProvider);

      await controller.bookAppointment(
        doctorId: widget.doctorId,
        date: appointmentDateTime,
        type: type, // 'in_person' o 'telemedicine'
        reason: "Consulta general", // Podríamos poner un Textfield después
      );

      // 3. Forzamos a que la lista principal se actualice para mostrar a "Tu Doctor"
      ref.invalidate(primaryDoctorProvider);
      ref.invalidate(availableDoctorsProvider);
      ref.invalidate(myAppointmentsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("¡Cita agendada con éxito con el Dr. $doctorName!"),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Volvemos al Dashboard
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al agendar: $e"), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Asumo que tienes un provider llamado doctorDetailProvider en tu profile_provider.dart
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
                    iconTheme: const IconThemeData(color: Colors.white),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.accentDark],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5))],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: doctorData['avatar_url'] != null && (doctorData['avatar_url'] as String).isNotEmpty
                                    ? Image.network(
                                        doctorData['avatar_url'] as String,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Icon(avatarIcon, size: 60, color: AppColors.textSecondary),
                                      )
                                    : Icon(avatarIcon, size: 60, color: AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            Text(specialty, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: _buildStatCard("Experiencia", "$experienceYears años", Icons.work_outline),
                          ),
                          const SizedBox(height: 30),

                          const Text("Acerca del especialista", style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(bio, style: const TextStyle(color: AppColors.textSecondary, height: 1.6)),
                          const SizedBox(height: 30),

                          const Text("Disponibilidad de hoy", style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: AppColors.secondary),
                                const SizedBox(width: 10),
                                Text(availability, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),

                          const Text("Consultorio / Dirección", style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_outlined, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    doctorData['office_address'] ?? 'Consulta en Sede Central HealSkin',
                                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 220), // Espacio para botones + cargador
                        ],
                      ),
                    ),
                  )
                ],
              ),

              // UI DE CARGA (Overlay)
              if (_isBooking)
                Container(
                  color: Colors.white.withValues(alpha: 0.8),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 15),
                        Text("Agendando cita...", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),

              // BOTONES INFERIORES
              if (!_isBooking)
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