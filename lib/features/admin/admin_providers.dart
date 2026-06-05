import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../auth/profile_provider.dart';

// 1. MÉTRICAS GLOBALES
final adminMetricsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final supabase = Supabase.instance.client;
  final patientsRes = await supabase.from('profiles').select('id').eq('role', 'patient').count(CountOption.exact);
  final doctorsRes = await supabase.from('profiles').select('id').eq('role', 'doctor').count(CountOption.exact);

  return {
    'patients': patientsRes.count ?? 0,
    'doctors': doctorsRes.count ?? 0,
  };
});

// 2. MÉDICOS PENDIENTES
final pendingDoctorsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('profiles')
      .select()
      .eq('role', 'doctor')
      .eq('is_approved', false)
      .order('created_at', ascending: false);
  return response;
});

// 3. ESCANEOS RECIENTES
final recentScansProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('ai_scans')
      .select('*, profiles(full_name)')
      .order('created_at', ascending: false)
      .limit(10);
  return response;
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
      ref.invalidate(adminMetricsProvider);
    } catch (e) {
      throw Exception("Error al aprobar médico: $e");
    }
  }

  Future<void> rejectDoctor(String doctorId) async {
    try {
      await supabase.from('profiles').delete().eq('id', doctorId);
      ref.invalidate(pendingDoctorsProvider);
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
        'is_open': isOpen,
        'lat': lat,
        'lng': lng,
        'image_url': imageUrl1,
        'image_url_2': imageUrl2,
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
        'is_open': isOpen,
        'lat': lat,
        'lng': lng,
        'image_url': imageUrl1,
        'image_url_2': imageUrl2,
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
}