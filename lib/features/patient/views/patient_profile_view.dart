import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/auth_provider.dart';
import '../../auth/profile_provider.dart';
import '../../auth/initial_quiz_screen.dart';
import '../../auth/login_screen.dart';
import 'patient_reminders_view.dart';

class PatientProfileView extends ConsumerStatefulWidget {
  const PatientProfileView({super.key});

  @override
  ConsumerState<PatientProfileView> createState() => _PatientProfileViewState();
}

class _PatientProfileViewState extends ConsumerState<PatientProfileView> {
  bool _isUploadingAvatar = false;
  bool _isSavingName = false;
  bool _notificationsEnabled = true;

  // --- 📸 CAPTURA Y SUBIDA DE FOTO DE PERFIL A STORAGE ---
  Future<void> _updateAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile == null) return;
    
    setState(() => _isUploadingAvatar = true);
    
    try {
      final file = File(pickedFile.path);
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

  // --- ✍️ ACTUALIZAR NOMBRE COMPLETO ---
  Future<void> _updateName(String newName) async {
    if (newName.trim().isEmpty) return;
    
    setState(() => _isSavingName = true);
    
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      
      await supabase.from('profiles').update({
        'full_name': newName.trim(),
      }).eq('id', userId);
      
      ref.invalidate(userProfileProvider);
      
      if (mounted) {
        Navigator.pop(context); // Cerramos el Modal
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("¡Nombre de perfil actualizado! 📝", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error al actualizar nombre: $e"),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  // --- 📝 MODAL BOTTOM SHEET DE EDICIÓN DE NOMBRE ---
  void _showEditProfileModal(String currentName) {
    final textController = TextEditingController(text: currentName);
    
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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                      "Actualiza tu nombre completo de presentación.",
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: textController,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: "Nombre Completo",
                        prefixIcon: const Icon(Icons.person_rounded, color: AppColors.primary),
                        fillColor: AppColors.surfaceLight,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSavingName 
                            ? null 
                            : () async {
                                setModalState(() => _isSavingName = true);
                                await _updateName(textController.text);
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
              expandedHeight: 80,
              floating: true,
              backgroundColor: AppColors.backgroundLight,
              elevation: 0,
              flexibleSpace: const FlexibleSpaceBar(
                titlePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                title: Text(
                  "Tu Perfil",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18)
                ),
              ),

            ),

            SliverToBoxAdapter(
              child: profileAsync.when(
                data: (profile) {
                  final String name = profile?['full_name'] ?? "Usuario";
                  final String email = authState.session?.user.email ?? "Sin correo";
                  final String skinTypeRaw = profile?['skin_type'] ?? 'normal';
                  
                  // Formateo visual del tipo de piel en mayúsculas
                  final String skinType = skinTypeRaw.toUpperCase();
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
                          onPressed: () => _showEditProfileModal(name),
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
                        
                        // Interruptor de Notificaciones Interactivo
                        _buildInteractiveNotificationTile(),

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
                          "HealSkin v1.1.0 • Ecosistema Clínico",
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