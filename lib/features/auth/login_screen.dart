import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // Logo Estilizado
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.health_and_safety, size: 50, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                  "HealSkin",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary)
              ),
              const Text(
                  "Inicio de sesión",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary)
              ),
              const SizedBox(height: 50),

              _buildTextField(emailController, "Correo electrónico", Icons.email_outlined),
              const SizedBox(height: 20),
              _buildTextField(passController, "Contraseña", Icons.lock_outline, isObscure: true),

              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {}, // Funcionalidad para recuperar clave
                  child: const Text("¿Olvidaste tu contraseña?", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: authState.isLoading ? () {} : () async {
                  FocusScope.of(context).unfocus();
                  final errorMsg = await ref.read(authProvider.notifier).login(
                      emailController.text,
                      passController.text
                  );

                  if (!context.mounted) return;

                  if (errorMsg != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMsg),
                        backgroundColor: AppColors.danger,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
                child: authState.isLoading
                    ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : const Text("Aceptar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),

              const SizedBox(height: 40),
              // Sección "También puedes unirte por" del PDF
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text("También puedes unirte por", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialIcon(Icons.facebook, const Color(0xFF1877F2)),
                  const SizedBox(width: 20),
                  // Cambiamos Icons.google por Icons.g_mobiledata que sí existe
                  _socialIcon(Icons.g_mobiledata, Colors.redAccent),
                ],
              ),

              const SizedBox(height: 30),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: RichText(
                  text: const TextSpan(
                      text: "¿No tienes cuenta? ",
                      style: TextStyle(color: AppColors.textSecondary),
                      children: [
                        TextSpan(
                            text: "Regístrate aquí",
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
                        )
                      ]
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      // Cambiamos Icons.google por Icons.g_mobiledata o Icons.mail
      // Para efectos visuales de desarrollo, Icons.g_mobiledata se ve parecido
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isObscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary),
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}