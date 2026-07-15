import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import 'patient_clinical_detail_screen.dart';

// ============================================================================
// 🚀 CAPA DE DATOS (PROVIDERS)
// ============================================================================

// Provider para obtener SOLO los pacientes asociados a este doctor (Cumplimiento estricto de privacidad)
final patientsDirectoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final doctorId = supabase.auth.currentUser?.id;

  if (doctorId == null) return [];

  // 🔒 PRIVACIDAD: Obtener patient_ids asociados a las citas de este doctor
  final appointmentsResponse = await supabase
      .from('appointments')
      .select('patient_id')
      .eq('doctor_id', doctorId);

  final List<dynamic> appts = appointmentsResponse as List<dynamic>;
  final List<String> patientIds = appts
      .map((item) => (item['patient_id'] ?? '').toString())
      .where((id) => id.isNotEmpty && id != doctorId)
      .toSet() // Eliminar duplicados
      .toList();

  if (patientIds.isEmpty) return [];

  final response = await supabase
      .from('profiles')
      .select('id, full_name, skin_type, avatar_url')
      .inFilter('id', patientIds)
      .order('full_name', ascending: true);

  return List<Map<String, dynamic>>.from(response);
});

// ============================================================================
// 📱 CAPA DE PRESENTACIÓN (UI)
// ============================================================================

class DoctorPatientsView extends ConsumerStatefulWidget {
  const DoctorPatientsView({super.key});

  @override
  ConsumerState<DoctorPatientsView> createState() => _DoctorPatientsViewState();
}

class _DoctorPatientsViewState extends ConsumerState<DoctorPatientsView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsDirectoryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            backgroundColor: AppColors.backgroundLight,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              title: const Text("Directorio de Pacientes",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18)),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Buscar por nombre...",
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: patientsAsync.when(
              data: (patients) {
                // Lógica de filtrado local para búsqueda instantánea
                final filteredPatients = patients.where((p) {
                  final name = (p['full_name'] ?? '').toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (filteredPatients.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 50.0),
                        child: Column(
                          children: [
                            Icon(Icons.person_search_outlined, size: 60, color: AppColors.secondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 15),
                            const Text("No se encontraron pacientes", style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final patient = filteredPatients[index];
                      final String fullName = patient['full_name'] ?? 'Desconocido';
                      final String patientId = patient['id'];
                      final String skinType = patient['skin_type'] ?? 'No especificado';
                      final String? avatarUrl = patient['avatar_url'] as String?;

                      final String initials = fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : 'P';

                      return _patientCard(context, patientId, fullName, skinType, initials, avatarUrl);
                    },
                    childCount: filteredPatients.length,
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
                child: Center(child: Text("Error al cargar pacientes: $err", style: const TextStyle(color: AppColors.danger))),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)), // Espacio para el BottomNav
        ],
      ),
    );
  }

  Widget _patientCard(BuildContext context, String patientId, String name, String skinType, String initials, String? avatarUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: () {
          // 🚀 MAGIA DE NAVEGACIÓN: Vamos al expediente clínico
          // ⚠️ Nota Arquitectónica: Como entramos desde el directorio (y no desde una cita de hoy),
          // pasamos un appointmentId genérico. En el futuro, podemos adaptar el expediente
          // para que oculte el botón de "Añadir Nota" si no hay una cita activa.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientClinicalDetailScreen(
                patientId: patientId,
                appointmentId: 'directory_view', // ID dummy para vistas sin cita
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: avatarUrl != null && avatarUrl.trim().isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl != null && avatarUrl.trim().isNotEmpty
                    ? null
                    : Text(initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text("Piel: $skinType", style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}