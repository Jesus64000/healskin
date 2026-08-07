import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../auth/profile_provider.dart';

// 1. MÉTRICAS GLOBALES
final adminMetricsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final patients = await ref.watch(adminUserListProvider('patient').future);
  final doctors = await ref.watch(adminUserListProvider('doctor').future);

  return {
    'patients': patients.length,
    'doctors': doctors.length,
  };
});

// 2. MÉDICOS PENDIENTES
final pendingDoctorsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final prefs = await SharedPreferences.getInstance();
  final List<String> deletedIds = prefs.getStringList('healskin_deleted_user_ids') ?? [];

  final response = await supabase
      .from('profiles')
      .select()
      .eq('role', 'doctor')
      .eq('is_approved', false)
      .order('created_at', ascending: false);

  final list = List<Map<String, dynamic>>.from(response);
  return list.where((d) => !deletedIds.contains(d['id'])).toList();
});

// 3. ESCANEOS RECIENTES
final recentScansProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final allScans = await ref.watch(allScansProvider.future);
  return allScans.take(5).toList();
});

// 3.1. TODOS LOS ESCANEOS
final allScansProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final List<Map<String, dynamic>> result = [];
  
  // 1. Obtener escaneos de ai_scans
  try {
    final response = await supabase
        .from('ai_scans')
        .select('*, profiles:patient_id(full_name)')
        .order('created_at', ascending: false);
    for (final item in response) {
      result.add(Map<String, dynamic>.from(item));
    }
  } catch (e) {
    // Si la relación guardada falla, traemos escaneos directos
    try {
      final rawScans = await supabase
          .from('ai_scans')
          .select()
          .order('created_at', ascending: false);
      for (final item in rawScans) {
        final Map<String, dynamic> scan = Map<String, dynamic>.from(item);
        if (scan['patient_id'] != null) {
          try {
            final prof = await supabase.from('profiles').select('full_name').eq('id', scan['patient_id']).maybeSingle();
            if (prof != null) scan['profiles'] = prof;
          } catch (_) {}
        }
        result.add(scan);
      }
    } catch (_) {}
  }

  // 2. Obtener escaneos de skin_evolution como respaldo
  try {
    final evols = await supabase
        .from('skin_evolution')
        .select()
        .order('created_at', ascending: false);
    for (final item in evols) {
      final String image = item['image_url'] ?? '';
      if (image.isNotEmpty && !result.any((r) => r['image_url'] == image)) {
        Map<String, dynamic>? profileMap;
        final userId = item['user_id'];
        if (userId != null) {
          try {
            final p = await supabase.from('profiles').select('full_name').eq('id', userId).maybeSingle();
            if (p != null) profileMap = Map<String, dynamic>.from(p);
          } catch (_) {}
        }
        result.add({
          'id': item['id'],
          'patient_id': item['user_id'],
          'ai_diagnosis': item['title'] ?? 'Análisis IA',
          'recommendation': item['description'] ?? 'Evolución registrada.',
          'risk_level': item['event_type'] == 'warning' ? 'high' : 'low',
          'image_url': image,
          'created_at': item['created_at'],
          'profiles': profileMap,
        });
      }
    }
  } catch (e) {
    debugPrint("Error fetching skin_evolution scans: $e");
  }

  result.sort((a, b) {
    final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
    final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
    return dateB.compareTo(dateA);
  });

  return result;
});


// 3.5. LISTA DE USUARIOS POR ROL (ADMIN)
final adminUserListProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, role) async {
  final supabase = Supabase.instance.client;
  final prefs = await SharedPreferences.getInstance();
  final List<String> deletedIds = prefs.getStringList('healskin_deleted_user_ids') ?? [];

  final response = await supabase
      .from('profiles')
      .select()
      .eq('role', role)
      .order('full_name', ascending: true);

  final list = List<Map<String, dynamic>>.from(response);
  return list.where((u) {
    final String uId = u['id'] ?? '';
    final bool isActive = u['is_active'] ?? true;
    final String uRole = u['role'] ?? '';
    final String name = u['full_name'] ?? '';
    return !deletedIds.contains(uId) && isActive && uRole == role && !name.contains('[Usuario Eliminado]') && !name.contains('[Médico Rechazado]');
  }).toList();
});

// 4. CONTROLADOR GENERAL DE ADMIN
final adminControllerProvider = Provider((ref) => AdminController(ref));

class AdminController {
  final Ref ref;
  AdminController(this.ref);

  final supabase = Supabase.instance.client;

  // --- MÓDULO DE DOCTORES ---
  Future<void> approveDoctor(String doctorId) async {
    try {
      await supabase.from('profiles').update({'is_approved': true}).eq('id', doctorId);
      ref.invalidate(pendingDoctorsProvider);
      ref.invalidate(adminUserListProvider('doctor'));
      ref.invalidate(adminMetricsProvider);
    } catch (e) {
      throw Exception("Error al aprobar médico: $e");
    }
  }

