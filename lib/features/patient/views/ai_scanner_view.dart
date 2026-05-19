import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_colors.dart';

class AiScannerView extends StatefulWidget {
  const AiScannerView({super.key});

  @override
  State<AiScannerView> createState() => _AiScannerViewState();
}

class _AiScannerViewState extends State<AiScannerView> {
  File? _image;
  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();

  // 1. Función para abrir la cámara
  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front, // Usamos la cámara frontal por defecto
    );

    if (photo != null) {
      setState(() {
        _image = File(photo.path);
        _isScanning = true;
      });
      _startSimulatedAnalysis();
    }
  }

  // 2. Simulación de la IA (Para la Demo actual)
  Future<void> _startSimulatedAnalysis() async {
    // Simulamos que la foto sube a la nube y la IA la procesa (tarda 4 segundos)
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    setState(() {
      _isScanning = false;
    });

    // Mostramos el resultado
    _showResultDialog();
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 10),
            Text("Análisis Completado"),
          ],
        ),
        content: const Text(
          "La IA ha detectado una leve inflamación en la zona T (probabilidad 85%).\n\nEl resultado ha sido guardado en tu historial clínico.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra el modal
              Navigator.pop(context); // Regresa a la pantalla anterior (Timeline/Home)
            },
            child: const Text("Ver Evolución", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text("Escáner de Piel IA", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Contenedor de la Imagen / Animación
              Container(
                height: 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                ),
                clipBehavior: Clip.hardEdge,
                child: _image == null
                    ? _buildPlaceholder()
                    : _buildScanningImage(),
              ),
              const SizedBox(height: 40),

              // Texto Dinámico
              Text(
                _isScanning ? "Analizando patrones dérmicos..." : "Captura el estado actual de tu piel",
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Botón de Acción Principal
              if (!_isScanning)
                ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text("Tomar Fotografía", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 5,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),

              if (_isScanning)
                const CircularProgressIndicator(color: AppColors.primary),
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
        Icon(Icons.face_retouching_natural, size: 100, color: AppColors.primary.withValues(alpha: 0.3)),
        const SizedBox(height: 15),
        const Text("La IA necesita una foto clara\nde tu rostro sin maquillaje.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary)
        ),
      ],
    );
  }

  Widget _buildScanningImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // La foto real que tomó el usuario
        Image.file(_image!, fit: BoxFit.cover),

        // Capa oscura semi-transparente para dar efecto de escaneo
        if (_isScanning)
          Container(color: AppColors.secondary.withValues(alpha: 0.3)),

        // Animación de red neuronal o escáner (Lottie)
        // Nota: Para que la animación se vea, debes descargar un archivo .json de lottiefiles.com,
        // ponerlo en assets/ y usar Lottie.asset('assets/scan.json').
        // Por ahora, usaremos un efecto visual integrado simple si no tienes el archivo.
        if (_isScanning)
          const Center(
            child: Icon(Icons.document_scanner_outlined, size: 100, color: Colors.white70),
          )
      ],
    );
  }
}