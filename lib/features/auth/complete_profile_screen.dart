import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import 'auth_provider.dart';
import 'splash_screen.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dniController = TextEditingController();
  final _licenseController = TextEditingController();

  UserRole _selectedRole = UserRole.patient;
  String _dniPrefix = 'V'; // Prefijo de la cédula V/E
  String? _selectedSpecialty;
  bool _isLoading = false;

  final List<String> _specialties = [
    "Dermatología Clínica",
    "Dermatología Estética",
    "Dermatología Pediátrica",
    "Oncología Cutánea"
  ];

  @override
  void initState() {
    super.initState();
    // Pre-cargar el nombre desde la metadata de Google si está disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).session?.user;
      if (user != null) {
        final String? fullName = user.userMetadata?['full_name'] as String? ?? user.userMetadata?['name'] as String?;
        if (fullName != null && fullName.isNotEmpty) {
          _nameController.text = fullName;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dniController.dispose();
    _licenseController.dispose();
    super.dispose();
  }


  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedRole == UserRole.doctor) {
      if (_selectedSpecialty == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor selecciona tu especialidad médica"), backgroundColor: AppColors.warning),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final errorMsg = await ref.read(authProvider.notifier).completeProfile(
      fullName: _nameController.text.trim(),
      role: _selectedRole,
      identificationId: "${_dniPrefix}-${_dniController.text.trim()}",
      specialty: _selectedRole == UserRole.doctor ? _selectedSpecialty : null,
      licenseNumber: _selectedRole == UserRole.doctor ? _licenseController.text.trim() : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (errorMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar perfil: $errorMsg"), backgroundColor: AppColors.danger),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✨ Perfil completado correctamente"),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.surfaceDark.withValues(alpha: 0.4),
              AppColors.backgroundLight,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- CABECERA DE LOGO ---
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.health_and_safety,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Completar Perfil",
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Necesitamos unos datos adicionales para tu cuenta",
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),

                    // --- CAMPO: NOMBRE COMPLETO ---
                    const Text(
                      "Nombres y Apellidos Completos",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Ej. Ana Pérez",
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: AppColors.danger),
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                      ],
                      validator: Validators.validateFullName,
                    ),
                    const SizedBox(height: 20),

                    // --- CAMPO: CÉDULA/DNI ---
                    const Text(
                      "Cédula / DNI",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dniController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(_dniPrefix == 'P' ? 10 : (_dniPrefix == 'J' ? 9 : 8)),
                      ],
                      decoration: InputDecoration(
                        hintText: "Ej. 24890312",
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 12),
                            const Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
                            const SizedBox(width: 4),
                            DropdownButton<String>(
                              value: _dniPrefix,
                              underline: const SizedBox(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _dniPrefix = newValue;
                                    final maxLen = _dniPrefix == 'P' ? 10 : (_dniPrefix == 'J' ? 9 : 8);
                                    if (_dniController.text.length > maxLen) {
                                      _dniController.text = _dniController.text.substring(0, maxLen);
                                    }
                                  });
                                }
                              },
                              items: <String>['V', 'E', 'J', 'P'].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                );
                              }).toList(),
                            ),
                            const SizedBox(
                              height: 20,
                              child: VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: AppColors.danger),
                        ),
                      ),
                      validator: Validators.validateDni,
                    ),
                    const SizedBox(height: 25),

                    // --- SELECCIÓN DE ROL ---
                    const Text(
                      "¿Cuál es tu rol en HealSkin?",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Tarjeta Paciente
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedRole = UserRole.patient),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedRole == UserRole.patient ? AppColors.primary : Colors.black.withValues(alpha: 0.05),
                                  width: _selectedRole == UserRole.patient ? 2 : 1,
                                ),
                                boxShadow: [
                                  if (_selectedRole == UserRole.patient)
                                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.spa_outlined,
                                    size: 32,
                                    color: _selectedRole == UserRole.patient ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Paciente",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedRole == UserRole.patient ? AppColors.primary : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Quiero escanear mi piel",
                                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Tarjeta Médico
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedRole = UserRole.doctor),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedRole == UserRole.doctor ? AppColors.primary : Colors.black.withValues(alpha: 0.05),
                                  width: _selectedRole == UserRole.doctor ? 2 : 1,
                                ),
                                boxShadow: [
                                  if (_selectedRole == UserRole.doctor)
                                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.medical_services_outlined,
                                    size: 32,
                                    color: _selectedRole == UserRole.doctor ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Médico",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedRole == UserRole.doctor ? AppColors.primary : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Quiero atender pacientes",
                                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // --- CAMPOS DINÁMICOS PARA MÉDICO ---
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  "Credenciales Médicas",
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),

                            // Especialidad
                            const Text(
                              "Especialidad",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _selectedSpecialty,
                              hint: const Text("Selecciona tu especialidad", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              items: _specialties.map((String specialty) {
                                return DropdownMenuItem<String>(
                                  value: specialty,
                                  child: Text(specialty),
                                );
                              }).toList(),
                              onChanged: (newValue) => setState(() => _selectedSpecialty = newValue),
                            ),
                            const SizedBox(height: 15),

                            // Licencia Médica
                            const Text(
                              "Número de Licencia / Colegiado",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _licenseController,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: "Ej. MPPS-12345",
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              validator: (value) {
                                if (_selectedRole == UserRole.doctor && (value == null || value.trim().isEmpty)) {
                                  return "El número de licencia es obligatorio";
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      crossFadeState: _selectedRole == UserRole.doctor ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                    const SizedBox(height: 40),

                    // --- BOTÓN: ENVIAR ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 2,
                          shadowColor: AppColors.primary.withValues(alpha: 0.3),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                "Guardar y Continuar",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
