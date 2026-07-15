import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import 'doctor_consultorio_location_screen.dart';
import '../../core/services/notification_service.dart';

// ============================================================================
// 🚀 CAPA DE DATOS: Provider del Perfil del Doctor
// ============================================================================
final doctorProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) throw Exception('Sesión de usuario no encontrada');

  // Traemos los datos específicos que configuró en el DoctorSetupScreen y perfil profesional
  final response = await supabase
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();

  return response;
});

// ============================================================================
// 📱 CAPA DE PRESENTACIÓN (UI)
// ============================================================================
class DoctorProfileView extends ConsumerStatefulWidget {
  const DoctorProfileView({super.key});

  @override
  ConsumerState<DoctorProfileView> createState() => _DoctorProfileViewState();
}

class _DoctorProfileViewState extends ConsumerState<DoctorProfileView> {
  bool _isUploadingAvatar = false;

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

      final fileExtension = croppedFile.path.split('.').last;
      final fileName = 'avatar_doc_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final storagePath = 'avatars/$fileName';

      await supabase.storage.from('scan_images').upload(storagePath, file);
      final publicUrl = supabase.storage.from('scan_images').getPublicUrl(storagePath);

      await supabase.from('profiles').update({
        'avatar_url': publicUrl,
      }).eq('id', userId);

      ref.invalidate(doctorProfileProvider);

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

  @override
  Widget build(BuildContext context) {
    // Escuchamos el estado del perfil en tiempo real
    final profileAsync = ref.watch(doctorProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: profileAsync.when(
        data: (profile) {
          // Extracción segura de datos con fallbacks
          final fullName = profile['full_name'] ?? 'Doctor';
          final specialty = profile['specialty'] ?? 'Especialidad no configurada';
          final license = profile['license_number'] ?? 'Licencia pendiente';
          final officeAddress = profile['office_address'] ?? 'Configurar consultorio';

          // Lógica para generar avatar dinámico con las iniciales
          final avatarInitials = fullName.trim().split(' ').take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(color: AppColors.primary),
                  title: const Text("Perfil Profesional", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
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
                              radius: 50,
                              backgroundColor: Colors.grey.shade100,
                              backgroundImage: (profile['avatar_url'] != null && (profile['avatar_url'] as String).isNotEmpty)
                                  ? NetworkImage(profile['avatar_url'] as String)
                                  : null,
                              child: _isUploadingAvatar
                                  ? const CircularProgressIndicator(color: AppColors.primary)
                                  : (profile['avatar_url'] == null || (profile['avatar_url'] as String).isEmpty
                                      ? Text(
                                          avatarInitials.isEmpty ? 'DR' : avatarInitials,
                                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)
                                        )
                                      : null),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text("Dr. $fullName", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text("$specialty • $license", style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 30),

                    // CONFIGURACIONES INTERACTIVAS
                    _buildMenuOption(
                      Icons.access_time,
                      "Horarios de Atención",
                      "Configura tu jornada laboral",
                      onTap: () => _showHorariosBottomSheet(context, profile['availability']),
                    ),
                    _buildMenuOption(
                      Icons.settings_suggest_outlined,
                      "Datos del Especialista",
                      "Especialidad, experiencia, biografía...",
                      onTap: () => _showEspecialistaBottomSheet(context, ref, profile),
                    ),
                    _buildMenuOption(
                      Icons.location_on_outlined,
                      "Ubicación de Clínica",
                      officeAddress,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DoctorConsultorioLocationScreen()),
                        ).then((_) => ref.invalidate(doctorProfileProvider));
                      },
                    ),
                    _buildMenuOption(
                      Icons.verified_user_outlined,
                      "Verificación de Licencia",
                      "Estado: Activa",
                      onTap: () => _showLicenciaBottomSheet(context, license, specialty),
                    ),
                    _buildMenuOption(
                      Icons.notifications_none,
                      "Probar Notificaciones",
                      "Emitir una alerta de prueba en 5 seg.",
                      onTap: () async {
                        final notificationService = NotificationService();
                        await notificationService.requestPermissions();
                        
                        if (context.mounted) {
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
                            id: 9998,
                            title: "¡Prueba de Notificación Funcional! 🎉",
                            body: "El canal de comunicación local de HealSkin está operando correctamente en tu dispositivo.",
                          );
                        });
                      },
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                      child: Divider(),
                    ),

                    // BOTÓN DE CERRAR SESIÓN
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ListTile(
                        onTap: () {
                          ref.read(authProvider.notifier).logout();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (route) => false,
                          );
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.logout, color: AppColors.danger),
                        ),
                        title: const Text("Cerrar Sesión", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.danger),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 50),
                const SizedBox(height: 10),
                Text("Error al cargar perfil: $err", textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
                const SizedBox(height: 20),
                // Botón de rescate si el fetch falla irremediablemente
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Forzar Cierre de Sesión"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHorariosBottomSheet(BuildContext context, String? currentAvailability) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _HorariosConfigBottomSheet(currentAvailability: currentAvailability);
      },
    );
  }

  void _showLicenciaBottomSheet(BuildContext context, String license, String specialty) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _LicenciaDetailBottomSheet(license: license, specialty: specialty);
      },
    );
  }

  Widget _buildMenuOption(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        ),
      ),
    );
  }

  void _showEspecialistaBottomSheet(BuildContext context, WidgetRef ref, Map<String, dynamic> profile) {
    final TextEditingController specialtyController = TextEditingController(text: profile['specialty'] ?? '');
    final TextEditingController experienceController = TextEditingController(text: (profile['years_experience'] ?? '').toString());
    final TextEditingController bioController = TextEditingController(text: profile['bio'] ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20, right: 20, top: 20
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Datos del Especialista", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 15),

                    const Text("Especialidad *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: specialtyController,
                      decoration: InputDecoration(
                        hintText: "Ej. Dermatólogo Clínico y Cosmético",
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),

                    const Text("Años de Experiencia", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: experienceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Ej. 5",
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),

                    const Text("Biografía / Perfil Profesional", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: bioController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Escribe un breve resumen sobre tu trayectoria y enfoque...",
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () async {
                          final spec = specialtyController.text.trim();
                          if (spec.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("La especialidad es obligatoria"), backgroundColor: AppColors.danger));
                            return;
                          }

                          final exp = int.tryParse(experienceController.text.trim());
                          final bio = bioController.text.trim();

                          setState(() => isSaving = true);
                          try {
                            final user = Supabase.instance.client.auth.currentUser;
                            if (user != null) {
                              await Supabase.instance.client.from('profiles').update({
                                'specialty': spec,
                                'years_experience': exp,
                                'bio': bio.isEmpty ? null : bio,
                              }).eq('id', user.id);

                              ref.invalidate(doctorProfileProvider);

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Datos actualizados con éxito"), backgroundColor: AppColors.success));
                              }
                            }
                          } catch (e) {
                            setState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.danger));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Guardar Cambios", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }
}

