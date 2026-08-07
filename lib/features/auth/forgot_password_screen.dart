import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final errorMsg = await ref.read(authProvider.notifier).forgotPassword(_emailController.text);

      if (!mounted) return;

      if (errorMsg == null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: AppColors.backgroundLight,
            title: const Text(
              "Enlace Enviado",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 20,
              ),
            ),
            content: const Text(
              "¡Hola! Hemos enviado un enlace de recuperación a tu correo electrónico. Por favor, revisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.",
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
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
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
                const SizedBox(height: 15),
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
                    Icon(Icons.lock_reset_outlined, color: AppColors.primary, size: 26),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Recuperación de Clave",
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
                  "¡Hola! Introduce tu dirección de correo electrónico a continuación y te enviaremos un enlace seguro para restablecer tu contraseña.",
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    style: const TextStyle(color: AppColors.textPrimary),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Por favor ingresa tu correo electrónico";
                      }
                      if (!_isValidEmail(val.trim())) {
                        return "Ingresa un correo electrónico válido";
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                      labelText: "Correo electrónico",
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                      errorStyle: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
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
                          "Enviar enlace de recuperación",
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
}
