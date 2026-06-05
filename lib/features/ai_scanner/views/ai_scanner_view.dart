import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/ai_scanner_controller.dart';
import 'patient_ai_chat_screen.dart';
import '../../patient/patient_dashboard.dart';

class AiScannerView extends ConsumerStatefulWidget {
  final bool isPushed;
  const AiScannerView({super.key, this.isPushed = false});

  @override
  ConsumerState<AiScannerView> createState() => _AiScannerViewState();
}

class _AiScannerViewState extends ConsumerState<AiScannerView> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 70, // 🚀 Ajuste: 70% es el punto dulce para IA
        maxWidth: 800,    // 🚀 CRÍTICO: Evita errores 'Payload Too Large' en la Edge Function
        maxHeight: 800,
      );

      if (photo != null) {
        setState(() => _image = File(photo.path));
        ref.read(aiScannerControllerProvider.notifier).analyzeAndSave(_image!);
      }
    } catch (e) {
      debugPrint("Error al abrir cámara: $e");
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // 🚀 Ajuste: 70% es el punto dulce para IA
        maxWidth: 800,    // 🚀 CRÍTICO: Evita errores 'Payload Too Large' en la Edge Function
        maxHeight: 800,
      );

      if (photo != null) {
        setState(() => _image = File(photo.path));
        ref.read(aiScannerControllerProvider.notifier).analyzeAndSave(_image!);
      }
    } catch (e) {
      debugPrint("Error al abrir galería: $e");
    }
  }

  void _showResultDialog(Map<String, dynamic> scanResult) {
    final String rawRisk = (scanResult['risk_level'] ?? 'low').toString().toLowerCase().trim();
    final bool isUrgent = rawRisk.contains('high') || rawRisk.contains('urgent') || rawRisk.contains('alto') || rawRisk.contains('urgente');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUrgent ? Icons.warning_amber_rounded : Icons.check_circle,
              color: isUrgent ? AppColors.danger : AppColors.success,
              size: 44,
            ),
            const SizedBox(height: 12),
            const Text(
              "¡Análisis Listo!",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          isUrgent
              ? "Hemos detectado un patrón que requiere atención. Tu caso ha sido priorizado en el panel médico. Por favor, agenda una cita."
              : "El escaneo se completó con éxito. Los resultados ya están en tu historial.",
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          textAlign: TextAlign.justify,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra Dialog
                  if (widget.isPushed) {
                    Navigator.pop(context); // Retrocedemos si fue a pantalla completa
                  } else {
                    ref.read(patientTabProvider.notifier).state = 1; // Cambia a Evolución (Index 1) 🚀
                  }
                },
                child: const Text("Entendido", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra Dialog
                  if (widget.isPushed) {
                    Navigator.pop(context); // Retrocedemos para quitar la pantalla del escáner
                  } else {
                    ref.read(patientTabProvider.notifier).state = 1; // Cambia a Evolución en el fondo para UX
                  }
                  // Abrimos el chat de IA interactiva de inmediato 🚀
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientAIChatScreen(scanData: scanResult),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Preguntar a IA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(aiScannerControllerProvider);
    final isScanning = scannerState.isLoading;

    ref.listen<AsyncValue<Map<String, dynamic>?>>(aiScannerControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (scanResult) {
          if (scanResult != null) _showResultDialog(scanResult);
        },
        error: (err, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $err"), backgroundColor: AppColors.danger),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: widget.isPushed, // Desactiva la flecha implícita si es tab 🚀
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text("Escáner de Piel IA", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 380,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                ),
                clipBehavior: Clip.hardEdge,
                child: _image == null
                    ? _buildPlaceholder()
                    : _buildScanningImage(isScanning),
              ),
              const SizedBox(height: 40),

              Text(
                isScanning ? "Analizando patrones dérmicos con IA en la nube..." : "Captura o sube una foto de tu piel",
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              if (!isScanning)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        label: const Text("Cámara", style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectFromGallery,
                        icon: const Icon(Icons.photo_library, color: AppColors.primary),
                        label: const Text("Galería", style: TextStyle(fontSize: 15, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 1,
                        ),
                      ),
                    ),
                  ],
                ),

              if (isScanning)
                const Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 10),
                    Text("Conectando con servidor seguro...", style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.face_retouching_natural, size: 80, color: AppColors.primary.withValues(alpha: 0.3)),
        const SizedBox(height: 15),
        const Text("La IA analizará signos de acné,\nmanchas o inflamación.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary)
        ),
      ],
    );
  }

  Widget _buildScanningImage(bool isScanning) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(_image!, fit: BoxFit.cover),
        if (isScanning) ...[
          Container(color: AppColors.secondary.withValues(alpha: 0.3)),
          const Center(
            child: Icon(Icons.qr_code_scanner_rounded, size: 120, color: Colors.white70),
          ),
          _buildLaserAnimation(),
        ]
      ],
    );
  }

  Widget _buildLaserAnimation() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 380),
      duration: const Duration(seconds: 2),
      builder: (context, double value, child) {
        return Positioned(
          top: value,
          left: 0,
          right: 0,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.8), blurRadius: 10, spreadRadius: 2)
              ],
              color: AppColors.primary,
            ),
          ),
        );
      },
    );
  }
}
