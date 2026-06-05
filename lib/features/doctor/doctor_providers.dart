import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. PROVIDER: AGENDA DEL DÍA (Citas)
final todayAppointmentsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final doctorId = supabase.auth.currentUser?.id;

  if (doctorId == null) throw Exception("No autenticado");

  // Buscamos citas de este doctor, ordenadas por fecha.
  // Traemos también el nombre y avatar del paciente haciendo un JOIN implícito de Supabase
  final response = await supabase
      .from('appointments')
      .select('*, patient:profiles!patient_id(full_name, avatar_url)')
      .eq('doctor_id', doctorId)
  // Para el MVP, traemos todas las pendientes o confirmadas (luego filtramos por fecha exacta)
      .inFilter('status', ['pending', 'confirmed'])
      .order('scheduled_at', ascending: true);

  return response;
});

// 2. PROVIDER: MIS PACIENTES (Lista general filtrada con privacidad)
final myPatientsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final doctorId = supabase.auth.currentUser?.id;

  if (doctorId == null) throw Exception("No autenticado");

  // 🔒 PRIVACIDAD: Obtener patient_ids asociados a las citas de este doctor
  final appointmentsResponse = await supabase
      .from('appointments')
      .select('patient_id')
      .eq('doctor_id', doctorId);

  final List<dynamic> appts = appointmentsResponse as List<dynamic>;
  final List<String> patientIds = appts
      .map((item) => (item['patient_id'] ?? '').toString())
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();

  if (patientIds.isEmpty) return [];

  final response = await supabase
      .from('profiles')
      .select('id, full_name, avatar_url, skin_type')
      .inFilter('id', patientIds)
      .order('full_name', ascending: true);

  return List<Map<String, dynamic>>.from(response);
});

// 3. PROVIDER: EXPEDIENTE CLÍNICO DE UN PACIENTE (Detalles e IA)
// Family Provider: Recibe el ID del paciente para buscar sus escaneos
final patientClinicalDataProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, patientId) async {
  final supabase = Supabase.instance.client;

  // A. Datos del Perfil
  final profile = await supabase.from('profiles').select().eq('id', patientId).single();

  // B. Escaneos de IA (Lo que le importa al dermatólogo)
  final aiScans = await supabase
      .from('ai_scans')
      .select()
      .eq('patient_id', patientId)
      .order('created_at', ascending: false);

  // C. Historial de Citas (Opcional para el expediente)
  final history = await supabase
      .from('appointments')
      .select()
      .eq('patient_id', patientId)
      .order('scheduled_at', ascending: false);

  return {
    'profile': profile,
    'ai_scans': aiScans,
    'history': history,
  };
});