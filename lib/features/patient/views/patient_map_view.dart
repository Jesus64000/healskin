import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/profile_provider.dart';

// 📏 Helper de distancia Haversine (Precisión absoluta en km)
double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double p = 0.017453292519943295; // pi / 180
  final double a = 0.5 - cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) *
      (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
}

// 🩺 Generador dinámico premium de tratamientos clínicos de alta gama
List<String> _getClinicTreatments(Map<String, dynamic> clinic) {
  if (clinic['treatments'] != null) {
    if (clinic['treatments'] is List) {
      return List<String>.from(clinic['treatments']);
    } else if (clinic['treatments'] is String) {
      return (clinic['treatments'] as String).split(',').map((e) => e.trim()).toList();
    }
  }

  final String name = (clinic['name'] ?? '').toString().toLowerCase();
  if (name.contains('estét') || name.contains('estet') || name.contains('laser') || name.contains('lser') || name.contains('spa')) {
    return [
      "Depilación Láser Diodo",
      "Rejuvenecimiento Facial CO2",
      "HIFU Facial y Corporal",
      "Hydrafacial Premium",
      "Rellenos de Ácido Hialurónico",
      "Tratamiento Liporeductor"
    ];
  } else if (name.contains('derm') || name.contains('piel') || name.contains('clínic') || name.contains('clinic')) {
    return [
      "Dermatoscopia de Lunares",
      "Crioterapia de Lesiones",
      "Terapia Fotodinámica",
      "Tratamiento para Acné Severo",
      "Control de Psoriasis y Rosácea",
      "Microdermoabrasión Médica"
    ];
  } else {
    return [
      "Limpieza Facial Profunda",
      "Plasma Rico en Plaquetas (PRP)",
      "Tratamiento Hidratante Premium",
      "Peeling Químico Medio",
      "Mesoterapia Revitalizante"
    ];
  }
}

// 🧪 Generador dinámico premium de aparatología y tecnología médica
List<String> _getClinicEquipment(Map<String, dynamic> clinic) {
  if (clinic['equipment'] != null) {
    if (clinic['equipment'] is List) {
      return List<String>.from(clinic['equipment']);
    } else if (clinic['equipment'] is String) {
      return (clinic['equipment'] as String).split(',').map((e) => e.trim()).toList();
    }
  }

  final String name = (clinic['name'] ?? '').toString().toLowerCase();
  if (name.contains('estét') || name.contains('estet') || name.contains('laser') || name.contains('lser') || name.contains('spa')) {
    return [
      "Soprano Titanium Diodo",
      "Láser CO2 Fraccionado Harmony",
      "Equipo Hydrafacial Elite",
      "Ultrasonido Focalizado HIFU"
    ];
  } else if (name.contains('derm') || name.contains('piel') || name.contains('clínic') || name.contains('clinic')) {
    return [
      "Dermatoscopio FotoFinder",
      "Sistema de Crioterapia CryoPen",
      "Cabina de Fototerapia UVB-NB",
      "Láser Nd:YAG Q-Switched"
    ];
  } else {
    return [
      "Microdermoabrasión Punta Diamante",
      "Centrifugadora Medilite PRP",
      "Dispositivo Dermapen 4 Profesional",
      "Cabina LED Fototerapéutica"
    ];
  }
}

class PatientMapView extends ConsumerStatefulWidget {
  const PatientMapView({super.key});

  @override
  ConsumerState<PatientMapView> createState() => _PatientMapViewState();
}

class _PatientMapViewState extends ConsumerState<PatientMapView> {
  late final MapController _mapController;

  // Estados Locales
  Map<String, dynamic>? _selectedClinic;
  String _selectedCategory = 'Todos';
  String _searchQuery = '';
  bool _isTracingRoute = false;

  // Centro Geográfico de Anclaje (Cabimas de referencia)
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

