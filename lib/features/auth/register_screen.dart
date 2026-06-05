import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
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
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  // Nodos de Enfoque
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmPassFocus = FocusNode();

  // Variables de Estado
  String _selectedRole = 'patient';
  bool _isPassObscured = true;
  bool _isConfirmPassObscured = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _nameFocus.dispose();
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
          _selectedRole
      );

      if (!mounted) return;

      if (errorMsg == null) {
        // 🔥 ENRUTAMIENTO INTELIGENTE SEGÚN EL ROL
        if (_selectedRole == 'patient') {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const InitialQuizScreen())
          );
        } else {
          // Si es Doctor, va a su pantalla de configuración profesional
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DoctorSetupScreen())
          );
        }
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
              const SizedBox(height: 40),

              _buildTextFormField(
                controller: _nameController,
                focusNode: _nameFocus,
                nextFocus: _emailFocus,
                label: "Nombre Completo",
                icon: Icons.person_outline,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Ingresa tu nombre completo";
                  if (val.trim().length < 3) return "El nombre debe tener al menos 3 caracteres";
                  if (RegExp(r'[0-9]').hasMatch(val)) return "El nombre no debe contener números";
                  return null;
                },
              ),
              const SizedBox(height: 15),

              _buildTextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                nextFocus: _passFocus,
                label: "Email",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Ingresa tu correo electrónico";
                  if (!_isValidEmail(val.trim())) return "Ingresa un correo electrónico válido";
                  return null;
                },
              ),
              const SizedBox(height: 15),

              _buildTextFormField(
                controller: _passController,
                focusNode: _passFocus,
                nextFocus: _confirmPassFocus,
                label: "Contraseña",
                icon: Icons.lock_outline,
                isObscure: _isPassObscured,
                onToggleVisibility: () => setState(() => _isPassObscured = !_isPassObscured),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Ingresa tu contraseña";
                  if (val.length < 6) return "La contraseña debe tener al menos 6 caracteres";
                  if (!RegExp(r'[a-zA-Z]').hasMatch(val) || !RegExp(r'[0-9]').hasMatch(val)) {
                    return "Debe contener al menos una letra y un número";
                  }
                  return null;
                },
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
        onFieldSubmitted: (_) {
          if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
        },
        validator: validator,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary),
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