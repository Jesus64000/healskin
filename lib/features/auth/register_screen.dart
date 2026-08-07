import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import 'auth_provider.dart';
import 'initial_quiz_screen.dart';
import '../doctor/doctor_setup_screen.dart'; // ✅ Importación conectada

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de Texto
  final _nameController = TextEditingController();
  final _dniController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  // Nodos de Enfoque
  final _nameFocus = FocusNode();
  final _dniFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmPassFocus = FocusNode();

  // Variables de Estado
  String _selectedRole = 'patient';
  String _dniPrefix = 'V'; // Prefijo de la cédula V/E/J/P
  bool _isPassObscured = true;
  bool _isConfirmPassObscured = true;
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _passController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _passController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _dniController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _nameFocus.dispose();
    _dniFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  void _submitRegistration() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Debes aceptar los Términos y Condiciones"),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      FocusScope.of(context).unfocus();

      final errorMsg = await ref.read(authProvider.notifier).signUp(
          _emailController.text,
          _passController.text,
          _nameController.text,
          _selectedRole,
          "$_dniPrefix-${_dniController.text.trim()}"
      );

      if (!mounted) return;

      if (errorMsg == null) {
        // Enrutamiento según el rol
        if (_selectedRole == 'patient') {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const InitialQuizScreen())
          );
        } else {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DoctorSetupScreen())
          );
        }
      } else if (errorMsg.contains("confirma tu correo") || errorMsg.contains("verificación")) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: AppColors.backgroundLight,
            title: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mark_email_read_outlined, color: AppColors.success, size: 44),
                SizedBox(height: 12),
                Text(
                  "Verificación de Correo",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: const Text(
              "¡Cuenta registrada con éxito!\n\nPor favor, revisa tu bandeja de entrada y confirma tu correo electrónico utilizando el enlace de verificación enviado para activar tu cuenta antes de ingresar.",
              style: TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Cierra el diálogo
                  Navigator.of(context).pop(); // Vuelve al login
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 2,
                ),
                child: const Text("Entendido", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      } else {
        final isDuplicated = errorMsg.toLowerCase().contains("already registered") || 
                             errorMsg.toLowerCase().contains("ya registrado") || 
                             errorMsg.toLowerCase().contains("already exists");
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDuplicated 
                  ? "Esta cuenta ya existe. ¿Deseas iniciar sesión en su lugar?" 
                  : errorMsg,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: isDuplicated ? AppColors.warning : AppColors.danger,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: isDuplicated 
                ? SnackBarAction(
                    label: "INGRESAR",
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.of(context).pop(); // Volver al login
                    },
                  )
                : null,
          ),
        );
      }
    }
  }

  Widget _buildPasswordRequirements() {
    final text = _passController.text;
    final hasMinLength = text.length >= 6;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(text);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(text);
    final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(text);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Requisitos para tu Contraseña:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _reqItem("Mínimo 6 caracteres", hasMinLength),
          _reqItem("Al menos una letra mayúscula (A-Z)", hasUppercase),
          _reqItem("Al menos una letra minúscula (a-z)", hasLowercase),
          _reqItem("Al menos un carácter especial (@, #, \$, %, !, entre otros)", hasSpecialChar),
        ],
      ),
    );
  }

  Widget _reqItem(String label, bool isFulfilled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            isFulfilled ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isFulfilled ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isFulfilled ? AppColors.success : AppColors.textSecondary,
                fontWeight: isFulfilled ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                  "Crea tu cuenta",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.1)
              ),
              const SizedBox(height: 10),
              const Text(
                  "Únete a la revolución dermatológica HealSkin y cuida tu piel.",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16)
              ),
              const SizedBox(height: 30),

              _buildTextFormField(
                controller: _nameController,
                focusNode: _nameFocus,
                nextFocus: _dniFocus,
                label: "Nombres y Apellidos Completos",
                icon: Icons.person_outline,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
                ],
                validator: Validators.validateFullName,
              ),
              const SizedBox(height: 15),

              _buildTextFormField(
                controller: _dniController,
                focusNode: _dniFocus,
                nextFocus: _emailFocus,
                label: "Cédula / Documento de Identidad",
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_dniPrefix == 'P' ? 10 : (_dniPrefix == 'J' ? 9 : 8)),
                ],
                customPrefixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.badge_outlined, color: AppColors.primary),
                    const SizedBox(width: 4),
                    DropdownButton<String>(
                      value: _dniPrefix,
                      underline: const SizedBox(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _dniPrefix = newValue;
                          });
                        }
                      },
                      items: <String>['V', 'E', 'J', 'P'].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
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
                validator: Validators.validateDni,
              ),
              const SizedBox(height: 15),

              _buildTextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                nextFocus: _passFocus,
                label: "Correo Electrónico",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Ingresa tu correo electrónico";
                  if (!_isValidEmail(val.trim())) return "Ingresa un correo electrónico válido";
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Requisitos interactivos de contraseña explicados visualmente (img4)
              _buildPasswordRequirements(),
              const SizedBox(height: 12),

              _buildTextFormField(
                controller: _passController,
                focusNode: _passFocus,
                nextFocus: _confirmPassFocus,
                label: "Contraseña",
                icon: Icons.lock_outline,
                isObscure: _isPassObscured,
                onToggleVisibility: () => setState(() => _isPassObscured = !_isPassObscured),
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 15),

              _buildTextFormField(
                controller: _confirmPassController,
                focusNode: _confirmPassFocus,
                label: "Confirmar Contraseña",
                icon: Icons.lock_reset,
                isObscure: _isConfirmPassObscured,
                onToggleVisibility: () => setState(() => _isConfirmPassObscured = !_isConfirmPassObscured),
                textInputAction: TextInputAction.done,
                validator: (val) {
                  if (val == null || val.isEmpty) return "Confirma tu contraseña";
                  if (val != _passController.text) return "Las contraseñas no coinciden";
                  return null;
                },
              ),
              const SizedBox(height: 30),

              const Text("¿Quién eres?", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 15),
              Row(
                children: [
                  _roleChip("Soy Paciente", 'patient'),
                  const SizedBox(width: 10),
                  _roleChip("Soy Doctor", 'doctor'),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      "Acepto los Términos de Servicio y la Política de Privacidad de datos médicos.",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: authState.isLoading ? null : _submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                ),
                child: authState.isLoading
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    SizedBox(width: 15),
                    Text("Creando cuenta...", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))
                  ],
                )
                    : const Text("Registrarme", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String label, String role) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]
                : [],
          ),
          child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              )
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String label,
    required IconData icon,
    bool isObscure = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    Widget? customPrefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isObscure,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        onFieldSubmitted: (_) {
          if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
        },
        validator: validator,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: customPrefixIcon ?? Icon(icon, color: AppColors.primary),
          suffixIcon: onToggleVisibility != null
              ? IconButton(
            icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
            onPressed: onToggleVisibility,
          )
              : null,
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
          errorStyle: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}