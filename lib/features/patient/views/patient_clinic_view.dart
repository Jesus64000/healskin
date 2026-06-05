import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/profile_provider.dart'; // O el archivo donde pusiste los nuevos providers
import 'doctor_detail_screen.dart';
import 'patient_appointments_provider.dart'; // Asegúrate de que la ruta sea correcta según tus carpetas

// 🚀 NUEVO IMPORT: La pantalla de chat que construimos
import '../../chat/chat_view.dart';

class PatientClinicView extends ConsumerWidget {
  const PatientClinicView({super.key});

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'person_3': return Icons.person_3;
      case 'person_4': return Icons.person_4;
      case 'person_2': return Icons.person_2;
      default: return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🧠 CONSUMIMOS LOS DOS PROVEEDORES NUEVOS
    final primaryDoctorAsync = ref.watch(primaryDoctorProvider);
    final availableDoctorsAsync = ref.watch(availableDoctorsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(primaryDoctorProvider);
          ref.invalidate(availableDoctorsProvider);
          await Future.delayed(const Duration(seconds: 1));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverAppBar(
              expandedHeight: 80,
              floating: true,
              backgroundColor: AppColors.backgroundLight,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                title: Text(
                    "Red de Guardianes de la Piel",
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18)
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPriorityBanner(),
                    const SizedBox(height: 30),

                    // --- 🌟 SECCIÓN 1: TU MÉDICO PRINCIPAL ---
                    primaryDoctorAsync.when(
                      data: (primaryDoc) {
                        if (primaryDoc == null) return const SizedBox.shrink(); // No tiene doctor principal
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                                "Tu Médico de Cabecera",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)
                            ),
                            const SizedBox(height: 15),
                            _buildPrimaryDoctorCard(context, primaryDoc),
                            const SizedBox(height: 30),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (err, _) => const SizedBox.shrink(),
                    ),

                    // --- 👥 SECCIÓN 2: OTROS ESPECIALISTAS ---
                    const Text(
                        "Otros Especialistas Disponibles",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)
                    ),
                    const SizedBox(height: 15),

                    availableDoctorsAsync.when(
                      data: (doctors) {
                        if (doctors.isEmpty) {
                          return _buildEmptyState();
                        }
                        return Column(
                          children: doctors.map((doc) => _buildDoctorTile(
                            context: context,
                            doctorId: doc['id'] ?? '',
                            name: "Dr. ${doc['full_name'] ?? 'Doctor'}",
                            specialty: doc['specialty'] ?? 'Especialista en Dermatología',
                            schedule: doc['availability'] ?? 'Consultar horario',
                            avatarIcon: _getIconData(doc['avatar_type']),
                          )).toList(),
                        );
                      },
                      loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          )
                      ),
                      error: (err, stack) => Center(
                          child: Text("Error al cargar médicos: $err")
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- COMPONENTES UI ---

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.medical_information_outlined, size: 60, color: AppColors.secondary.withValues(alpha: 0.3)),
          const SizedBox(height: 15),
          const Text(
            "No hay especialistas disponibles",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 5),
          const Text(
            "Estamos actualizando nuestra red de médicos.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tu salud, es", style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
                Text("Nuestra Prioridad", style: TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 10)]
            ),
            child: const Icon(Icons.favorite, color: AppColors.primary, size: 30),
          )
        ],
      ),
    );
  }

  // 🌟 NUEVO: Tarjeta destacada para el médico principal CON BOTÓN DE CHAT
  Widget _buildPrimaryDoctorCard(BuildContext context, Map<String, dynamic> doc) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DoctorDetailScreen(doctorId: doc['id'])),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))
            ]
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(_getIconData(doc['avatar_type']), color: AppColors.primary, size: 35),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Dr. ${doc['full_name']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 5),
                  Text(doc['specialty'] ?? 'Tu Médico Asignado', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                ],
              ),
            ),
            // 🚀 AQUÍ ESTÁ EL BOTÓN DE CHAT MÁGICO
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChatView(
                      otherUserId: doc['id'],
                      otherUserName: "Dr. ${doc['full_name']}",
                    )),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorTile({
    required BuildContext context,
    required String doctorId,
    required String name,
    required String specialty,
    required String schedule,
    required IconData avatarIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: () {
          if (doctorId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DoctorDetailScreen(doctorId: doctorId)),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
              ]
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(avatarIcon, color: AppColors.textSecondary, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(specialty, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(schedule, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_forward_ios, color: AppColors.secondary, size: 16),
              )
            ],
          ),
        ),
      ),
    );
  }
}