import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/image_utils.dart';
import 'admin_providers.dart';

class AdminScansHistoryScreen extends ConsumerStatefulWidget {
  const AdminScansHistoryScreen({super.key});

  @override
  ConsumerState<AdminScansHistoryScreen> createState() => _AdminScansHistoryScreenState();
}

class _AdminScansHistoryScreenState extends ConsumerState<AdminScansHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedRiskFilter = "Todos"; // Todos, Alto, Medio, Bajo

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showScanDetails(Map<String, dynamic> scan) {
    final patientName = scan['profiles']?['full_name'] ?? 'Paciente';
    final date = scan['created_at'] != null
        ? DateFormat('dd MMMM yyyy, hh:mm a', 'es').format(DateTime.parse(scan['created_at']).toLocal())
        : 'Fecha desc.';
    final diagnosis = scan['ai_diagnosis'] ?? 'Sin diagnóstico';
    final recommendation = scan['recommendation'] ?? 'Sin recomendaciones registradas.';
    final rawRisk = (scan['risk_level'] ?? 'low').toString().toLowerCase().trim();
    final imageUrl = scan['image_url'] as String?;

    final isRisk = rawRisk.contains('high') ||
        rawRisk.contains('urgent') ||
        rawRisk.contains('alto') ||
        rawRisk.contains('urgente');
    final isMedium = rawRisk.contains('medium') || rawRisk.contains('medio');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isRisk
                              ? AppColors.danger.withOpacity(0.1)
                              : isMedium
                                  ? Colors.orange.withOpacity(0.1)
                                  : AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isRisk
                              ? "RIESGO ALTO"
                              : isMedium
                                  ? "RIESGO MEDIO"
                                  : "NORMAL / BAJO",
                          style: TextStyle(
                            color: isRisk
                                ? AppColors.danger
                                : isMedium
                                    ? Colors.orange
                                    : AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (imageUrl != null && imageUrl.isNotEmpty) ...[
                    const Text(
                      "Lesión Analizada",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => showFullScreenImage(context, imageUrl),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: double.infinity,
                                height: 220,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.broken_image, size: 50, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Text(
                    "Diagnóstico de la IA",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      diagnosis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Recomendaciones e Indicaciones",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recommendation,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cerrar Auditoría", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scansAsync = ref.watch(allScansProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Historial de Escaneos IA",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      body: scansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text("Error al cargar escaneos: $err")),
        data: (scans) {
          // Cálculo de métricas
          final totalScans = scans.length;
          final highRiskCount = scans.where((s) {
            final raw = (s['risk_level'] ?? 'low').toString().toLowerCase();
            return raw.contains('high') || raw.contains('urgent') || raw.contains('alto') || raw.contains('urgente');
          }).length;
          final uniquePatientsCount = scans.map((s) => s['patient_id']).where((id) => id != null).toSet().length;

          // Filtrado local
          final List<Map<String, dynamic>> filteredScans = scans.where((scan) {
            final patientName = (scan['profiles']?['full_name'] ?? 'Paciente').toString().toLowerCase();
            final diagnosis = (scan['ai_diagnosis'] ?? '').toString().toLowerCase();
            final rawRisk = (scan['risk_level'] ?? 'low').toString().toLowerCase().trim();

            final matchesSearch = _searchQuery.isEmpty ||
                patientName.contains(_searchQuery) ||
                diagnosis.contains(_searchQuery);

            if (!matchesSearch) return false;

            if (_selectedRiskFilter == "Todos") return true;

            if (_selectedRiskFilter == "Alto") {
              return rawRisk.contains('high') || rawRisk.contains('urgent') || rawRisk.contains('alto') || rawRisk.contains('urgente');
            }
            if (_selectedRiskFilter == "Medio") {
              return rawRisk.contains('medium') || rawRisk.contains('medio');
            }
            if (_selectedRiskFilter == "Bajo") {
              return rawRisk.contains('low') || rawRisk.contains('bajo') || rawRisk.contains('normal');
            }

            return true;
          }).toList();

          return Column(
            children: [
              // 📊 Tarjetas de Métricas de Auditoría
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: _buildSummaryMiniCard("Total", "$totalScans", Icons.document_scanner_rounded, AppColors.primary)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSummaryMiniCard("Alto Riesgo", "$highRiskCount", Icons.warning_amber_rounded, AppColors.danger)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSummaryMiniCard("Pacientes", "$uniquePatientsCount", Icons.people_alt_rounded, AppColors.secondary)),
                  ],
                ),
              ),

              // 🔍 Barra de Búsqueda y Filtros
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Buscar paciente o diagnóstico...",
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 35,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ["Todos", "Alto", "Medio", "Bajo"].map((risk) {
                          final isSelected = _selectedRiskFilter == risk;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(risk),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              backgroundColor: AppColors.surfaceLight,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedRiskFilter = risk;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // 📜 Lista de Escaneos
              Expanded(
                child: filteredScans.isEmpty
                    ? const Center(
                        child: Text(
                          "No se encontraron escaneos con los filtros activos.",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: filteredScans.length,
                        itemBuilder: (context, index) {
                          final scan = filteredScans[index];
                          final patientName = scan['profiles']?['full_name'] ?? 'Paciente';
                          final date = scan['created_at'] != null
                              ? DateFormat('dd MMM, hh:mm a', 'es').format(DateTime.parse(scan['created_at']).toLocal())
                              : 'Fecha desc.';
                          final diagnosis = scan['ai_diagnosis'] ?? 'Sin diagnóstico';
                          final imageUrl = scan['image_url'] as String?;
                          final rawRisk = (scan['risk_level'] ?? 'low').toString().toLowerCase().trim();

                          final isRisk = rawRisk.contains('high') ||
                              rawRisk.contains('urgent') ||
                              rawRisk.contains('alto') ||
                              rawRisk.contains('urgente');
                          final isMedium = rawRisk.contains('medium') || rawRisk.contains('medio');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.01),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: InkWell(
                              onTap: () => _showScanDetails(scan),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    if (imageUrl != null && imageUrl.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          imageUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 50,
                                            height: 50,
                                            color: AppColors.surfaceLight,
                                            child: const Icon(Icons.broken_image, size: 20, color: AppColors.textSecondary),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceLight,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.document_scanner_rounded, color: AppColors.primary, size: 24),
                                      ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            patientName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "$diagnosis • $date",
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isRisk
                                            ? AppColors.danger.withValues(alpha: 0.1)
                                            : isMedium
                                                ? Colors.orange.withValues(alpha: 0.1)
                                                : AppColors.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isRisk
                                            ? "ALTO"
                                            : isMedium
                                                ? "MEDIO"
                                                : "NORMAL",
                                        style: TextStyle(
                                          color: isRisk
                                              ? AppColors.danger
                                              : isMedium
                                                  ? Colors.orange.shade800
                                                  : AppColors.success,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryMiniCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            ],
          ),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