  // 🚀 LÓGICA DE NEGOCIO: Redirección nativa a Google Maps GPS real
  Future<void> _launchGoogleMaps(double lat, double lng, String name) async {
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se pudo abrir el mapa externo.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al abrir mapa GPS: $e"),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _triggerRouteTracing() {
    if (_selectedClinic == null) return;
    setState(() {
      _isTracingRoute = true;
    });

    final double lat = (_selectedClinic!['lat'] as num?)?.toDouble() ?? centerLat;
    final double lng = (_selectedClinic!['lng'] as num?)?.toDouble() ?? centerLng;

    // Ajustar vista para abarcar usuario y clínica
    final double boundsCenterLat = (centerLat + lat) / 2;
    final double boundsCenterLng = (centerLng + lng) / 2;
    _mapController.move(LatLng(boundsCenterLat, boundsCenterLng), 13.5);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("📍 Ruta clínica proyectada en el mapa. GPS Listo."),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final centersAsync = ref.watch(medicalCentersProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // 📡 CAPA 1: Capa de mapa real interactiva de OpenStreetMap
          Positioned.fill(
            child: centersAsync.when(
              data: (centers) {
                // 1. Filtrar localmente las clínicas aplicando lógica de búsqueda extendida
                final List<Map<String, dynamic>> filtered = centers.where((center) {
                  final String name = (center['name'] ?? '').toString().toLowerCase();
                  final String address = (center['address'] ?? '').toString().toLowerCase();
                  
                  // Tratamientos y Equipos de esta clínica
                  final List<String> treatments = _getClinicTreatments(center);
                  final List<String> equipment = _getClinicEquipment(center);
                  
                  final bool matchesSearch = _searchQuery.isEmpty || 
                      name.contains(_searchQuery) ||
                      address.contains(_searchQuery) ||
                      treatments.any((t) => t.toLowerCase().contains(_searchQuery)) ||
                      equipment.any((e) => e.toLowerCase().contains(_searchQuery));

                  if (_selectedCategory == 'Todos') return matchesSearch;
                  if (_selectedCategory == 'Dermatología') return matchesSearch && name.contains('derm');
                  if (_selectedCategory == 'Estética') return matchesSearch && (name.contains('estét') || name.contains('estet') || name.contains('laser') || name.contains('lser'));
                  if (_selectedCategory == 'Abiertos') return matchesSearch && (center['is_open'] == true);
                  return matchesSearch;
                }).toList();

                // 2. Mapear calculando distancias desde la ubicación del usuario (Cabimas)
                final List<Map<String, dynamic>> withDistance = filtered.map((center) {
                  final double lat = (center['lat'] as num?)?.toDouble() ?? centerLat;
                  final double lng = (center['lng'] as num?)?.toDouble() ?? centerLng;
                  final double dist = _calculateDistance(centerLat, centerLng, lat, lng);
                  
                  return {
                    ...center,
                    'distance_km': dist,
                  };
                }).toList();

                // 3. Ordenar de menor a mayor distancia (más cercana primero)
                withDistance.sort((a, b) => (a['distance_km'] as double).compareTo(b['distance_km'] as double));

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(centerLat, centerLng),
                    initialZoom: 13.5,
                    maxZoom: 18.0,
                    minZoom: 10.0,
                    onTap: (_, __) {
                      setState(() {
                        _selectedClinic = null;
                        _isTracingRoute = false;
                      });
                    },
                  ),
                  children: [
                    // Capa de mosaicos (OpenStreetMap)
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.testingcode.healskin',
                    ),
                    
                    // Línea de Ruta si está activa
                    if (_isTracingRoute && _selectedClinic != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [
                              LatLng(centerLat, centerLng),
                              LatLng(
                                (_selectedClinic!['lat'] as num?)?.toDouble() ?? centerLat,
                                (_selectedClinic!['lng'] as num?)?.toDouble() ?? centerLng,
                              ),
                            ],
                            color: AppColors.primary,
                            strokeWidth: 4.5,
                          ),
                        ],
                      ),

                    // Capa de Marcadores (Mi Ubicación y Clínicas)
                    MarkerLayer(
                      markers: [
                        // Marcador del Usuario
                        Marker(
                          point: LatLng(centerLat, centerLng),
                          width: 80,
                          height: 80,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.secondary, width: 2),
                                ),
                                child: const Icon(Icons.my_location, color: AppColors.secondary, size: 18),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                                ),
                                child: const Text(
                                  "Tú",
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Marcadores de Clínicas
                        ...withDistance.map((clinic) {
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
                                  _isTracingRoute = false;
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
                                      Icons.location_on_rounded,
                                      color: isSelected ? AppColors.primary : AppColors.secondary,
                                      size: isSelected ? 34 : 28,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                                        boxShadow: const [
                                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                                        ],
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
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text("Error al cargar clínicas: $err", style: const TextStyle(color: AppColors.danger))),
            ),
          ),

          // 🔍 CAPA 2: Buscador superior y Chips de Categorías
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: SafeArea(
              child: Column(
                children: [
                  // Barra de búsqueda premium
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: "Buscar clínicas, tratamientos o aparatología...",
                        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Chips de categoría
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['Todos', 'Dermatología', 'Estética', 'Abiertos'].map((category) {
                        final bool isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: Colors.white,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
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
          ),

          // 📇 CAPA 3: Tarjeta Detallada Flotante de Clínica Seleccionada
          if (_selectedClinic != null)
            Builder(builder: (context) {
              final double selLat = (_selectedClinic!['lat'] as num?)?.toDouble() ?? centerLat;
              final double selLng = (_selectedClinic!['lng'] as num?)?.toDouble() ?? centerLng;
              final double selDist = _calculateDistance(centerLat, centerLng, selLat, selLng);

              return Positioned(
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
                        // Encabezado Tarjeta
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
                                    _selectedClinic!['name'] ?? 'Clínica Asociada', 
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
                                  _isTracingRoute = false;
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

                        // Detalles Clínicos Rápidos
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildDetailChip(Icons.access_time, _selectedClinic!['status_text'] ?? 'Horario'),
                            _buildDetailChip(
                              Icons.navigation_outlined, 
                              "${selDist.toStringAsFixed(1)} km",
                              color: AppColors.secondary,
                            ),
                            _buildDetailChip(
                              Icons.star_border, 
                              (_selectedClinic!['is_open'] ?? false) ? "Abierto" : "Cerrado",
                              color: (_selectedClinic!['is_open'] ?? false) ? AppColors.success : AppColors.danger
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // 🩺 Sección: Tratamientos Disponibles
                        const Text(
                          "Tratamientos Destacados",
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            color: AppColors.textPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _getClinicTreatments(_selectedClinic!).take(3).map((treatment) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withOpacity(0.12)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, size: 10, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    treatment,
                                    style: const TextStyle(fontSize: 10.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),

                        // 🔬 Sección: Aparatología y Tecnología
                        const Text(
                          "Tecnología y Aparatología",
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            color: AppColors.textPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _getClinicEquipment(_selectedClinic!).take(3).map((equip) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.secondary.withOpacity(0.12)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.biotech, size: 10, color: AppColors.secondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    equip,
                                    style: const TextStyle(fontSize: 10.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // Acciones de Trazado de Ruta y GPS Real
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.alt_route, size: 20),
                                label: const Text("Trazar Ruta", style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: _triggerRouteTracing,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.directions, color: AppColors.secondary),
                                tooltip: "Abrir Google Maps",
                                onPressed: () {
                                  final double lat = (_selectedClinic!['lat'] as num?)?.toDouble() ?? 10.3932;
                                  final double lng = (_selectedClinic!['lng'] as num?)?.toDouble() ?? -71.4422;
                                  _launchGoogleMaps(lat, lng, _selectedClinic!['name'] ?? 'Clínica');
                                },
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, {Color color = AppColors.textSecondary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}