  Future<void> rejectDoctor(String doctorId) async {
    try {
      try {
        await supabase.from('profiles').update({
          'role': 'deleted',
          'is_active': false,
          'is_approved': false,
          'full_name': '[Médico Rechazado]',
        }).eq('id', doctorId);
      } catch (_) {}

      try {
        await supabase.from('profiles').delete().eq('id', doctorId);
      } catch (_) {}

      ref.invalidate(pendingDoctorsProvider);
      ref.invalidate(adminUserListProvider('doctor'));
      ref.invalidate(adminMetricsProvider);
    } catch (e) {
      throw Exception("Error al rechazar médico: $e");
    }
  }

  // --- MÓDULO DE ARTÍCULOS (NUEVO) 🚀 ---
  Future<void> publishArticle({
    required String title,
    required String content,
    required String category,
    required File coverImage,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("Sesión inválida");

      // 1. Subir imagen al bucket
      final fileExtension = coverImage.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$fileExtension';
      final storagePath = '${user.id}/$fileName';

      await supabase.storage.from('scan_images').upload(storagePath, coverImage);
      final imageUrl = supabase.storage.from('scan_images').getPublicUrl(storagePath);

      // 2. Guardar en base de datos
      await supabase.from('articles').insert({
        'title': title,
        'content': content,
        'category': category,
        'image_url': imageUrl,
        'author_id': user.id,
      });

    } catch (e) {
      throw Exception("Error al publicar artículo: $e");
    }
  }

  Future<void> deleteArticle(String articleId) async {
    try {
      await supabase.from('articles').delete().eq('id', articleId);
      ref.invalidate(articlesProvider);
    } catch (e) {
      throw Exception("Error al eliminar artículo: $e");
    }
  }

  Future<void> updateArticle({
    required String articleId,
    required String title,
    required String content,
    required String category,
    File? coverImage,
    String? existingImageUrl,
  }) async {
    try {
      String imageUrl = existingImageUrl ?? '';

      // Si se seleccionó una nueva imagen de portada, la subimos
      if (coverImage != null) {
        final user = supabase.auth.currentUser;
        if (user == null) throw Exception("Sesión inválida");

        final fileExtension = coverImage.path.split('.').last;
        final fileName = '${const Uuid().v4()}.$fileExtension';
        final storagePath = '${user.id}/$fileName';

        await supabase.storage.from('scan_images').upload(storagePath, coverImage);
        imageUrl = supabase.storage.from('scan_images').getPublicUrl(storagePath);
      }

      await supabase.from('articles').update({
        'title': title,
        'content': content,
        'category': category,
        'image_url': imageUrl,
      }).eq('id', articleId);

      ref.invalidate(articlesProvider);
    } catch (e) {
      throw Exception("Error al actualizar artículo: $e");
    }
  }

  // --- MÓDULO DE CLÍNICAS (NUEVO) 🏥 ---
  Future<void> addMedicalCenter({
    required String name,
    required String address,
    required String statusText,
    required bool isOpen,
    required double lat,
    required double lng,
    File? imageFile1,
    File? imageFile2,
  }) async {
    try {
      String? imageUrl1;
      String? imageUrl2;

      final user = supabase.auth.currentUser;
      if (user != null) {
        if (imageFile1 != null) {
          final fileExtension = imageFile1.path.split('.').last;
          final fileName = 'clinic_1_${const Uuid().v4()}.$fileExtension';
          final storagePath = 'clinics/$fileName';
          await supabase.storage.from('scan_images').upload(storagePath, imageFile1);
          imageUrl1 = supabase.storage.from('scan_images').getPublicUrl(storagePath);
        }
        if (imageFile2 != null) {
          final fileExtension = imageFile2.path.split('.').last;
          final fileName = 'clinic_2_${const Uuid().v4()}.$fileExtension';
          final storagePath = 'clinics/$fileName';
          await supabase.storage.from('scan_images').upload(storagePath, imageFile2);
          imageUrl2 = supabase.storage.from('scan_images').getPublicUrl(storagePath);
        }
      }

      await supabase.from('medical_centers').insert({
        'name': name,
        'address': address,
        'status_text': statusText,
        'latitude': lat,
        'longitude': lng,
        if (imageUrl1 != null) ...{'image_url_1': imageUrl1},
        if (imageUrl2 != null) ...{'image_url_2': imageUrl2},
      });
      ref.invalidate(medicalCentersProvider);
    } catch (e) {
      throw Exception("Error al agregar centro médico: $e");
    }
  }

