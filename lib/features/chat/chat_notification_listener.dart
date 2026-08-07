import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/notification_service.dart';

class ChatNotificationListener {
  static final ChatNotificationListener _instance = ChatNotificationListener._internal();
  factory ChatNotificationListener() => _instance;
  ChatNotificationListener._internal();

  RealtimeChannel? _channel;
  String? activeChatUserId;
  final Set<String> _seenMessageIds = {};
  DateTime _startTime = DateTime.now();

  void startListening() {
    final supabase = Supabase.instance.client;
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    _startTime = DateTime.now();
    _seenMessageIds.clear();
    stopListening();

    debugPrint("💬 Iniciando listener en tiempo real para mensajes entrantes de: $myId");

    _channel = supabase.channel('public:direct_messages')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'direct_messages',
        callback: (payload) async {
          final newRecord = payload.newRecord;
          final receiverId = newRecord['receiver_id']?.toString();
          if (receiverId != myId) return; // Filtramos aquí en Dart

          final messageId = newRecord['id']?.toString();
          final senderId = newRecord['sender_id']?.toString();
          final messageText = newRecord['message']?.toString() ?? 'Nuevo mensaje';
          final createdAtStr = newRecord['created_at']?.toString();

          if (messageId == null || senderId == null) return;
          if (_seenMessageIds.contains(messageId)) return;
          _seenMessageIds.add(messageId);

          if (activeChatUserId == senderId) {
            debugPrint("💬 Mensaje de chat activo recibido ($senderId), omitiendo notificación.");
            return;
          }

          if (createdAtStr != null) {
            try {
              final createdAt = DateTime.parse(createdAtStr).toLocal();
              // Permitir mensajes recientes dentro del margen de tolerancia (5 minutos)
              if (createdAt.isBefore(_startTime.subtract(const Duration(minutes: 5)))) {
                return;
              }
            } catch (_) {}
          }

          try {
            final profileRes = await supabase
                .from('profiles')
                .select('full_name')
                .eq('id', senderId)
                .maybeSingle();

            final senderName = profileRes?['full_name'] ?? 'Usuario';

            await NotificationService().showInstantNotification(
              id: senderId.hashCode,
              title: senderName,
              body: messageText,
              payload: 'chat:$senderId|$senderName',
            );
          } catch (e) {
            debugPrint("⚠️ Error al obtener perfil del remitente o mostrar notificación: $e");
          }
        },
      );
    _channel?.subscribe();
  }

  void stopListening() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
      debugPrint("💬 Listener de chat en tiempo real detenido.");
    }
  }
}
