import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🚀 CLASE NOTIFIER PARA MANEJAR CACHÉ LOCAL Y ACTUALIZACIÓN EN SEGUNDO PLANO
class UserProfileNotifier extends AutoDisposeAsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    // 1. Intentamos recuperar los datos instantáneamente de caché local
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_profile_${user.id}');
      if (cachedStr != null) {
        final cachedData = jsonDecode(cachedStr) as Map<String, dynamic>;
        
        // Disparamos fetch asíncrono silencioso en segundo plano para refrescar la BD
        _fetchAndCacheProfile(user.id);
        
        // Devolvemos la caché al UI de forma INMEDIATA
        return cachedData;
      }
    } catch (e) {
      debugPrint("⚠️ Error al leer caché local de perfil: $e");
    }

    // 2. Si no hay caché, hacemos un fetch bloqueante normal
    return await _fetchAndCacheProfile(user.id);
  }

  Future<Map<String, dynamic>?> _fetchAndCacheProfile(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_profile_$userId', jsonEncode(response));
        
        // Notificamos reactivamente al UI con los datos actualizados
        state = AsyncData(response);
      }
      return response;
    } catch (e, stack) {
      // Robustez Offline: Si ya teníamos caché, ignoramos el fallo y mantenemos los datos locales
      if (state.hasValue && state.value != null) {
        debugPrint("⚠️ Conexión lenta/offline. Manteniendo datos locales del perfil. Error: $e");
        return state.value;
      }
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  // Permite invalidar y borrar la caché en el Logout
  Future<void> clearCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_profile_$userId');
    } catch (e) {
      debugPrint("Error al limpiar caché de perfil: $e");
    }
  }
}

// 1. Provider del Perfil (Offline-First, Auto-refrescable)
final userProfileProvider = AsyncNotifierProvider.autoDispose<UserProfileNotifier, Map<String, dynamic>?>(
  UserProfileNotifier.new,
);

// 2. Provider de Doctores (Auto-refrescable)
final doctorsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('doctors')
      .select()
      .order('full_name', ascending: true);

  return List<Map<String, dynamic>>.from(response);
});

// 3. Provider de Centros Médicos (Auto-refrescable)
final medicalCentersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('medical_centers')
      .select()
      .order('name', ascending: true);

  final list = List<Map<String, dynamic>>.from(response);
  return list.map((item) {
    final mapped = Map<String, dynamic>.from(item);
    mapped['lat'] = (mapped['latitude'] as num?)?.toDouble();
    mapped['lng'] = (mapped['longitude'] as num?)?.toDouble();
    mapped['status_text'] = mapped['status_text'] ?? '';
    mapped['is_open'] = true;
    return mapped;
  }).toList();
});

// 3.5. Provider de Filtros del Mapa (con fallback tolerante a fallos si la tabla no existe)
final mapFiltersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  try {
    final response = await supabase
        .from('map_filters')
        .select()
        .order('name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    debugPrint("⚠️ Tabla map_filters no encontrada o error: $e. Usando filtros por defecto.");
    return [
      {'id': 'default-derm', 'name': 'Dermatología', 'keywords': 'derm'},
      {'id': 'default-estet', 'name': 'Estética', 'keywords': 'estét, estet, laser'},
    ];
  }
});

// 🚀 CLASE NOTIFIER PARA LA LÍNEA DE TIEMPO CON CACHÉ LOCAL
class SkinTimelineNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    // 1. Intentamos leer la caché local instantáneamente
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_timeline_${user.id}');
      if (cachedStr != null) {
        final List<dynamic> decoded = jsonDecode(cachedStr);
        final List<Map<String, dynamic>> cachedTimeline = decoded
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        // Disparamos sincronización asíncrona silenciosa de fondo
        _fetchAndCacheTimeline(user.id);

        // Devolvemos los datos de caché de inmediato
        return cachedTimeline;
      }
    } catch (e) {
      debugPrint("⚠️ Error al leer caché local de evolución: $e");
    }

    // 2. Si no hay caché, hacemos fetch directo de la BD
    return await _fetchAndCacheTimeline(user.id);
  }

  Future<List<Map<String, dynamic>>> _fetchAndCacheTimeline(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('skin_evolution')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> timelineList = List<Map<String, dynamic>>.from(response);

      // Guardamos en la caché local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_timeline_$userId', jsonEncode(timelineList));

      // Actualizamos reactivamente el estado de la UI
      state = AsyncData(timelineList);
      return timelineList;
    } catch (e, stack) {
      // Robustez Offline: Si ya teníamos datos, los mantenemos y evitamos pantallas de error
      if (state.hasValue && state.value != null && state.value!.isNotEmpty) {
        debugPrint("⚠️ Conexión lenta/offline. Manteniendo datos locales del historial dérmico. Error: $e");
        return state.value!;
      }
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}

// 4. Provider de la Línea de Tiempo / Evolución (Offline-First, Auto-refrescable)
final skinTimelineProvider = AsyncNotifierProvider.autoDispose<SkinTimelineNotifier, List<Map<String, dynamic>>>(
  SkinTimelineNotifier.new,
);

// 5. NUEVO: Provider de Artículos (Dermotips del Admin)
final articlesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('articles')
      .select()
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

// 🚀 PROVEEDOR PARA EL DETALLE DEL DOCTOR (Lazy Loading)
final doctorDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, doctorId) async {
  final supabase = Supabase.instance.client;

  // Buscamos el perfil completo del doctor por su ID
  final response = await supabase
      .from('profiles')
      .select()
      .eq('id', doctorId)
      .single();

  return response;
});

// 🗺️ PROVEEDOR DE UBICACIONES DE DOCTORES (FILTRADO POR COORDENADAS)
final doctorsLocationsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final currentUser = supabase.auth.currentUser;
  var query = supabase
      .from('profiles')
      .select('id, full_name, specialty, office_address, office_lat, office_lng')
      .eq('role', 'doctor')
      .not('office_lat', 'is', null)
      .not('office_lng', 'is', null);

  if (currentUser != null) {
    query = query.neq('id', currentUser.id);
  }

  final response = await query;
  return List<Map<String, dynamic>>.from(response as List);
});

Map<String, String> parseArticleCategory(String? categoryCombined) {
  final category = categoryCombined ?? '';
  if (category.contains('|')) {
    final parts = category.split('|');
    if (parts.length >= 3) {
      return {
        'type': parts[0].trim(),
        'skinType': parts[1].trim(),
        'name': parts[2].trim(),
      };
    }
  }
  if (category.contains(' - ')) {
    final parts = category.split(' - ');
    return {
      'type': 'Recomendación',
      'skinType': parts[0].trim(),
      'name': parts[1].trim(),
    };
  }
  return {
    'type': 'Recomendación',
    'skinType': 'todos',
    'name': category,
  };
}

String formatFrequencyDays(int days) {
  if (days <= 0) return "Una sola vez";
  if (days % 365 == 0) {
    final years = days ~/ 365;
    return years == 1 ? "Cada año" : "Cada $years años";
  }
  if (days % 30 == 0) {
    final months = days ~/ 30;
    return months == 1 ? "Cada mes" : "Cada $months meses";
  }
  if (days % 7 == 0) {
    final weeks = days ~/ 7;
    return weeks == 1 ? "Cada semana" : "Cada $weeks semanas";
  }
  return days == 1 ? "Cada día" : "Cada $days días";
}


