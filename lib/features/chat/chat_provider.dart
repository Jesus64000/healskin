import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. EL STREAM EN TIEMPO REAL (Escucha los mensajes al instante)
final chatStreamProvider = StreamProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, otherUserId) {
  final supabase = Supabase.instance.client;
  final myId = supabase.auth.currentUser!.id;

  // Escuchamos la tabla en tiempo real y ordenamos del más nuevo al más viejo
  return supabase
      .from('direct_messages')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((messages) {
    // Filtramos solo la conversación entre el paciente y ESTE doctor
    return messages.where((m) =>
    (m['sender_id'] == myId && m['receiver_id'] == otherUserId) ||
        (m['sender_id'] == otherUserId && m['receiver_id'] == myId)
    ).toList();
  });
});

// 2. EL CONTROLADOR PARA ENVIAR MENSAJES
class ChatController {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> sendMessage(String receiverId, String text) async {
    if (text.trim().isEmpty) return;

    final myId = supabase.auth.currentUser!.id;

    try {
      await supabase.from('direct_messages').insert({
        'sender_id': myId,
        'receiver_id': receiverId,
        'message': text.trim(),
      });
    } catch (e) {
      throw Exception("Error al enviar mensaje: $e");
    }
  }
}

final chatControllerProvider = Provider((ref) => ChatController());