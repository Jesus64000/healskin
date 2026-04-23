import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/auth_provider.dart';
import '../../auth/profile_provider.dart';

class PatientHomeView extends ConsumerWidget {
  const PatientHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        final String userName = profile?['full_name'] ?? "Usuario";
        final String skinType = profile?['skin_type'] ?? "no definida";

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 80,
              floating: true,
              pinned: false,
              backgroundColor: AppColors.backgroundLight,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // ARREGLO AQUÍ: Envolvemos en Expanded para evitar la cinta amarilla
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Bienvenido", style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.normal)),
                          Text(
                            userName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            maxLines: 1, // Forzamos a que sea 1 sola línea
                            overflow: TextOverflow.ellipsis, // Ponemos "..." si el nombre es muy largo
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10), // Un pequeño respiro antes del botón
                    InkWell(
                      onTap: () => ref.read(authProvider.notifier).logout(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12)
                        ),
                        child: const Icon(Icons.logout, color: AppColors.primary, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBannerNovedades(),
                    const SizedBox(height: 25),
                    _buildSearchBar(),
                    const SizedBox(height: 30),
                    _buildCategoriasGrid(),
                    const SizedBox(height: 35),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Para tu piel $skinType",
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        const Text("Ver todos", style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildDermotipsCarousel(),
                    const SizedBox(height: 35),

                    const Text("Cuestionarios", style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _buildCuestionarioList(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text("Error al cargar datos: $err")),
      ),
    );
  }

  Widget _buildBannerNovedades() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.secondary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
            child: const Text("Novedades", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          const Text("Desliza, aprende y enamórate", style: TextStyle(color: Colors.white, fontSize: 16)),
          const Text("de tu Piel", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: const TextField(
        style: TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: "Accede a lo indispensable para una piel sana",
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          suffixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildCategoriasGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _categoriaItem("Patologías", Icons.coronavirus_outlined),
        _categoriaItem("Piel", Icons.face_retouching_natural),
        _categoriaItem("Productos", Icons.clean_hands_outlined),
      ],
    );
  }

  Widget _categoriaItem(String title, IconData icon) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: AppColors.primary, size: 40),
        ),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDermotipsCarousel() {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _dermotipCard("Uso correcto de Protector Solar", Icons.wb_sunny_outlined, AppColors.primary),
          _dermotipCard("Consulta Médica Ante Anomalías", Icons.medical_services_outlined, AppColors.secondary),
          _dermotipCard("Rutina de Limpieza Diaria", Icons.water_drop_outlined, AppColors.success),
        ],
      ),
    );
  }

  Widget _dermotipCard(String title, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildCuestionarioList() {
    return Column(
      children: [
        _cuestionarioTile("Tipo de Piel", "Descubre tus necesidades", Icons.assignment_outlined),
        const SizedBox(height: 10),
        _cuestionarioTile("Hábitos Actuales", "Evalúa tu rutina diaria", Icons.fact_check_outlined),
      ],
    );
  }

  Widget _cuestionarioTile(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
        ],
      ),
    );
  }
}