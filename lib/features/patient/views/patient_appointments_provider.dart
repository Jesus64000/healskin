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
  final currentUser = supabase.auth.currentUser;

  // 🚀 FIX: Leemos el valor del provider de forma segura sincrónicamente
  final primaryDocAsync = ref.watch(primaryDoctorProvider);
  final primaryDocId = primaryDocAsync.value?['id'] as String?;

  var query = supabase.from('profiles').select().eq('role', 'doctor').eq('is_approved', true);

  // Excluir al usuario actual si está autenticado
  if (currentUser != null) {
    query = query.neq('id', currentUser.id);
  }

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
            .select('full_name, office_address')
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

// 4. ESTRUCTURA Y FUNCIÓN PARA CONSULTAR Y AGENDAR CITAS
class DoctorDayAvailability {
  final bool isAllDayBlocked;
  final String? blockReason;
  final List<TimeOfDay> occupiedSlots;
  final List<TimeOfDay> blockedSlots;
  final Map<String, String> slotReasons; // Mapea slot key a motivo de bloqueo

  DoctorDayAvailability({
    required this.isAllDayBlocked,
    this.blockReason,
    required this.occupiedSlots,
    required this.blockedSlots,
    required this.slotReasons,
  });
}

class AppointmentController {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<DoctorDayAvailability> getDoctorDayAvailability(String doctorId, DateTime date) async {
    final localDate = date.toLocal();
    final localStart = DateTime(localDate.year, localDate.month, localDate.day, 0, 0, 0);
    final localEnd = DateTime(localDate.year, localDate.month, localDate.day, 23, 59, 59);

    final startOfDayUtc = localStart.toUtc().toIso8601String();
    final endOfDayUtc = localEnd.toUtc().toIso8601String();

    final existingApts = await supabase
        .from('appointments')
        .select()
        .eq('doctor_id', doctorId)
        .eq('status', 'scheduled')
        .gte('appointment_date', startOfDayUtc)
        .lte('appointment_date', endOfDayUtc);

    bool isAllDayBlocked = false;
    String? dayBlockReason;
    final List<TimeOfDay> occupiedSlots = [];
    final List<TimeOfDay> blockedSlots = [];
    final Map<String, String> slotReasons = {};

    for (final apt in existingApts) {
      final String reasonStr = apt['reason'] ?? '';
      final String patientId = apt['patient_id'] ?? '';
      final bool isBlocked = patientId == doctorId || reasonStr.toLowerCase().contains('bloqueo');

      final aptTime = DateTime.parse(apt['appointment_date']).toLocal();

      if (isBlocked) {
        if (reasonStr.contains('[Jornada Completa]') || reasonStr.toLowerCase().contains('jornada completa')) {
          isAllDayBlocked = true;
          final cleanReason = reasonStr.replaceAll('[Jornada Completa]', '').replaceAll('Bloqueo :', '').trim();
          dayBlockReason = cleanReason.isEmpty ? "Jornada bloqueada por el médico" : cleanReason;
        } else if (reasonStr.contains('[Hasta ')) {
          final startIdx = reasonStr.indexOf('[Hasta ') + 7;
          final endIdx = reasonStr.indexOf(']', startIdx);
          if (endIdx != -1) {
            final timeStr = reasonStr.substring(startIdx, endIdx); // e.g. "04:00 PM"
            final parts = timeStr.trim().split(' ');
            if (parts.length == 2) {
              final hm = parts[0].split(':');
              if (hm.length == 2) {
                int hour = int.parse(hm[0]);
                final minute = int.parse(hm[1]);
                final ampm = parts[1].toUpperCase();
                if (ampm == 'PM' && hour < 12) hour += 12;
                if (ampm == 'AM' && hour == 12) hour = 0;

                final blockStart = aptTime;
                final blockEnd = DateTime(blockStart.year, blockStart.month, blockStart.day, hour, minute);

                // Marcar todos los slots de 30 mins entre blockStart y blockEnd
                DateTime current = blockStart;
                while (current.isBefore(blockEnd) || current.isAtSameMomentAs(blockEnd)) {
                  final slotTime = TimeOfDay(hour: current.hour, minute: current.minute);
                  blockedSlots.add(slotTime);
                  slotReasons["${current.hour}:${current.minute}"] = reasonStr;
                  current = current.add(const Duration(minutes: 30));
                }
              }
            }
          }
        } else {
          // Bloqueo general en esa hora específica
          final slotTime = TimeOfDay(hour: aptTime.hour, minute: aptTime.minute);
          blockedSlots.add(slotTime);
          slotReasons["${aptTime.hour}:${aptTime.minute}"] = reasonStr;
        }
      } else {
        // Cita ocupada por otro paciente
        final slotTime = TimeOfDay(hour: aptTime.hour, minute: aptTime.minute);
        occupiedSlots.add(slotTime);
      }
    }

