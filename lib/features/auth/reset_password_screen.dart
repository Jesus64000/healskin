import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'auth_provider.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  final _passFocus = FocusNode();
  final _confirmPassFocus = FocusNode();

  bool _isPassObscured = true;
  bool _isConfirmPassObscured = true;

  @override
  void dispose() {
    _passController.dispose();
    _confirmPassController.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final errorMsg = await ref.read(authProvider.notifier).updatePassword(_passController.text);

      if (!mounted) return;

      if (errorMsg == null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: AppColors.backgroundLight,
            title: const Text(
              "Contraseña Actualizada",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 20,
              ),
            ),
            content: const Text(
              "¡Hola! Tu contraseña ha sido restablecida exitosamente. Por motivos de seguridad, por favor inicia sesión nuevamente con tus nuevas credenciales.",
              textAlign: TextAlign.justify,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  Navigator.of(dialogContext).pop(); // Cierra el diálogo
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 2,
                ),
                child: const Text("Entendido", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Image.asset(
                    'imagenes/logo_sin_fondo.png',
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 25),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.vpn_key_outlined, color: AppColors.primary, size: 26),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Restablecer Contraseña",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  "¡Hola! Crea una nueva contraseña segura para tu cuenta. Recuerda que debe contener letras y números.",
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                _buildTextFormField(
                  controller: _passController,
                  focusNode: _passFocus,
                  nextFocus: _confirmPassFocus,
                  label: "Nueva Contraseña",
                  icon: Icons.lock_outline,
                  isObscure: _isPassObscured,
                  onToggleVisibility: () => setState(() => _isPassObscured = !_isPassObscured),
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Ingresa tu nueva contraseña";
                    if (val.length < 6) return "La contraseña debe tener al menos 6 caracteres";
                    if (!RegExp(r'[a-zA-Z]').hasMatch(val) || !RegExp(r'[0-9]').hasMatch(val)) {
                      return "Debe contener al menos una letra y un número";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _confirmPassController,
                  focusNode: _confirmPassFocus,
                  label: "Confirmar Contraseña",
                  icon: Icons.lock_reset_outlined,
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
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Guardar nueva contraseña",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
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
        textInputAction: textInputAction,
        onFieldSubmitted: (_) {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          } else {
            _submit();
          }
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
