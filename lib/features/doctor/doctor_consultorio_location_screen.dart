import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../auth/profile_provider.dart';

class DoctorConsultorioLocationScreen extends ConsumerStatefulWidget {
  const DoctorConsultorioLocationScreen({super.key});

  @override
  ConsumerState<DoctorConsultorioLocationScreen> createState() => _DoctorConsultorioLocationScreenState();
}

class _DoctorConsultorioLocationScreenState extends ConsumerState<DoctorConsultorioLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _officeNameController = TextEditingController();
  final _addressController = TextEditingController();
  late final MapController _mapController;

  LatLng _selectedLatLng = const LatLng(10.3932, -71.4422); // Cabimas de referencia
  bool _isLoading = true;
  bool _isSaving = false;
  bool _useRegisteredClinic = false;
  bool _isSearchingAddress = false;

  Map<String, dynamic>? _selectedClinic;
  List<Map<String, dynamic>> _availableClinics = [];

  Future<void> _searchAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    setState(() {
      _isSearchingAddress = true;
    });

    try {
      final client = HttpClient();
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1');
      final request = await client.getUrl(url);
      request.headers.add('User-Agent', 'HealSkinApp/1.0 (pazje@testing.com)');
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final List data = jsonDecode(responseBody);
        if (data.isNotEmpty) {
          final double lat = double.parse(data[0]['lat']);
          final double lng = double.parse(data[0]['lon']);
          
          setState(() {
            _selectedLatLng = LatLng(lat, lng);
            _addressController.text = data[0]['display_name'] ?? address;
          });
          
          _mapController.move(_selectedLatLng, 15.0);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("📍 Ubicación localizada en el mapa"),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("⚠️ No se encontró la dirección. Intenta ser más específico."),
                backgroundColor: AppColors.warning,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        throw Exception("Error de respuesta: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al buscar dirección: $e"),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingAddress = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadInitialData();
  }

  @override
  void dispose() {
    _officeNameController.dispose();
    _addressController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    try {
      // 1. Cargar perfil del médico
      final profile = await supabase
          .from('profiles')
          .select('office_address, office_lat, office_lng')
          .eq('id', user.id)
          .maybeSingle();

      // 2. Cargar clínicas disponibles del admin
      final clinicsResponse = await supabase
          .from('medical_centers')
          .select()
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _availableClinics = List<Map<String, dynamic>>.from(clinicsResponse).map((item) {
            final mapped = Map<String, dynamic>.from(item);
            mapped['lat'] = (mapped['latitude'] as num?)?.toDouble();
            mapped['lng'] = (mapped['longitude'] as num?)?.toDouble();
            mapped['status_text'] = mapped['status_text'] ?? '';
            mapped['is_open'] = true;
            return mapped;
          }).toList();

          if (profile != null) {
            final String? dbAddress = profile['office_address'];
            final double? dbLat = (profile['office_lat'] as num?)?.toDouble();
            final double? dbLng = (profile['office_lng'] as num?)?.toDouble();

            if (dbAddress != null && dbAddress.isNotEmpty) {
              final firstComma = dbAddress.indexOf(',');
              if (firstComma != -1) {
                _officeNameController.text = dbAddress.substring(0, firstComma).trim();
                _addressController.text = dbAddress.substring(firstComma + 1).trim();
              } else {
                _officeNameController.text = '';
                _addressController.text = dbAddress;
              }
            }
            if (dbLat != null && dbLng != null) {
              _selectedLatLng = LatLng(dbLat, dbLng);
            }
          }

          // Verificar si las coordenadas coinciden con alguna clínica registrada
          for (final clinic in _availableClinics) {
            final double cLat = (clinic['lat'] as num?)?.toDouble() ?? 0.0;
            final double cLng = (clinic['lng'] as num?)?.toDouble() ?? 0.0;
            if ((cLat - _selectedLatLng.latitude).abs() < 0.0001 &&
                (cLng - _selectedLatLng.longitude).abs() < 0.0001) {
              _selectedClinic = clinic;
              _useRegisteredClinic = true;
              break;
            }
          }

          _isLoading = false;
        });

        // Mover mapa a las coordenadas iniciales después del primer build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(_selectedLatLng, 14.5);
        });
      }
    } catch (e) {
      debugPrint("Error al cargar datos de ubicación del consultorio: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveLocation() async {
    if (!_useRegisteredClinic && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    final String officeName = _officeNameController.text.trim();
    final String officeAddr = _addressController.text.trim();
    final String finalAddress = _useRegisteredClinic
        ? "${_selectedClinic?['name'] ?? ''}, ${_selectedClinic?['address'] ?? ''}"
        : (officeName.isNotEmpty ? "$officeName, $officeAddr" : officeAddr);

    try {
      await supabase.from('profiles').update({
        'office_address': finalAddress,
        'office_lat': _selectedLatLng.latitude,
        'office_lng': _selectedLatLng.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      // Invalidar el provider de perfil para refrescar caché local
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("📍 Ubicación del consultorio guardada con éxito"),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al guardar ubicación: $e"),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onClinicSelected(Map<String, dynamic>? clinic) {
    if (clinic == null) return;
    setState(() {
      _selectedClinic = clinic;
      final double lat = (clinic['lat'] as num?)?.toDouble() ?? 10.3932;
      final double lng = (clinic['lng'] as num?)?.toDouble() ?? -71.4422;
      _selectedLatLng = LatLng(lat, lng);
      final String clinicName = clinic['name'] ?? '';
      final String clinicAddress = clinic['address'] ?? '';
      _officeNameController.text = clinicName;
      _addressController.text = clinicAddress;
    });
    _mapController.move(_selectedLatLng, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text("Ubicación del Consultorio", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Selector de modo de configuración
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _modeButton(
                            label: "Clínica Registrada",
                            isSelected: _useRegisteredClinic,
                            onTap: () => setState(() => _useRegisteredClinic = true),
                          ),
                        ),
                        Expanded(
                          child: _modeButton(
                            label: "Ubicación Libre",
                            isSelected: !_useRegisteredClinic,
                            onTap: () => setState(() => _useRegisteredClinic = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_useRegisteredClinic) ...[
                              const Text(
                                "Selecciona el centro médico donde consultas:",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<Map<String, dynamic>>(
                                    isExpanded: true,
                                    value: _selectedClinic,
                                    hint: const Text("Seleccionar centro médico..."),
                                    items: _availableClinics.map((clinic) {
                                      return DropdownMenuItem<Map<String, dynamic>>(
                                        value: clinic,
                                        child: Text(clinic['name'] ?? 'Clínica'),
                                      );
                                    }).toList(),
                                    onChanged: _onClinicSelected,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ] else ...[
                              const Text(
                                "Detalles del Consultorio:",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.01),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _officeNameController,
                                  validator: (val) => val == null || val.isEmpty ? "El nombre del centro médico u oficina es obligatorio" : null,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: "Nombre del Centro Médico u Oficina",
                                    hintText: "Ej. Clínica San Lucas",
                                    prefixIcon: const Icon(Icons.apartment_outlined, color: AppColors.primary),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.01),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _addressController,
                                  validator: (val) => val == null || val.isEmpty ? "La dirección del consultorio es obligatoria" : null,
                                  textInputAction: TextInputAction.search,
                                  onFieldSubmitted: (val) => _searchAddress(),
                                  decoration: InputDecoration(
                                    labelText: "Dirección Completa",
                                    hintText: "Ej. Consultorio 3B, Calle 5 con Av. 10, Cabimas",
                                    prefixIcon: const Icon(Icons.business_outlined, color: AppColors.primary),
                                    suffixIcon: _isSearchingAddress
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Padding(
                                              padding: EdgeInsets.all(12.0),
                                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                            ),
                                          )
                                        : IconButton(
                                            icon: const Icon(Icons.search, color: AppColors.primary),
                                            onPressed: _searchAddress,
                                          ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Información de ubicación
                            Row(
                              children: [
                                const Icon(Icons.info_outline, color: AppColors.secondary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _useRegisteredClinic
                                        ? "El marcador se ajustará automáticamente a la dirección de la clínica seleccionada."
                                        : "Mueve el mapa a continuación para situar el marcador rojo en la ubicación exacta de tu consultorio:",
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Mapa interactivo
                            Container(
                              height: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.black.withOpacity(0.08)),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: _selectedLatLng,
                                    initialZoom: 14.5,
                                    maxZoom: 18.0,
                                    minZoom: 10.0,
                                    onPositionChanged: (position, hasGesture) {
                                      if (!_useRegisteredClinic && position.center != null) {
                                        setState(() {
                                          _selectedLatLng = position.center!;
                                        });
                                      }
                                    },
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.testingcode.healskin',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: _selectedLatLng,
                                          width: 50,
                                          height: 50,
                                          child: const Icon(
                                            Icons.location_on,
                                            color: AppColors.danger,
                                            size: 44,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Fila de Coordenadas informativas
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _coordinateBadge("Latitud", _selectedLatLng.latitude.toStringAsFixed(6)),
                                _coordinateBadge("Longitud", _selectedLatLng.longitude.toStringAsFixed(6)),
                              ],
                            ),
                            const SizedBox(height: 40),

                            // Botón de guardar
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 2,
                                  shadowColor: AppColors.primary.withOpacity(0.3),
                                ),
                                icon: _isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.save_outlined, color: Colors.white),
                                label: Text(
                                  _isSaving ? "Guardando..." : "Guardar Configuración",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                onPressed: _isSaving ? null : _saveLocation,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _modeButton({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _coordinateBadge(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary)),
          Text(val, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
