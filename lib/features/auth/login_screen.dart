import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'auth_provider.dart';
import 'register_screen.dart';
import 'initial_quiz_screen.dart';
import 'forgot_password_screen.dart';
import 'reset_password_screen.dart';
import 'complete_profile_screen.dart'; // 🚀 NUEVO IMPORT
import '../admin/admin_dashboard.dart';
import '../doctor/doctor_dashboard.dart';
import '../doctor/doctor_setup_screen.dart';
import '../doctor/doctor_pending_approval_screen.dart';
import '../patient/patient_dashboard.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController emailController;
  late final TextEditingController passController;

  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _isPassObscured = true;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Si ya estamos en recuperación de contraseña al cargar la pantalla, abrir la pantalla de restablecimiento
    if (authState.isPasswordRecovery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(authProvider.notifier).clearPasswordRecoveryFlag();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        );
      });
    }

    // Escuchar cambios de estado para navegación reactiva (especialmente útil en OAuth de Google)
    ref.listen<HealSkinAuthState>(authProvider, (previous, next) {
      if (next.isPasswordRecovery) {
        ref.read(authProvider.notifier).clearPasswordRecoveryFlag();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        );
        return;
      }

      if (next.session != null && !next.isLoading && next.isInitialized) {
        final role = next.role;
        Widget nextScreen;

        if (next.isProfileIncomplete) {
          nextScreen = const CompleteProfileScreen();
        } else if (role == UserRole.admin) {
          nextScreen = const AdminDashboard();
        } else if (role == UserRole.doctor) {
          if (!next.hasCompletedSetup) {
            nextScreen = const DoctorSetupScreen();
          } else if (!next.isApproved) {
            nextScreen = const DoctorPendingApprovalScreen();
          } else {
            nextScreen = const DoctorDashboard();
          }
        } else {
          nextScreen = next.hasCompletedQuiz ? const PatientDashboard() : const InitialQuizScreen();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 25),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.health_and_safety, size: 44, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                const Text("HealSkin", textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const Text("Inicio de sesión", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 20),

                _buildTextFormField(
                  controller: emailController,
                  focusNode: _emailFocus,
                  nextFocus: _passFocus,
                  label: "Correo electrónico",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Por favor ingresa tu correo";
                    }
                    if (!_isValidEmail(val.trim())) {
                      return "Ingresa un correo electrónico válido";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildTextFormField(
                  controller: passController,
                  focusNode: _passFocus,
                  label: "Contraseña",
                  icon: Icons.lock_outline,
                  isObscure: _isPassObscured,
                  onToggleVisibility: () => setState(() => _isPassObscured = !_isPassObscured),
                  textInputAction: TextInputAction.done,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return "Por favor ingresa tu contraseña";
                    }
                    if (val.length < 6) {
                      return "La contraseña debe tener al menos 6 caracteres";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      );
                    },
                    child: const Text("¿Olvidaste tu contraseña?", style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ),
                ),

                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: authState.isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {
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
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Aceptar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),

                const SizedBox(height: 25),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: const Text("O ingresa rápidamente con", style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 15),
                Center(
                  child: InkWell(
                    onTap: authState.isLoading ? null : () async {
                      final errorMsg = await ref.read(authProvider.notifier).loginWithGoogle();
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
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.g_mobiledata, color: Colors.redAccent, size: 28),
                          const SizedBox(width: 8),
                          const Text(
                            "Continuar con Google",
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: RichText(
                    text: const TextSpan(
                        text: "¿No tienes cuenta? ",
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        children: [TextSpan(text: "Regístrate aquí", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))]
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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