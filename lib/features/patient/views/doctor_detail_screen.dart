import 'package:flutter/material.dart';
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

  // 🚀 LA LÓGICA MAESTRA DE AGENDAMIENTO
  Future<void> _processBooking(BuildContext context, String type, String doctorName) async {
    // 1. Pedimos al usuario que seleccione la fecha
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)), // Mañana por defecto
      firstDate: DateTime.now(), // No se puede viajar al pasado
      lastDate: DateTime.now().add(const Duration(days: 60)), // Hasta 2 meses
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
          final availability = doctorData['availability'] ?? 'Consultar horario';
          final specialty = doctorData['specialty'] ?? 'Especialista en Dermatología';
          final bio = doctorData['bio'] ?? 'Especialista clínico con amplia experiencia en el diagnóstico temprano y tratamiento de patologías de la piel asistido por tecnología.';
          final patientsCount = doctorData['patients_count']?.toString() ?? 'N/A';
          final experienceYears = doctorData['experience_years']?.toString() ?? '-';
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
                              child: Icon(avatarIcon, size: 60, color: AppColors.textSecondary),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatCard("Pacientes", patientsCount, Icons.people_outline),
                              _buildStatCard("Experiencia", "$experienceYears años", Icons.work_outline),
                              _buildStatCard("Rating", rating, Icons.star_border),
                            ],
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
                          const SizedBox(height: 150), // Espacio para botones + cargador
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