class _HorariosConfigBottomSheet extends ConsumerStatefulWidget {
  final String? currentAvailability;
  const _HorariosConfigBottomSheet({this.currentAvailability});

  @override
  ConsumerState<_HorariosConfigBottomSheet> createState() => _HorariosConfigBottomSheetState();
}

class _HorariosConfigBottomSheetState extends ConsumerState<_HorariosConfigBottomSheet> {
  final Map<String, bool> _diasActivos = {
    "Lunes": true,
    "Martes": true,
    "Miércoles": true,
    "Jueves": true,
    "Viernes": true,
    "Sábado": false,
    "Domingo": false,
  };

  final Map<String, String> _horasDia = {
    "Lunes": "08:00 AM - 04:00 PM",
    "Martes": "08:00 AM - 04:00 PM",
    "Miércoles": "08:00 AM - 04:00 PM",
    "Jueves": "08:00 AM - 04:00 PM",
    "Viernes": "08:00 AM - 04:00 PM",
    "Sábado": "09:00 AM - 01:00 PM",
    "Domingo": "Cerrado",
  };

  @override
  void initState() {
    super.initState();
    if (widget.currentAvailability != null && widget.currentAvailability!.startsWith('{')) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(widget.currentAvailability!);
        decoded.forEach((day, time) {
          if (_diasActivos.containsKey(day)) {
            _diasActivos[day] = time != 'Cerrado';
            _horasDia[day] = time;
          }
        });
      } catch (e) {
        debugPrint("Error parsing initial availability: $e");
      }
    }
  }

  bool _isSaving = false;

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hourStr = (hour == 0 ? 12 : hour).toString().padLeft(2, '0');
    return "$hourStr:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Horarios de Atención",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Configura los días y horarios en los que los pacientes pueden agendar citas en tu consultorio virtual o presencial.",
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView(
              shrinkWrap: true,
              children: _diasActivos.keys.map((dia) {
                final activo = _diasActivos[dia]!;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Checkbox(
                        value: activo,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _diasActivos[dia] = val ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          dia,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: activo ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (activo)
                        InkWell(
                          onTap: () async {
                            final pickedStart = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 8, minute: 0),
                              helpText: "Hora de apertura de $dia",
                              builder: (context, child) {
                                return MediaQuery(
                                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedStart == null) return;
                            if (!context.mounted) return;
                            final pickedEnd = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 16, minute: 0),
                              helpText: "Hora de cierre de $dia",
                              builder: (context, child) {
                                return MediaQuery(
                                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedEnd == null) return;

                            setState(() {
                              _horasDia[dia] = "${_formatTimeOfDay(pickedStart)} - ${_formatTimeOfDay(pickedEnd)}";
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                            ),
                            child: Text(
                              _horasDia[dia]!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      else
                        const Text(
                          "No laborable",
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : () async {
              setState(() => _isSaving = true);
              try {
                final Map<String, String> dataToSave = {};
                _diasActivos.forEach((day, active) {
                  if (active) {
                    dataToSave[day] = _horasDia[day] ?? "08:00 AM - 04:00 PM";
                  } else {
                    dataToSave[day] = "Cerrado";
                  }
                });
                
                final jsonStr = jsonEncode(dataToSave);
                final supabase = Supabase.instance.client;
                final userId = supabase.auth.currentUser!.id;
                
                await supabase.from('profiles').update({
                  'availability': jsonStr,
                }).eq('id', userId);
                
                ref.invalidate(doctorProfileProvider);
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Horarios de atención actualizados con éxito."),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error al guardar horarios: $e"),
                      backgroundColor: AppColors.danger,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isSaving = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Guardar Horarios", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _LicenciaDetailBottomSheet extends StatelessWidget {
  final String license;
  final String specialty;

  const _LicenciaDetailBottomSheet({required this.license, required this.specialty});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.verified, color: AppColors.primary, size: 60),
          const SizedBox(height: 12),
          const Text(
            "Licencia Médica Verificada",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Tu identidad profesional ha sido validada por el comité médico de HealSkin y las autoridades correspondientes.",
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Tarjeta de Credenciales
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "HealSkin Professional Card",
                      style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    Icon(Icons.shield, color: Colors.white.withOpacity(0.8), size: 20),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  "Nº REGISTRO SANITARIO",
                  style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold),
                ),
                Text(
                  license,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ESPECIALIDAD",
                          style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          specialty,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "ESTADO",
                          style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.white, size: 10),
                              SizedBox(width: 4),
                              Text(
                                "VÁLIDO",
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Cerrar", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}