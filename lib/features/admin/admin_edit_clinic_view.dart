import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import 'admin_providers.dart';

class AdminEditClinicView extends ConsumerStatefulWidget {
  final Map<String, dynamic>? clinic;
  const AdminEditClinicView({super.key, this.clinic});

  @override
  ConsumerState<AdminEditClinicView> createState() => _AdminEditClinicViewState();
}

class _AdminEditClinicViewState extends ConsumerState<AdminEditClinicView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _statusController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late final MapController _miniMapController;
  bool _isOpen = true;
  bool _isSaving = false;
  bool _isSearchingAddress = false;

  File? _imageFile1;
  File? _imageFile2;
  String? _existingImageUrl1;
  String? _existingImageUrl2;

  @override
  void initState() {
    super.initState();
    final c = widget.clinic;
    _nameController = TextEditingController(text: c?['name'] ?? '');
    _addressController = TextEditingController(text: c?['address'] ?? '');
    _statusController = TextEditingController(text: c?['status_text'] ?? 'Lunes a Viernes: 8:00 AM - 5:00 PM');
    _latController = TextEditingController(text: c?['lat']?.toString() ?? '');
    _lngController = TextEditingController(text: c?['lng']?.toString() ?? '');
    _isOpen = c?['is_open'] ?? true;
    _existingImageUrl1 = c?['image_url'];
    _existingImageUrl2 = c?['image_url_2'];

    _miniMapController = MapController();
    
    _latController.addListener(_onCoordsChanged);
    _lngController.addListener(_onCoordsChanged);
  }

  @override
  void dispose() {
    _latController.removeListener(_onCoordsChanged);
    _lngController.removeListener(_onCoordsChanged);
    _nameController.dispose();
    _addressController.dispose();
    _statusController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _miniMapController.dispose();
    super.dispose();
  }

  void _onCoordsChanged() {
    final double? lat = double.tryParse(_latController.text);
    final double? lng = double.tryParse(_lngController.text);
    if (lat != null && lng != null && _latController.text.length > 5 && _lngController.text.length > 5) {
      final center = _miniMapController.camera.center;
      if ((center.latitude - lat).abs() > 0.0001 || (center.longitude - lng).abs() > 0.0001) {
        _miniMapController.move(LatLng(lat, lng), _miniMapController.camera.zoom);
      }
    }
  }

  void _fillDefaultCabimasCoords() {
    setState(() {
      _latController.text = "10.3932";
      _lngController.text = "-71.4422";
    });
  }

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
            _latController.text = lat.toStringAsFixed(6);
            _lngController.text = lng.toStringAsFixed(6);
          });
          
          _miniMapController.move(LatLng(lat, lng), 15.0);

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

  Future<void> _saveClinic() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final statusText = _statusController.text.trim();
    final double lat = double.parse(_latController.text.trim());
    final double lng = double.parse(_lngController.text.trim());

    try {
      final controller = ref.read(adminControllerProvider);

      if (widget.clinic != null) {
        // Editar existente
        await controller.updateMedicalCenter(
          centerId: widget.clinic!['id'].toString(),
          name: name,
          address: address,
          statusText: statusText,
          isOpen: _isOpen,
          lat: lat,
          lng: lng,
          imageFile1: _imageFile1,
          imageFile2: _imageFile2,
          existingImageUrl1: _existingImageUrl1,
          existingImageUrl2: _existingImageUrl2,
        );
      } else {
        // Crear nueva
        await controller.addMedicalCenter(
          name: name,
          address: address,
          statusText: statusText,
          isOpen: _isOpen,
          lat: lat,
          lng: lng,
          imageFile1: _imageFile1,
          imageFile2: _imageFile2,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.clinic != null ? "Clínica actualizada con éxito" : "Clínica creada con éxito"),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Volver atrás
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al guardar: $e"),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.clinic != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isEditing ? "Editar Clínica" : "Nueva Clínica", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título decorativo
                    Row(
                      children: [
                        Icon(isEditing ? Icons.edit_note : Icons.add_business_outlined, color: AppColors.primary, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          isEditing ? "Formulario de Actualización" : "Registrar Nueva Clínica",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Nombre de la clínica
                    _buildTextField(
                      controller: _nameController,
                      label: "Nombre de la Clínica",
                      hint: "Ej. Clínica Dermatológica del Zulia",
                      icon: Icons.title,
                      validator: (value) => value == null || value.isEmpty ? "El nombre es obligatorio" : null,
                    ),
                    const SizedBox(height: 16),

                    // Dirección de la clínica
                    _buildTextField(
                      controller: _addressController,
                      label: "Dirección de la Clínica",
                      hint: "Ej. Av. Intercomunal con Calle Chile, Cabimas",
                      icon: Icons.map,
                      validator: (value) => value == null || value.isEmpty ? "La dirección es obligatoria" : null,
                      textInputAction: TextInputAction.search,
                      onFieldSubmitted: (val) => _searchAddress(),
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
                    ),
                    const SizedBox(height: 16),

                    // Horarios / Disponibilidad
                    _buildTextField(
                      controller: _statusController,
                      label: "Horarios y Disponibilidad",
                      hint: "Ej. Lun-Vie: 8:00 AM - 5:00 PM",
                      icon: Icons.access_time_filled,
                      validator: (value) => value == null || value.isEmpty ? "El horario es obligatorio" : null,
                    ),
                    const SizedBox(height: 16),

                    // Fila de Coordenadas
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _latController,
                            label: "Latitud (Lat)",
                            hint: "Ej. 10.3932",
                            icon: Icons.explore_outlined,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) return "Obligatorio";
                              if (double.tryParse(value) == null) return "Número inválido";
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _lngController,
                            label: "Longitud (Lng)",
                            hint: "Ej. -71.4422",
                            icon: Icons.explore_outlined,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) return "Obligatorio";
                              if (double.tryParse(value) == null) return "Número inválido";
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Asistente rápido de coordenadas
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.location_searching, size: 16, color: AppColors.secondary),
                        label: const Text("Centrar en Cabimas (Coordenadas)", style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                        onPressed: _fillDefaultCabimasCoords,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mapa interactivo táctil para captura de coordenadas
                    const Text(
                      "Toque en el mapa para capturar coordenadas automáticamente:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withOpacity(0.08)),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: FlutterMap(
                          mapController: _miniMapController,
                          options: MapOptions(
                            initialCenter: LatLng(
                              double.tryParse(_latController.text) ?? 10.3932,
                              double.tryParse(_lngController.text) ?? -71.4422,
                            ),
                            initialZoom: 14.0,
                            maxZoom: 18.0,
                            minZoom: 10.0,
                            onPositionChanged: (position, hasGesture) {
                              final center = position.center;
                              if (center != null) {
                                setState(() {
                                  _latController.text = center.latitude.toStringAsFixed(6);
                                  _lngController.text = center.longitude.toStringAsFixed(6);
                                });
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.testingcode.healskin',
                            ),
                            if (double.tryParse(_latController.text) != null &&
                                double.tryParse(_lngController.text) != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      double.parse(_latController.text),
                                      double.parse(_lngController.text),
                                    ),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: AppColors.danger,
                                      size: 38,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Switch Abierto/Cerrado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withOpacity(0.05)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.storefront,
                                color: _isOpen ? AppColors.success : AppColors.danger,
                              ),
                              const SizedBox(width: 12),
                              const Text("Clínica Abierta al Público", style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Switch(
                            value: _isOpen,
                            activeColor: AppColors.success,
                            onChanged: (val) {
                              setState(() {
                                _isOpen = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Fotos de la Clínica (Máx. 2)",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildImageSlot(1)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildImageSlot(2)),
                      ],
                    ),
                    const SizedBox(height: 35),

                    // Botón de guardar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          isEditing ? "Actualizar Clínica" : "Guardar Clínica",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _saveClinic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return Container(
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
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.6)),
          suffixIcon: suffixIcon,
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
          labelStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          floatingLabelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _pickImage(int imageNumber) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        if (imageNumber == 1) {
          _imageFile1 = File(pickedFile.path);
        } else {
          _imageFile2 = File(pickedFile.path);
        }
      });
    }
  }

  Widget _buildImageSlot(int slot) {
    final File? localFile = slot == 1 ? _imageFile1 : _imageFile2;
    final String? remoteUrl = slot == 1 ? _existingImageUrl1 : _existingImageUrl2;

    Widget? child;
    if (localFile != null) {
      child = Image.file(localFile, fit: BoxFit.cover);
    } else if (remoteUrl != null && remoteUrl.isNotEmpty) {
      child = Image.network(remoteUrl, fit: BoxFit.cover);
    }

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                child,
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (slot == 1) {
                          _imageFile1 = null;
                          _existingImageUrl1 = null;
                        } else {
                          _imageFile2 = null;
                          _existingImageUrl2 = null;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: () => _pickImage(slot),
              borderRadius: BorderRadius.circular(16),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 28),
                  SizedBox(height: 6),
                  Text("Añadir Foto", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                ],
              ),
            ),
    );
  }
}