  Future<void> updateMedicalCenter({
    required String centerId,
    required String name,
    required String address,
    required String statusText,
    required bool isOpen,
    required double lat,
    required double lng,
    File? imageFile1,
    File? imageFile2,
    String? existingImageUrl1,
    String? existingImageUrl2,
  }) async {
    try {
      String? imageUrl1 = existingImageUrl1;
      String? imageUrl2 = existingImageUrl2;

      final user = supabase.auth.currentUser;
      if (user != null) {
        if (imageFile1 != null) {
          final fileExtension = imageFile1.path.split('.').last;
          final fileName = 'clinic_1_${const Uuid().v4()}.$fileExtension';
          final storagePath = 'clinics/$fileName';
          await supabase.storage.from('scan_images').upload(storagePath, imageFile1);
          imageUrl1 = supabase.storage.from('scan_images').getPublicUrl(storagePath);
        }
        if (imageFile2 != null) {
          final fileExtension = imageFile2.path.split('.').last;
          final fileName = 'clinic_2_${const Uuid().v4()}.$fileExtension';
          final storagePath = 'clinics/$fileName';
          await supabase.storage.from('scan_images').upload(storagePath, imageFile2);
          imageUrl2 = supabase.storage.from('scan_images').getPublicUrl(storagePath);
        }
      }

      await supabase.from('medical_centers').update({
        'name': name,
        'address': address,
        'status_text': statusText,
        'latitude': lat,
        'longitude': lng,
        if (imageUrl1 != null) ...{'image_url_1': imageUrl1},
        if (imageUrl2 != null) ...{'image_url_2': imageUrl2},
      }).eq('id', centerId);
      ref.invalidate(medicalCentersProvider);
    } catch (e) {
      throw Exception("Error al actualizar centro médico: $e");
    }
  }

  Future<void> deleteMedicalCenter(String centerId) async {
    try {
      await supabase.from('medical_centers').delete().eq('id', centerId);
      ref.invalidate(medicalCentersProvider);
    } catch (e) {
      throw Exception("Error al eliminar centro médico: $e");
    }
  }

  // --- GESTIÓN DE FILTROS DEL MAPA ---
  Future<void> addMapFilter(String name, String keywords) async {
    try {
      await supabase.from('map_filters').insert({
        'name': name,
        'keywords': keywords,
      });
      // Importante: invalidamos el mapFiltersProvider para refrescar la UI
      ref.invalidate(mapFiltersProvider);
    } catch (e) {
      throw Exception("Error al agregar filtro: $e");
    }
  }

  Future<void> updateMapFilter({
    required String filterId,
    required String name,
    required String keywords,
  }) async {
    try {
      await supabase.from('map_filters').update({
        'name': name,
        'keywords': keywords,
      }).eq('id', filterId);
      ref.invalidate(mapFiltersProvider);
    } catch (e) {
      throw Exception("Error al actualizar filtro: $e");
    }
  }

  Future<void> deleteMapFilter(String filterId) async {
    try {
      await supabase.from('map_filters').delete().eq('id', filterId);
      ref.invalidate(mapFiltersProvider);
    } catch (e) {
      throw Exception("Error al eliminar filtro: $e");
    }
  }

  Future<void> deleteUser(String userId, String role) async {
    try {
      // 1. Invocar RPC en Supabase para borrado físico de auth.users y profiles
      try {
        await supabase.rpc('delete_user_by_admin', params: {'target_user_id': userId});
      } catch (e) {
        debugPrint("RPC delete_user_by_admin notice/fallback: $e");
      }

      // 2. Limpieza de registros dependientes por respaldo
      try { await supabase.from('ai_scans').delete().eq('patient_id', userId); } catch (_) {}
      try { await supabase.from('skin_evolution').delete().eq('user_id', userId); } catch (_) {}
      try { await supabase.from('appointments').delete().or('patient_id.eq.$userId,doctor_id.eq.$userId'); } catch (_) {}
      try { await supabase.from('medical_notes').delete().or('patient_id.eq.$userId,doctor_id.eq.$userId'); } catch (_) {}
      try { await supabase.from('direct_messages').delete().or('sender_id.eq.$userId,receiver_id.eq.$userId'); } catch (_) {}
      try { await supabase.from('chat_messages').delete().or('sender_id.eq.$userId,receiver_id.eq.$userId'); } catch (_) {}
      try { await supabase.from('patient_procedures').delete().eq('patient_id', userId); } catch (_) {}
      try { await supabase.from('profiles').delete().eq('id', userId); } catch (_) {}

      // 3. Guardar en lista local de filtrado para actualización inmediata
      final prefs = await SharedPreferences.getInstance();
      final List<String> deletedIds = prefs.getStringList('healskin_deleted_user_ids') ?? [];
      if (!deletedIds.contains(userId)) {
        deletedIds.add(userId);
        await prefs.setStringList('healskin_deleted_user_ids', deletedIds);
      }

      // 4. Invalidar todos los listados para actualizar la pantalla al instante
      ref.invalidate(adminUserListProvider('patient'));
      ref.invalidate(adminUserListProvider('doctor'));
      ref.invalidate(pendingDoctorsProvider);
      ref.invalidate(adminMetricsProvider);
    } catch (e) {
      throw Exception("Error al eliminar usuario: $e");
    }
  }
}