import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final patientProceduresProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) async* {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    yield [];
    return;
  }

  final stream = supabase
      .from('patient_procedures')
      .stream(primaryKey: ['id'])
      .eq('patient_id', user.id)
      .order('created_at', ascending: false);

  await for (final procedures in stream) {
    final List<Map<String, dynamic>> enriched = [];
    for (final proc in procedures) {
      try {
        final doctorId = proc['doctor_id'];
        if (doctorId != null) {
          final doctorData = await supabase
              .from('profiles')
              .select('full_name')
              .eq('id', doctorId)
              .single();
          enriched.add({
            ...proc,
            'doctor': doctorData,
          });
        } else {
          enriched.add(proc);
        }
      } catch (_) {
        enriched.add(proc);
      }
    }
    yield enriched;
  }
});

class ProceduresController {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> addProcedure({
    required String patientId,
    required String procedureName,
    required int frequencyDays,
    required String? instructions,
  }) async {
    final doctorId = supabase.auth.currentUser?.id;
    try {
      await supabase.from('patient_procedures').insert({
        'patient_id': patientId,
        'doctor_id': doctorId,
        'procedure_name': procedureName,
        'frequency_days': frequencyDays,
        'instructions': instructions,
        'status': 'active',
      });
    } catch (e) {
      throw Exception("Error al recetar el procedimiento: $e");
    }
  }

  Future<void> updateProcedureStatus({
    required String procedureId,
    required String status,
  }) async {
    try {
      await supabase.from('patient_procedures').update({
        'status': status,
      }).eq('id', procedureId);
    } catch (e) {
      throw Exception("Error al actualizar el estado del procedimiento: $e");
    }
  }

  Future<void> deleteProcedure(String procedureId) async {
    try {
      await supabase.from('patient_procedures').delete().eq('id', procedureId);
    } catch (e) {
      throw Exception("Error al eliminar el procedimiento: $e");
    }
  }
}

final proceduresControllerProvider = Provider((ref) => ProceduresController());
