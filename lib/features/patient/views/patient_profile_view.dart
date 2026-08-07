import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/auth_provider.dart';
import '../../auth/profile_provider.dart';
import '../../auth/initial_quiz_screen.dart';
import '../../auth/login_screen.dart';
import 'patient_reminders_view.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/personal_use_disclaimer_dialog.dart';

class PatientProfileView extends ConsumerStatefulWidget {
  final bool autoOpenEditModal;
  const PatientProfileView({super.key, this.autoOpenEditModal = false});

  @override
  ConsumerState<PatientProfileView> createState() => _PatientProfileViewState();
}

class _PatientProfileViewState extends ConsumerState<PatientProfileView> {
  bool _isUploadingAvatar = false;
  bool _isSavingName = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    if (widget.autoOpenEditModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final profile = await ref.read(userProfileProvider.future);
        if (profile != null && mounted) {
          _showEditProfileModal(profile);
        }
      });
    }
  }

  // --- 📸 CAPTURA Y SUBIDA DE FOTO DE PERFIL A STORAGE ---
  Future<void> _updateAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile == null) return;
    
    // Recortar la foto para permitir que el usuario la encuadre
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Ajustar Foto de Perfil',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: 'Ajustar Foto de Perfil',
          aspectRatioLockEnabled: true,
          cropStyle: CropStyle.circle,
        ),
      ],
    );

    if (croppedFile == null) return;

    setState(() => _isUploadingAvatar = true);
    
    try {
      final file = File(croppedFile.path);
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      
      final fileExtension = pickedFile.path.split('.').last;
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final storagePath = 'avatars/$fileName';
      
      // Subimos la imagen al bucket público 'scan_images'
      await supabase.storage.from('scan_images').upload(storagePath, file);
      final publicUrl = supabase.storage.from('scan_images').getPublicUrl(storagePath);
      
      // Actualizamos la dirección de la foto en la base de datos
      await supabase.from('profiles').update({
        'avatar_url': publicUrl,
      }).eq('id', userId);
      
      // Invalidamos el proveedor de perfil para forzar actualización reactiva en toda la app
      ref.invalidate(userProfileProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("¡Foto de perfil actualizada con éxito! 📸", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error al subir foto: $e"),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  // --- ✍️ ACTUALIZAR PERFIL ---
  Future<void> _updateProfile({
    required String newName,
    required int? age,
    required String? gender,
    required String allergies,
    required String medicalHistory,
    required String treatmentsPast,
    required String treatmentsCurrent,
  }) async {
    if (newName.trim().isEmpty) return;
    
    setState(() => _isSavingName = true);
    
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      
      await supabase.from('profiles').update({
        'full_name': newName.trim(),
        'age': age,
        'gender': gender,
        'allergies': allergies.trim(),
        'medical_history': medicalHistory.trim(),
        'treatments_past': treatmentsPast.trim(),
        'treatments_current': treatmentsCurrent.trim(),
      }).eq('id', userId);
      
      ref.invalidate(userProfileProvider);
      
      if (mounted) {
        Navigator.pop(context); // Cerramos el Modal
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("¡Información de perfil actualizada! 📝", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error al actualizar información: $e"),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  // --- 📝 MODAL BOTTOM SHEET DE EDICIÓN DE PERFIL ---
  void _showEditProfileModal(Map<String, dynamic>? profile) {
    final nameController = TextEditingController(text: profile?['full_name'] ?? '');
    final ageController = TextEditingController(text: profile?['age']?.toString() ?? '');
    String? selectedGender = profile?['gender'];

    final String allergiesVal = profile?['allergies'] ?? '';
    final String medicalHistoryVal = profile?['medical_history'] ?? '';
    final String treatmentsPastVal = profile?['treatments_past'] ?? '';
    final String treatmentsCurrentVal = profile?['treatments_current'] ?? '';

    bool hasAllergies = allergiesVal.isNotEmpty && allergiesVal.toLowerCase() != 'ninguna' && allergiesVal.toLowerCase() != 'ninguno';
    bool hasMedicalHistory = medicalHistoryVal.isNotEmpty && medicalHistoryVal.toLowerCase() != 'ninguna' && medicalHistoryVal.toLowerCase() != 'ninguno';
    bool hasTreatmentsPast = treatmentsPastVal.isNotEmpty && treatmentsPastVal.toLowerCase() != 'ninguna' && treatmentsPastVal.toLowerCase() != 'ninguno';
    bool hasTreatmentsCurrent = treatmentsCurrentVal.isNotEmpty && treatmentsCurrentVal.toLowerCase() != 'ninguna' && treatmentsCurrentVal.toLowerCase() != 'ninguno';

    final allergiesController = TextEditingController(text: hasAllergies ? allergiesVal : '');
    final medicalHistoryController = TextEditingController(text: hasMedicalHistory ? medicalHistoryVal : '');
    final treatmentsPastController = TextEditingController(text: hasTreatmentsPast ? treatmentsPastVal : '');
    final treatmentsCurrentController = TextEditingController(text: hasTreatmentsCurrent ? treatmentsCurrentVal : '');

    // Géneros válidos
    final genders = ["Femenino", "Masculino", "Otro", "Prefiero no decirlo"];
    if (selectedGender != null && !genders.contains(selectedGender)) {
      selectedGender = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75, // máximo 75% del alto de pantalla
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 45,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Editar Información",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Actualiza tus datos demográficos e historial médico para tu dermatólogo.",
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      
                      // 1. Nombre Completo
                      const Text("Nombre Completo *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                        ],
                        decoration: InputDecoration(
                          hintText: "Ej. María Pérez",
                          prefixIcon: const Icon(Icons.person_rounded, color: AppColors.primary),
                          fillColor: AppColors.surfaceLight,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Fila de Edad y Género
                      Row(
                        children: [
                          // 2. Edad
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Edad", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: ageController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(3),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: "Ej. 25",
                                    prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.primary),
                                    fillColor: AppColors.surfaceLight,
                                    filled: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          // 3. Género
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Género", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedGender,
                                      hint: const Text("Selecciona", style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                                      isExpanded: true,
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                                      items: genders.map((g) {
                                        return DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 14)));
                                      }).toList(),
                                      onChanged: (val) {
                                        setModalState(() => selectedGender = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 4. Alergias Conocidas Switch
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "¿Sufre de alguna alergia?",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: hasAllergies,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setModalState(() {
                                hasAllergies = val;
                              });
                            },
                          ),
                        ],
                      ),
                      if (hasAllergies) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: allergiesController,
                          maxLines: 2,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: "Ej. Alergia al níquel, fragancias artificiales...",
                            fillColor: AppColors.surfaceLight,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                      const SizedBox(height: 15),

                      // 5. Antecedentes Médicos Switch
                      Row(
                        children: [
                          const Icon(Icons.history_edu_outlined, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "¿Posee antecedentes médicos?",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: hasMedicalHistory,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setModalState(() {
                                hasMedicalHistory = val;
                              });
                            },
                          ),
                        ],
                      ),
                      if (hasMedicalHistory) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: medicalHistoryController,
                          maxLines: 3,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: "Ej. Antecedentes familiares de rosácea, dermatitis atópica...",
                            fillColor: AppColors.surfaceLight,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                      const SizedBox(height: 15),

                      // 6. Tratamientos Previos Switch
                      Row(
                        children: [
                          const Icon(Icons.history_outlined, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "¿Ha recibido tratamientos previos?",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: hasTreatmentsPast,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setModalState(() {
                                hasTreatmentsPast = val;
                              });
                            },
                          ),
                        ],
                      ),
                      if (hasTreatmentsPast) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: treatmentsPastController,
                          maxLines: 2,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: "Ej. Uso previo de ácido salicílico, láser de CO2...",
                            fillColor: AppColors.surfaceLight,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                      const SizedBox(height: 15),

                      // 7. Tratamientos Actuales Switch
                      Row(
                        children: [
                          const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "¿Realiza algún tratamiento actual?",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: hasTreatmentsCurrent,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setModalState(() {
                                hasTreatmentsCurrent = val;
                              });
                            },
                          ),
                        ],
                      ),
                      if (hasTreatmentsCurrent) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: treatmentsCurrentController,
                          maxLines: 2,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: "Ej. Uso de protector solar FPS 50, crema de retinol nocturna...",
                            fillColor: AppColors.surfaceLight,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                      const SizedBox(height: 25),

                      // Botón Guardar
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSavingName 
                              ? null 
                              : () async {
                                  if (nameController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                      content: Text("El nombre es obligatorio."),
                                      backgroundColor: AppColors.warning,
                                    ));
                                    return;
                                  }

                                  setModalState(() => _isSavingName = true);
                                  
                                  final int? age = int.tryParse(ageController.text);
                                  
                                  String allergiesToSave = hasAllergies ? allergiesController.text.trim() : "Ninguna";
                                  if (allergiesToSave.isEmpty) allergiesToSave = "Ninguna";

                                  String medicalHistoryToSave = hasMedicalHistory ? medicalHistoryController.text.trim() : "Ninguno";
                                  if (medicalHistoryToSave.isEmpty) medicalHistoryToSave = "Ninguno";

                                  String treatmentsPastToSave = hasTreatmentsPast ? treatmentsPastController.text.trim() : "Ninguno";
                                  if (treatmentsPastToSave.isEmpty) treatmentsPastToSave = "Ninguno";

                                  String treatmentsCurrentToSave = hasTreatmentsCurrent ? treatmentsCurrentController.text.trim() : "Ninguno";
                                  if (treatmentsCurrentToSave.isEmpty) treatmentsCurrentToSave = "Ninguno";

                                  await _updateProfile(
                                    newName: nameController.text,
                                    age: age,
                                    gender: selectedGender,
                                    allergies: allergiesToSave,
                                    medicalHistory: medicalHistoryToSave,
                                    treatmentsPast: treatmentsPastToSave,
                                    treatmentsCurrent: treatmentsCurrentToSave,
                                  );
                                  
                                  setModalState(() => _isSavingName = false);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isSavingName
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text("Guardar Cambios", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 🛡️ DIÁLOGO DE PRIVACIDAD REAL ---
  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_moon_rounded, color: AppColors.secondary, size: 44),
              SizedBox(height: 12),
              Text(
                "Privacidad y Datos", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "En HealSkin nos tomamos tu privacidad y la seguridad de tu información con absoluta seriedad.\n\n"
                "• Tus fotos de piel y análisis se almacenan en servidores en la nube encriptados de forma privada.\n\n"
                "• El triaje de la IA sirve únicamente como una guía preliminar para agilizar tu consulta.\n\n"
                "• Ningún tercero tiene acceso a tus datos; solo tu dermatólogo asignado está autorizado para revisar tu historial clínico durante tus citas de telemedicina.",
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.justify,
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 2,
              ),
              child: const Text("Entendido y Acepto", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  // --- 🩺 DIÁLOGO DE AYUDA Y SOPORTE FAQ ---
  void _showFAQDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.help_outline_rounded, color: AppColors.success, size: 44),
              SizedBox(height: 12),
              Text(
                "Ayuda y Soporte FAQ", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFaqItem(
                  "¿Cómo funciona el triaje de la IA?",
                  "La IA analiza visualmente tu foto para identificar posibles atipias y estructurar un razonamiento pre-clínico (eritemas, bordes, etc.). No da diagnósticos finales, sino un triaje de riesgo para tu médico."
                ),
                _buildFaqItem(
                  "¿Cómo agendar videoconsultas?",
                  "Dirígete al apartado de Citas e inicia una llamada directa con tu dermatólogo en el canal dinámico en tiempo real habilitado."
                ),
                _buildFaqItem(
                  "¿Qué es la pantalla de Evolución?",
                  "Es un timeline de progreso interactivo. Cada escaneo de piel exitoso dibuja un hito cronológico con la foto, el riesgo y el desglose de consejos de la IA."
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 2,
              ),
              child: const Text("Cerrar", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            question, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            answer, 
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 10),
          const Divider(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          await Future.delayed(const Duration(seconds: 1));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.backgroundLight,
              elevation: 0,
              centerTitle: false,
              title: const Text(
                "Perfil",
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18),
              ),
            ),

            SliverToBoxAdapter(
              child: profileAsync.when(
                data: (profile) {
                  final String name = profile?['full_name'] ?? "Usuario";
                  final String email = authState.session?.user.email ?? "Sin correo";
                  final String skinTypeRaw = profile?['skin_type'] ?? 'normal';
                  
                  // Formateo visual del tipo de piel en mayúsculas
                  final String skinType = skinTypeRaw.toUpperCase().replaceAll('GRASO', 'GRASA');
                  final String? avatarUrl = profile?['avatar_url'];

                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // 🧠 AVATAR DINÁMICO TÁCTIL (Pulsar para subir foto)
                        GestureDetector(
                          onTap: _isUploadingAvatar ? null : _updateAvatar,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 55,
                                  backgroundColor: Colors.grey.shade100,
                                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: _isUploadingAvatar
                                      ? const CircularProgressIndicator(color: AppColors.primary)
                                      : (avatarUrl == null || avatarUrl.isEmpty
                                          ? const Icon(Icons.person_rounded, size: 60, color: AppColors.primary)
                                          : null),
                                ),
                              ),
                              // Lápiz de edición flotante estilo premium
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          name,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          email,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 15),

                        // Botón de Edición Rápida
                        OutlinedButton.icon(
                          onPressed: () => _showEditProfileModal(profile),
                          icon: const Icon(Icons.badge_rounded, size: 16),
                          label: const Text("Editar Datos", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // --- CELDAS DE AJUSTES ---
                        _buildSettingsTile(
                          icon: Icons.medical_information_outlined,
                          title: "Cuestionario de Piel",
                          subtitle: "Tu diagnóstico: PIEL $skinType",
                          iconColor: AppColors.primary,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InitialQuizScreen())),
                        ),
                        _buildSettingsTile(
                          icon: Icons.shield_moon_outlined,
                          title: "Privacidad y Datos",
                          subtitle: "Políticas y encriptación de triaje",
                          iconColor: AppColors.secondary,
                          onTap: _showPrivacyDialog,
                        ),
                        _buildSettingsTile(
                          icon: Icons.verified_user_outlined,
                          title: "Aviso de Uso Personal",
                          subtitle: "Uso estrictamente individual de la cuenta",
                          iconColor: AppColors.primary,
                          onTap: () => PersonalUseDisclaimerDialog.show(context),
                        ),
                        
                        // Interruptor de Notificaciones Interactivo
                        _buildInteractiveNotificationTile(),

                        _buildSettingsTile(
                          icon: Icons.notification_important_outlined,
                          title: "Probar Notificaciones",
                          subtitle: "Emitir una alerta de prueba en 5 seg.",
                          iconColor: AppColors.primary,
                          onTap: () async {
                            final notificationService = NotificationService();
                            await notificationService.requestPermissions();
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("🔔 Alerta de prueba agendada en 5 segundos. Sal de la app para verla."),
                                  duration: Duration(seconds: 4),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }

                            Future.delayed(const Duration(seconds: 5), () async {
                              await notificationService.showInstantNotification(
                                id: 9999,
                                title: "¡Prueba de Notificación Funcional! 🎉",
                                body: "El canal de comunicación local de HealSkin está operando correctamente en tu dispositivo.",
                              );
                            });
                          },
                        ),

                        _buildSettingsTile(
                          icon: Icons.notifications_active_outlined,
                          title: "Recordatorios y Hábitos",
                          subtitle: "Alarmas de medicación y rutinas",
                          iconColor: AppColors.secondary,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientRemindersView())),
                        ),

                        _buildSettingsTile(
                          icon: Icons.help_outline_rounded,
                          title: "Ayuda y FAQ",
                          subtitle: "Preguntas y respuestas del sistema IA",
                          iconColor: AppColors.success,
                          onTap: _showFAQDialog,
                        ),

                        _buildSettingsTile(
                          icon: Icons.logout_rounded,
                          title: "Cerrar Sesión",
                          subtitle: "Salir de tu cuenta de forma segura",
                          iconColor: AppColors.danger,
                          onTap: () {
                            ref.read(authProvider.notifier).logout();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                        ),

                        const SizedBox(height: 25),
                        const Text(
                          "HealSkin v1.1.0 • Aplicación Dermatológica",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
                error: (err, stack) => Center(child: Text("Error al cargar perfil: $err")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))
            ]
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveNotificationTile() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_active_outlined, color: AppColors.warning),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Notificaciones de Citas",
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)
                  ),
                  Text(
                    "Alertas y avisos de telemedicina",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: _notificationsEnabled,
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() => _notificationsEnabled = val);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(val ? "Notificaciones activadas 🔔" : "Notificaciones silenciadas 🔕"),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}