    return DoctorDayAvailability(
      isAllDayBlocked: isAllDayBlocked,
      blockReason: dayBlockReason,
      occupiedSlots: occupiedSlots,
      blockedSlots: blockedSlots,
      slotReasons: slotReasons,
    );
  }

  Future<void> _checkDoctorAvailability(String doctorId, DateTime date, {String? ignoreAppointmentId}) async {
    final availability = await getDoctorDayAvailability(doctorId, date);

    if (availability.isAllDayBlocked) {
      throw Exception("El médico tiene la jornada bloqueada para este día (${availability.blockReason ?? 'Motivo personal'}). Por favor elige otra fecha.");
    }

    final targetLocal = date.toLocal();
    final targetTime = TimeOfDay(hour: targetLocal.hour, minute: targetLocal.minute);

    // Verificar si la hora objetivo está bloqueada o reservada
    for (final blocked in availability.blockedSlots) {
      final diffMinutes = (targetTime.hour * 60 + targetTime.minute) - (blocked.hour * 60 + blocked.minute);
      if (diffMinutes.abs() < 30) {
        throw Exception("El horario seleccionado (${_formatTime(targetTime)}) está bloqueado por el médico. Por favor elige otra hora.");
      }
    }

    for (final occupied in availability.occupiedSlots) {
      final diffMinutes = (targetTime.hour * 60 + targetTime.minute) - (occupied.hour * 60 + occupied.minute);
      if (diffMinutes.abs() < 30) {
        throw Exception("El horario de las ${_formatTime(targetTime)} ya se encuentra reservado por otro paciente. Por favor elige otra hora.");
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> bookAppointment({
    required String doctorId,
    required DateTime date,
    required String type,
    required String reason,
  }) async {
    final userId = supabase.auth.currentUser!.id;

    try {
      // Validar bloqueos y solapamientos
      await _checkDoctorAvailability(doctorId, date);
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
      throw Exception(e.toString().replaceAll("Exception: ", ""));
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

  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await supabase.from('appointments').delete().eq('id', appointmentId);
    } catch (e) {
      throw Exception("Error al eliminar la cita: $e");
    }
  }

  Future<void> updateAppointment({
    required String appointmentId,
    required DateTime date,
    required String type,
    required String reason,
  }) async {
    try {
      // 1. Obtener la cita actual para saber el doctor_id
      final currentApt = await supabase.from('appointments').select('doctor_id').eq('id', appointmentId).single();
      final doctorId = currentApt['doctor_id'];

      // 2. Validar bloqueos y solapamientos (ignorando esta misma cita)
      await _checkDoctorAvailability(doctorId, date, ignoreAppointmentId: appointmentId);

      await supabase.from('appointments').update({
        'appointment_date': date.toUtc().toIso8601String(),
        'type': type,
        'reason': reason,
      }).eq('id', appointmentId);
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }
}

final appointmentControllerProvider = Provider((ref) => AppointmentController());

final doctorDayAvailabilityProvider = FutureProvider.family.autoDispose<DoctorDayAvailability, ({String doctorId, DateTime date})>((ref, arg) async {
  final controller = ref.read(appointmentControllerProvider);
  return await controller.getDoctorDayAvailability(arg.doctorId, arg.date);
});