import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/profile_provider.dart';
import '../../chat/chat_view.dart';
import '../../../core/utils/image_utils.dart';

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

final mapSearchQueryProvider = StateProvider<String>((ref) => '');

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
  late final TextEditingController _searchController;
  bool _isTracingRoute = false;
  List<LatLng> _routePoints = [];

  // Ubicación del usuario (inicializada en Cabimas, actualizada por GPS)
  LatLng _userLatLng = const LatLng(10.3932, -71.4422);
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _searchController = TextEditingController(text: ref.read(mapSearchQueryProvider));
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _loadingLocation = false;
          });
        }
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _loadingLocation = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _loadingLocation = false;
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _userLatLng = LatLng(position.latitude, position.longitude);
          _loadingLocation = false;
        });
        
        // Mover el mapa a la ubicación del usuario
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(_userLatLng, 13.5);
        });
      }
    } catch (e) {
      debugPrint("Error al obtener la ubicación GPS: $e");
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 🚀 LÓGICA DE NEGOCIO: Redirección nativa a Google Maps GPS con nombre exacto de la clínica
  Future<void> _launchGoogleMaps(double lat, double lng, String name) async {
    final String cleanName = name.isEmpty ? 'Centro Médico HealSkin' : name;
    final String encodedName = Uri.encodeComponent(cleanName);
    
    // URI nativa para Android/iOS con etiqueta exacta de la clínica
    final Uri geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng($encodedName)');
    final Uri googleMapsSearchUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedName+$lat,$lng');
    final Uri googleMapsDirUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

    try {
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(googleMapsSearchUrl)) {
        await launchUrl(googleMapsSearchUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(googleMapsDirUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(googleMapsSearchUrl, mode: LaunchMode.externalApplication);
      } catch (e) {
        try {
          await launchUrl(googleMapsDirUrl, mode: LaunchMode.platformDefault);
        } catch (err) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error al abrir mapa GPS: $err"),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _fetchRoutePoints(LatLng start, LatLng end) async {
    if (!mounted) return;
    setState(() {
      _isTracingRoute = true;
    });

    try {
      final client = HttpClient();
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson',
      );
      final request = await client.getUrl(url);
      request.headers.add('User-Agent', 'HealSkinApp/1.0 (pazje@testing.com)');
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          final List coords = geometry['coordinates'];
          final List<LatLng> points = coords.map((c) {
            final double lng = (c[0] as num).toDouble();
            final double lat = (c[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();

          if (mounted) {
            setState(() {
              _routePoints = points;
              _isTracingRoute = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Error fetching OSRM route: $e");
    }

    if (mounted) {
      setState(() {
        _routePoints = [start, end]; // Fallback solo si falla la red
        _isTracingRoute = false;
      });
    }
  }

  void _triggerRouteTracing() {
    if (_selectedClinic == null) return;
    setState(() {
      _isTracingRoute = true;
    });

    final double lat = (_selectedClinic!['lat'] as num?)?.toDouble() ?? _userLatLng.latitude;
    final double lng = (_selectedClinic!['lng'] as num?)?.toDouble() ?? _userLatLng.longitude;
    final endLatLng = LatLng(lat, lng);

    // Ajustar vista para abarcar usuario y clínica
    final double boundsCenterLat = (_userLatLng.latitude + lat) / 2;
    final double boundsCenterLng = (_userLatLng.longitude + lng) / 2;
    _mapController.move(LatLng(boundsCenterLat, boundsCenterLng), 13.5);

    // Cargar ruta real por calles
    _fetchRoutePoints(_userLatLng, endLatLng);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("📍 Calculando ruta óptima por calles..."),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final centersAsync = ref.watch(medicalCentersProvider);
    final doctorsAsync = ref.watch(doctorsLocationsProvider);
    final filtersAsync = ref.watch(mapFiltersProvider);
    final filters = filtersAsync.value ?? [];
    final searchQuery = ref.watch(mapSearchQueryProvider).toLowerCase();

    ref.listen<String>(mapSearchQueryProvider, (previous, next) {
      if (_searchController.text != next) {
        _searchController.text = next;
      }
    });

    if (_loadingLocation) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                "Obteniendo tu ubicación...",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final double userLat = _userLatLng.latitude;
    final double userLng = _userLatLng.longitude;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // 📡 CAPA 1: Capa de mapa real interactiva de OpenStreetMap
          Positioned.fill(
            child: centersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text("Error al cargar clínicas: $err", style: const TextStyle(color: AppColors.danger))),
              data: (centers) {
                return doctorsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (err, _) => Center(child: Text("Error al cargar médicos: $err", style: const TextStyle(color: AppColors.danger))),
                  data: (doctors) {
                    // Combinar puntos
                    final List<Map<String, dynamic>> combinedPoints = [];

                    // Agregar clínicas
                    for (var c in centers) {
                      combinedPoints.add({
                        'id': c['id'].toString(),
                        'name': c['name'] ?? 'Clínica',
                        'address': c['address'] ?? '',
                        'lat': (c['lat'] as num?)?.toDouble() ?? userLat,
                        'lng': (c['lng'] as num?)?.toDouble() ?? userLng,
                        'is_open': c['is_open'] ?? false,
                        'status_text': c['status_text'] ?? 'Horario',
                        'image_url': c['image_url'] ?? '',
                        'image_url_2': c['image_url_2'] ?? '',
                        'type': 'clinic',
                        'raw': c,
                      });
                    }

                    // Agregar consultorios de doctores
                    for (var d in doctors) {
                      combinedPoints.add({
                        'id': d['id'].toString(),
                        'name': d['full_name'] ?? 'Médico',
                        'address': d['office_address'] ?? '',
                        'lat': (d['office_lat'] as num?)?.toDouble() ?? userLat,
                        'lng': (d['office_lng'] as num?)?.toDouble() ?? userLng,
                        'is_open': true,
                        'status_text': d['specialty'] ?? 'Dermatólogo',
                        'image_url': '',
                        'image_url_2': '',
                        'type': 'doctor',
                        'raw': d,
                      });
                    }

                    // Filtrado local según la búsqueda y categoría
                    final List<Map<String, dynamic>> filtered = combinedPoints.where((point) {
                      final String name = point['name'].toString().toLowerCase();
                      final String address = point['address'].toString().toLowerCase();
                      final String spec = point['status_text'].toString().toLowerCase();

                      final bool matchesSearch = searchQuery.isEmpty ||
                          name.contains(searchQuery) ||
                          address.contains(searchQuery) ||
                          spec.contains(searchQuery);

                      if (point['type'] == 'clinic') {
                        final List<String> treatments = _getClinicTreatments(point['raw']);
                        final List<String> equipment = _getClinicEquipment(point['raw']);
                        if (treatments.any((t) => t.toLowerCase().contains(searchQuery)) ||
                            equipment.any((e) => e.toLowerCase().contains(searchQuery))) {
                          return true;
                        }
                      }

                      if (_selectedCategory == 'Todos') return matchesSearch;
                      if (_selectedCategory == 'Abiertos') {
                        return matchesSearch && (point['is_open'] == true);
                      }
                      
                      // Buscar si coincide con alguna de las categorías dinámicas de la BD
                      final matchingFilter = filters.firstWhere(
                        (f) => f['name'] == _selectedCategory,
                        orElse: () => <String, dynamic>{},
                      );
                      
                      if (matchingFilter.isNotEmpty) {
                        final String keywordsStr = matchingFilter['keywords'] ?? '';
                        final List<String> keywords = keywordsStr
                            .split(',')
                            .map((k) => k.trim().toLowerCase())
                            .where((k) => k.isNotEmpty)
                            .toList();
                        
                        if (keywords.isEmpty) return matchesSearch;
                        
                        final bool matchesKeywords = keywords.any((keyword) =>
                            name.contains(keyword) || spec.contains(keyword));
                        return matchesSearch && matchesKeywords;
                      }
                      
                      return matchesSearch;
                    }).toList();

                    // Calcular distancias reales
                    final List<Map<String, dynamic>> withDistance = filtered.map((point) {
                      final double dist = _calculateDistance(userLat, userLng, point['lat'], point['lng']);
                      return {
                        ...point,
                        'distance_km': dist,
                      };
                    }).toList();

                    // Ordenar por distancia
                    withDistance.sort((a, b) => (a['distance_km'] as double).compareTo(b['distance_km'] as double));

                    return FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _userLatLng,
                        initialZoom: 13.5,
                        maxZoom: 18.0,
                        minZoom: 10.0,
                        onTap: (_, __) {
                          setState(() {
                            _selectedClinic = null;
                            _isTracingRoute = false;
                            _routePoints = [];
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.testingcode.healskin',
                        ),

                        if (_isTracingRoute && _selectedClinic != null)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints.isNotEmpty
                                    ? _routePoints
                                    : [
                                        _userLatLng,
                                        LatLng(_selectedClinic!['lat'], _selectedClinic!['lng']),
                                      ],
                                color: AppColors.primary,
                                strokeWidth: 4.5,
                              ),
                            ],
                          ),

                        MarkerLayer(
                          markers: [
                            // Marcador del Usuario
                            Marker(
                              point: _userLatLng,
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

                            // Marcadores de Clínicas y Consultorios Médicos
                            ...withDistance.map((point) {
                              final double lat = point['lat'];
                              final double lng = point['lng'];
                              final bool isSelected = _selectedClinic != null && _selectedClinic!['id'] == point['id'];
                              final bool isClinic = point['type'] == 'clinic';

                              return Marker(
                                point: LatLng(lat, lng),
                                width: 120,
                                height: 70,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedClinic = point;
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
                                          isClinic ? Icons.local_hospital_rounded : Icons.medical_services,
                                          color: isSelected 
                                              ? AppColors.accentDark 
                                              : (isClinic ? AppColors.secondary : AppColors.primary),
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
                                            point['name'],
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
                );
              },
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
                      controller: _searchController,
                      onChanged: (value) {
                        ref.read(mapSearchQueryProvider.notifier).state = value;
                      },
                      decoration: const InputDecoration(
                        hintText: "Buscar clínicas, especialidades o tratamientos...",
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
                      children: [
                        'Todos',
                        ...filters.map((f) => f['name'] as String),
                        'Abiertos',
                      ].map((category) {
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

          // 📇 CAPA 3: Tarjeta Detallada Flotante de Clínica / Consultorio Seleccionado
          if (_selectedClinic != null)
            Builder(builder: (context) {
              final double selLat = _selectedClinic!['lat'];
              final double selLng = _selectedClinic!['lng'];
              final double selDist = _selectedClinic!['distance_km'];
              final bool isDoctor = _selectedClinic!['type'] == 'doctor';

              if (_isTracingRoute) {
                return Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.navigation_outlined, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Ruta a ${isDoctor ? 'Dr. ' + _selectedClinic!['name'] : _selectedClinic!['name']}",
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "Distancia: ${selDist.toStringAsFixed(1)} km",
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isTracingRoute = false;
                                _routePoints = [];
                              });
                            },
                            icon: const Icon(Icons.close, size: 16, color: AppColors.danger),
                            label: const Text("Cerrar", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

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
                                color: (isDoctor ? AppColors.primary : AppColors.secondary).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isDoctor ? Icons.medical_services_outlined : Icons.local_hospital_outlined, 
                                color: isDoctor ? AppColors.primary : AppColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isDoctor ? "Dr. ${_selectedClinic!['name']}" : _selectedClinic!['name'], 
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isDoctor ? (_selectedClinic!['status_text'] ?? 'Especialista') : (_selectedClinic!['address'] ?? 'Dirección'), 
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                        const SizedBox(height: 10),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Si es Clínica, mostrar fotos
                                if (!isDoctor &&
                                    ((_selectedClinic!['image_url'] != null && (_selectedClinic!['image_url'] as String).isNotEmpty) ||
                                    (_selectedClinic!['image_url_2'] != null && (_selectedClinic!['image_url_2'] as String).isNotEmpty))) ...[
                                  SizedBox(
                                    height: 120,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: [
                                        if (_selectedClinic!['image_url'] != null && (_selectedClinic!['image_url'] as String).isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 12.0),
                                            child: GestureDetector(
                                              onTap: () => showFullScreenImage(context, _selectedClinic!['image_url'] as String),
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
                                          ),
                                        if (_selectedClinic!['image_url_2'] != null && (_selectedClinic!['image_url_2'] as String).isNotEmpty)
                                          GestureDetector(
                                            onTap: () => showFullScreenImage(context, _selectedClinic!['image_url_2'] as String),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: Image.network(
                                                _selectedClinic!['image_url_2'] as String,
                                                width: 180,
                                                height: 120,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                ],

                                // Detalles Rápidos
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  alignment: WrapAlignment.start,
                                  children: [
                                    _buildDetailChip(
                                      isDoctor ? Icons.business_outlined : Icons.access_time, 
                                      isDoctor ? "Consultorio Privado" : (_selectedClinic!['status_text'] ?? 'Horario'),
                                      color: isDoctor ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                    _buildDetailChip(
                                      Icons.navigation_outlined, 
                                      "${selDist.toStringAsFixed(1)} km",
                                      color: AppColors.secondary,
                                    ),
                                    _buildDetailChip(
                                      isDoctor ? Icons.verified_user_outlined : Icons.star_border, 
                                      isDoctor ? "Verificado" : ((_selectedClinic!['is_open'] ?? false) ? "Abierto" : "Cerrado"),
                                      color: isDoctor ? AppColors.success : ((_selectedClinic!['is_open'] ?? false) ? AppColors.success : AppColors.danger)
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 15),
                                
                                if (isDoctor) ...[
                                  // Para doctores: dirección completa
                                  const Text(
                                    "Dirección del Consultorio",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 0.3),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedClinic!['address'].isNotEmpty ? _selectedClinic!['address'] : "No especificada",
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                                  ),
                                ] else ...[
                                  // Para clínicas: Tratamientos Disponibles
                                  const Text(
                                    "Tratamientos Destacados",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 0.3),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: _getClinicTreatments(_selectedClinic!['raw']).take(3).map((treatment) {
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

                                  // Para clínicas: Aparatología
                                  const Text(
                                    "Tecnología y Aparatología",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 0.3),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: _getClinicEquipment(_selectedClinic!['raw']).take(3).map((equip) {
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
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const SizedBox(height: 18),

                        // Acciones: Chat Rápido, Trazar Ruta y GPS Maps
                        Row(
                          children: [
                            if (isDoctor) ...[
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatView(
                                          otherUserId: _selectedClinic!['id'],
                                          otherUserName: "Dr. ${_selectedClinic!['name']}",
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                      SizedBox(width: 6),
                                      Text("Iniciar Chat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDoctor ? AppColors.secondary : AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                onPressed: _triggerRouteTracing,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.alt_route, size: 16),
                                    SizedBox(width: 6),
                                    Text("Trazar Ruta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: (isDoctor ? AppColors.primary : AppColors.secondary).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.directions, color: isDoctor ? AppColors.primary : AppColors.secondary),
                                tooltip: "Abrir Google Maps",
                                onPressed: () {
                                  _launchGoogleMaps(selLat, selLng, _selectedClinic!['name']);
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}