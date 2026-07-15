import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../auth/profile_provider.dart';
import 'admin_providers.dart';
import 'admin_edit_clinic_view.dart';

class AdminClinicManagementView extends ConsumerStatefulWidget {
  const AdminClinicManagementView({super.key});

  @override
  ConsumerState<AdminClinicManagementView> createState() => _AdminClinicManagementViewState();
}

class _AdminClinicManagementViewState extends ConsumerState<AdminClinicManagementView> {
  bool _showMap = false;
  Map<String, dynamic>? _selectedClinic;
  late final MapController _mapController;

  final double centerLat = 10.3932;
  final double centerLng = -71.4422;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clinicsAsync = ref.watch(medicalCentersProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text("Gestión de Clínicas", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showMap ? Icons.list_alt : Icons.map_outlined,
              color: AppColors.primary,
            ),
            tooltip: _showMap ? "Mostrar Lista" : "Mostrar Mapa de Auditoría",
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
                _selectedClinic = null;
              });
            },
          ),
        ],
      ),
      body: clinicsAsync.when(
        data: (clinics) {
          if (clinics.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_hospital_outlined, size: 64, color: AppColors.secondary),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "No hay clínicas registradas",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Agrega una clínica para que aparezca en el mapa del paciente.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showMap ? _buildMapView(clinics) : _buildListView(clinics),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text("Error al cargar clínicas: $err", style: const TextStyle(color: AppColors.danger)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminEditClinicView(),
          ),
        ).then((_) => ref.invalidate(medicalCentersProvider)),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nueva Clínica", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> clinics) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.refresh(medicalCentersProvider),
      child: ListView.builder(
        key: const PageStorageKey("clinic_list"),
        padding: const EdgeInsets.all(20),
        itemCount: clinics.length,
        itemBuilder: (context, index) {
          final clinic = clinics[index];
          final bool isOpen = clinic['is_open'] == true;

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminEditClinicView(clinic: clinic),
                  ),
                ).then((_) => ref.invalidate(medicalCentersProvider)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.local_hospital, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clinic['name'] ?? 'Clínica Asociada',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              clinic['address'] ?? 'Dirección no disponible',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isOpen ? AppColors.success : AppColors.danger).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isOpen ? "Abierto" : "Cerrado",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isOpen ? AppColors.success : AppColors.danger,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    "${clinic['lat'] != null ? (clinic['lat'] as num).toStringAsFixed(4) : '0'}, ${clinic['lng'] != null ? (clinic['lng'] as num).toStringAsFixed(4) : '0'}",
                                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.secondary, size: 20),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminEditClinicView(clinic: clinic),
                              ),
                            ).then((_) => ref.invalidate(medicalCentersProvider)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                            onPressed: () => _showDeleteConfirmation(context, ref, clinic),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapView(List<Map<String, dynamic>> clinics) {
    return Stack(
      children: [
        // Mapa interactivo real de OpenStreetMap
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(centerLat, centerLng),
              initialZoom: 13.5,
              maxZoom: 18.0,
              minZoom: 10.0,
              onTap: (_, __) {
                setState(() {
                  _selectedClinic = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.testingcode.healskin',
              ),
              MarkerLayer(
                markers: [
                  // Marcador de cabecera/referencia
                  Marker(
                    point: LatLng(centerLat, centerLng),
                    width: 70,
                    height: 70,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.secondary, width: 2),
                          ),
                          child: const Icon(Icons.location_searching, color: AppColors.secondary, size: 16),
                        ),
                      ],
                    ),
                  ),

                  // Marcadores de las clínicas registradas
                  ...clinics.map((clinic) {
                    final double lat = (clinic['lat'] as num?)?.toDouble() ?? centerLat;
                    final double lng = (clinic['lng'] as num?)?.toDouble() ?? centerLng;
                    final bool isSelected = _selectedClinic != null && _selectedClinic!['id'] == clinic['id'];

                    return Marker(
                      point: LatLng(lat, lng),
                      width: 120,
                      height: 70,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedClinic = clinic;
                          });
                          _mapController.move(LatLng(lat, lng), 14.5);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutBack,
                          transform: Matrix4.identity()..scale(isSelected ? 1.15 : 1.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on, 
                                color: isSelected ? AppColors.primary : AppColors.secondary, 
                                size: isSelected ? 34 : 28,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                ),
                                child: Text(
                                  clinic['name'] ?? 'Clínica',
                                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),

        // Tarjeta flotante detallada
        if (_selectedClinic != null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_hospital_outlined, color: AppColors.primary),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedClinic!['name'] ?? 'Clínica', 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedClinic!['address'] ?? 'Dirección', 
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () {
                            setState(() {
                              _selectedClinic = null;
                            });
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 15),

                    // 📸 FOTOS DE LA CLÍNICA (Si están disponibles)
                    if ((_selectedClinic!['image_url'] != null && (_selectedClinic!['image_url'] as String).isNotEmpty) ||
                        (_selectedClinic!['image_url_2'] != null && (_selectedClinic!['image_url_2'] as String).isNotEmpty)) ...[
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            if (_selectedClinic!['image_url'] != null && (_selectedClinic!['image_url'] as String).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    _selectedClinic!['image_url'] as String,
                                    width: 180,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            if (_selectedClinic!['image_url_2'] != null && (_selectedClinic!['image_url_2'] as String).isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  _selectedClinic!['image_url_2'] as String,
                                  width: 180,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ((_selectedClinic!['is_open'] == true) ? AppColors.success : AppColors.danger).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (_selectedClinic!['is_open'] == true) ? "Abierto" : "Cerrado",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: (_selectedClinic!['is_open'] == true) ? AppColors.success : AppColors.danger,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                        Text(
                          "${_selectedClinic!['lat']?.toString() ?? '0'}, ${_selectedClinic!['lng']?.toString() ?? '0'}",
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text("Editar Clínica", style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              final c = _selectedClinic;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminEditClinicView(clinic: c),
                                ),
                              ).then((_) {
                                setState(() {
                                  _selectedClinic = null;
                                });
                                ref.invalidate(medicalCentersProvider);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger.withOpacity(0.1),
                            foregroundColor: AppColors.danger,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text("Eliminar"),
                          onPressed: () {
                            final clinicToDelete = _selectedClinic!;
                            setState(() {
                              _selectedClinic = null;
                            });
                            _showDeleteConfirmation(context, ref, clinicToDelete);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Map<String, dynamic> clinic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¿Eliminar Clínica?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Esta acción eliminará permanentemente la clínica '${clinic['name']}' y ya no se mostrará en el mapa del paciente."),
        actions: [
          TextButton(
            child: const Text("Cancelar", style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Eliminar", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(adminControllerProvider).deleteMedicalCenter(clinic['id'].toString());
                ref.invalidate(medicalCentersProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Clínica '${clinic['name']}' eliminada con éxito"),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error al eliminar clínica: $e"),
                      backgroundColor: AppColors.danger,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
