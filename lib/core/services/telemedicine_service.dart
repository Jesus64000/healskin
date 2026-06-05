import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 🚀 Inyección de variables de entorno

class TelemedicineService {
  // Extraemos la llave de forma segura desde la configuración local
  final String appId = dotenv.env['AGORA_APP_ID'] ?? '';

  late RtcEngine engine;

  // Callbacks para actualizar la UI reactivamente
  Function(int uid)? onUserJoined;
  Function(int uid, UserOfflineReasonType reason)? onUserOffline;
  Function(int uid)? onFirstRemoteVideoDecoded; // Para saber cuándo renderizar al otro

  Future<void> initialize() async {
    // 🔥 Fail-Fast: Si no hay llave, rompemos la ejecución con un mensaje claro
    if (appId.isEmpty) {
      throw Exception("Error Crítico de Infraestructura: AGORA_APP_ID no encontrado en el archivo .env");
    }

    // 1. Solicitar permisos críticos de hardware
    await [Permission.camera, Permission.microphone].request();

    // 2. Crear instancia del motor WebRTC
    engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // 3. Configurar eventos reactivos de Agora
    engine.registerEventHandler(
      RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("Local user joined: ${connection.localUid}");
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("Remote user joined: $remoteUid");
            if (onUserJoined != null) onUserJoined!(remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint("Remote user left: $remoteUid");
            if (onUserOffline != null) onUserOffline!(remoteUid, reason);
          },
          onFirstRemoteVideoDecoded: (connection, remoteUid, width, height, elapsed) {
            if (onFirstRemoteVideoDecoded != null) onFirstRemoteVideoDecoded!(remoteUid);
          }
      ),
    );

    // 4. Habilitar el módulo de video
    await engine.enableVideo();
    await engine.startPreview(); // Enciende la cámara local antes de entrar a la sala
  }

  Future<void> joinChannel({required String channelName, required String token, required int uid}) async {
    await engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  Future<void> toggleMic(bool isMuted) async {
    await engine.muteLocalAudioStream(isMuted);
  }

  Future<void> toggleCamera(bool isCameraOff) async {
    await engine.muteLocalVideoStream(isCameraOff);
  }

  Future<void> leaveChannel() async {
    await engine.leaveChannel();
    await engine.release(); // Libera la memoria en RAM (Crucial para no crashear la app en la siguiente llamada)
  }
}