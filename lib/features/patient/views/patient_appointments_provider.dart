import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. OBTENER EL DOCTOR PRINCIPAL DEL PACIENTE
final primaryDoctorProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return null;

  // Buscamos el perfil del paciente
  final patientProfile = await supabase.from('profiles').select('primary_doctor_id').eq('id', user.id).single();

  // 🚀 FIX: Aseguramos que Dart sepa que esto puede ser un String nulo
  final primaryDocId = patientProfile['primary_doctor_id'] as String?;
  if (primaryDocId == null) return null;

  // 🚀 FIX: Usamos el '!' para decirle a Supabase que estamos 100% seguros de que no es nulo aquí
  final doctorData = await supabase.from('profiles').select().eq('id', primaryDocId).single();
  return doctorData;
});

// 2. OBTENER EL RESTO DE DOCTORES (Excluyendo al principal si existe)
final availableDoctorsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;

  // 🚀 FIX: Leemos el valor del provider de forma segura sincrónicamente
  final primaryDocAsync = ref.watch(primaryDoctorProvider);
  final primaryDocId = primaryDocAsync.value?['id'] as String?;

  var query = supabase.from('profiles').select().eq('role', 'doctor').eq('is_approved', true);

  // Si ya tiene doctor principal, lo filtramos
  if (primaryDocId != null) {
    // 🚀 FIX: El '!' le asegura a Supabase que el ID es un Object válido, no un nulo
    query = query.neq('id', primaryDocId!);
  }

  return await query;
});

// 🌟 ACTUALIZADO: 3. OBTENER LAS CITAS EN TIEMPO REAL (STREAM)
final myAppointmentsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) async* {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    yield [];
    return;
  }

  // 🚀 Usamos .stream() de Supabase para escuchar cualquier cambio (como doctor_in_room) al instante
  final stream = supabase
      .from('appointments')
      .stream(primaryKey: ['id'])
      .eq('patient_id', user.id)
      .order('appointment_date', ascending: true);

  await for (final appointments in stream) {
    final List<Map<String, dynamic>> enrichedAppointments = [];

    for (final apt in appointments) {
      try {
        // 🚀 FIX APLICADO: Solo pedimos 'full_name' para evitar el error de columnas inexistentes
        final doctorData = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', apt['doctor_id'])
            .single();

        // Creamos un mapa combinado
        enrichedAppointments.add({
          ...apt,
          'doctor': doctorData,
        });
      } catch (_) {
        // Si hay error al buscar al doctor, enviamos la cita igual para no romper la lista
        enrichedAppointments.add(apt);
      }
    }
    yield enrichedAppointments;
  }
});

// 4. LA FUNCIÓN PARA AGENDAR LA CITA
class AppointmentController {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> bookAppointment({
    required String doctorId,
    required DateTime date,
    required String type,
    required String reason,
  }) async {
    final userId = supabase.auth.currentUser!.id;

    try {
      // A. Guardar la cita
      await supabase.from('appointments').insert({
        'patient_id': userId,
        'doctor_id': doctorId,
        'appointment_date': date.toUtc().toIso8601String(),
        'type': type,
        'reason': reason,
        'status': 'scheduled',
      });

      // B. Fidelización: Verificar si ya tiene doctor principal
      final profile = await supabase.from('profiles').select('primary_doctor_id').eq('id', userId).single();

      // C. Si es su primera vez, lo asignamos
      if (profile['primary_doctor_id'] == null) {
        await supabase.from('profiles').update({
          'primary_doctor_id': doctorId
        }).eq('id', userId);
      }

    } catch (e) {
      throw Exception("Error al agendar la cita: $e");
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await supabase.from('appointments').update({
        'status': 'cancelled',
      }).eq('id', appointmentId);
    } catch (e) {
      throw Exception("Error al cancelar la cita: $e");
    }
  }

  Future<void> updateAppointment({
    required String appointmentId,
    required DateTime date,
    required String type,
    required String reason,
  }) async {
    try {
      await supabase.from('appointments').update({
        'appointment_date': date.toUtc().toIso8601String(),
        'type': type,
        'reason': reason,
      }).eq('id', appointmentId);
    } catch (e) {
      throw Exception("Error al actualizar la cita: $e");
    }
  }
}

final appointmentControllerProvider = Provider((ref) => AppointmentController());