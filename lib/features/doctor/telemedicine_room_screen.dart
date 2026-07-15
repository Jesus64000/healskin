import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 🚀 IMPORTANTE: Para actualizar la BD al colgar
import '../../core/theme/app_colors.dart';
import '../../core/services/telemedicine_service.dart';

class TelemedicineRoomScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String appointmentId; // 🚀 NUEVO: ID de la cita
  final bool isDoctor;        // 🚀 NUEVO: ¿Quién está en esta pantalla?

  const TelemedicineRoomScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.appointmentId,
    required this.isDoctor,
  });

  @override
  State<TelemedicineRoomScreen> createState() => _TelemedicineRoomScreenState();
}

class _TelemedicineRoomScreenState extends State<TelemedicineRoomScreen> {
  // --- ESTADO DE AGORA ---
  final TelemedicineService _agoraService = TelemedicineService();
  int? _remoteUid;
  bool _localUserJoined = false;

  // 🚀 NOTA TÉCNICA: El token temporal estático del .env ha sido reemplazado por
  // un microservicio de Supabase Edge Functions que genera tokens dinámicos y seguros al vuelo.

  // --- ESTADO DE UI ---
  bool _isMuted = false;
  bool _isCameraOff = false;
  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initTelemedicine();
  }

  Future<void> _initTelemedicine() async {
    _agoraService.onUserJoined = (uid) {
      debugPrint("Usuario remoto conectado. UID: $uid");
      setState(() => _remoteUid = uid);
    };

    _agoraService.onUserOffline = (uid, reason) {
      debugPrint("Usuario remoto desconectado.");
      setState(() => _remoteUid = null);
    };

    try {
      await _agoraService.initialize();

      // 🚀 INVOCACIÓN AL GENERADOR DE TOKENS DINÁMICOS
      final response = await Supabase.instance.client.functions.invoke(
        'agora-token-generator',
        body: {
          'channelName': widget.patientId,
          'uid': 0,
        },
      );

      if (response.status != 200) {
        throw Exception("Error de respuesta del microservicio: ${response.status}");
      }

      final data = response.data as Map<String, dynamic>;
      final String dynamicToken = data['token'] ?? '';

      if (dynamicToken.isEmpty) {
        throw Exception("El token recibido está vacío.");
      }

      await _agoraService.joinChannel(
        channelName: widget.patientId, // 🔴 CRÍTICO: La sala es el ID del paciente (Privacidad 1 a 1)
        token: dynamicToken,
        uid: 0,
      );
      setState(() => _localUserJoined = true);

      // 🚀 NUEVO: Si es el doctor, activamos el flag de "doctor_in_room" en Supabase en cuanto entra a la sala
      if (widget.isDoctor && widget.appointmentId.isNotEmpty) {
        try {
          await Supabase.instance.client
              .from('appointments')
              .update({'doctor_in_room': true})
              .eq('id', widget.appointmentId);
        } catch (e) {
          debugPrint("⚠️ Error al activar doctor_in_room: $e");
        }
      }
    } on FunctionException catch (e) {
      final errorMessage = e.details ?? e.reasonPhrase ?? e.toString();
      debugPrint("⚠️ ERROR EN TELEMEDICINA IA/RTC (FunctionException): $errorMessage");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al conectar videoconsulta: $errorMessage"),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      debugPrint("⚠️ ERROR EN TELEMEDICINA IA/RTC: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al conectar videoconsulta: $e"),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (widget.isDoctor && widget.appointmentId.isNotEmpty) {
      // Fire-and-forget para apagar el flag al destruir la pantalla (por ejemplo, al volver atrás)
      Supabase.instance.client
          .from('appointments')
          .update({'doctor_in_room': false})
          .eq('id', widget.appointmentId)
          .then((_) => debugPrint("Sala virtual del médico cerrada exitosamente en dispose"))
          .catchError((e) => debugPrint("Error al cerrar sala en dispose: $e"));
    }
    try {
      _agoraService.leaveChannel();
    } catch (e) {
      debugPrint("Error al colgar canal en dispose: $e");
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsElapsed++);
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$remainingSeconds";
  }

  Future<void> _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _agoraService.toggleMic(_isMuted);
  }

  Future<void> _toggleCamera() async {
    setState(() => _isCameraOff = !_isCameraOff);
    await _agoraService.toggleCamera(_isCameraOff);
  }

  // 🚀 EL CIERRE MÁGICO
  Future<void> _endCall() async {
    // 1. Salimos de Agora
    await _agoraService.leaveChannel();
    _timer?.cancel();

    // 2. Cerramos la puerta de la sala y marcamos la cita como completada en Supabase
    if (widget.appointmentId.isNotEmpty) {
      try {
        await Supabase.instance.client
            .from('appointments')
            .update({
              'status': 'completed',
              'doctor_in_room': false,
            })
            .eq('id', widget.appointmentId);
        debugPrint("Cita ${widget.appointmentId} marcada como completada exitosamente.");
      } catch (e) {
        debugPrint("Error al actualizar cita en BD a completada: $e");
      }
    }

    if (!mounted) return;

    // 3. Volvemos al expediente / dashboard
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Consulta con ${widget.patientName} finalizada. Duración: ${_formatDuration(_secondsElapsed)}"),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          await _endCall();
        },
        child: SafeArea(
          child: Stack(
            children: [
              _buildMainVideoFeed(),
              _buildPiPVideoFeed(),
              _buildTopBar(context),
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  // --- RENDERIZADO WEB RTC ---

  Widget _buildMainVideoFeed() {
    return Positioned.fill(
      child: Container(
        color: AppColors.surfaceDark.withValues(alpha: 0.1),
        child: _remoteUid != null
            ? AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _agoraService.engine,
            canvas: VideoCanvas(uid: _remoteUid),
            connection: RtcConnection(channelId: widget.patientId),
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 120, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 20),
            Text(
              "Esperando conexión de ${widget.patientName}...",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildPiPVideoFeed() {
    return Positioned(
      top: 90,
      right: 20,
      child: Container(
        width: 110,
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: _isCameraOff
            ? const Center(child: Icon(Icons.videocam_off, color: Colors.white, size: 30))
            : _localUserJoined
            ? AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _agoraService.engine,
            canvas: const VideoCanvas(uid: 0),
          ),
        )
            : const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }

  // --- UI CONTROLES ---

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 10, left: 10, right: 10,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => _endCall(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.patientName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(_formatDuration(_secondsElapsed), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 40, left: 0, right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _controlButton(icon: _isMuted ? Icons.mic_off : Icons.mic, color: _isMuted ? Colors.white : AppColors.surfaceDark, iconColor: _isMuted ? AppColors.textPrimary : Colors.white, onTap: _toggleMute),
          const SizedBox(width: 25),
          GestureDetector(
            onTap: _endCall,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.danger, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.danger.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5))]),
              child: const Icon(Icons.call_end, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(width: 25),
          _controlButton(icon: _isCameraOff ? Icons.videocam_off : Icons.videocam, color: _isCameraOff ? Colors.white : AppColors.surfaceDark, iconColor: _isCameraOff ? AppColors.textPrimary : Colors.white, onTap: _toggleCamera),
        ],
      ),
    );
  }

  Widget _controlButton({required IconData icon, required Color color, required Color iconColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 26),
      ),
    );
  }
}