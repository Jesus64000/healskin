import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Provider del Perfil (Auto-refrescable)
final userProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return null;

  final response = await supabase
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();

  return response;
});

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

  return List<Map<String, dynamic>>.from(response);
});

// 4. Provider de la Línea de Tiempo / Evolución (Auto-refrescable)
final skinTimelineProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return [];

  final response = await supabase
      .from('skin_evolution')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});