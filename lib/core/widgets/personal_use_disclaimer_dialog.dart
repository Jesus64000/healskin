import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

class PersonalUseDisclaimerDialog extends StatelessWidget {
  const PersonalUseDisclaimerDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool alreadyShown = prefs.getBool('personal_use_disclaimer_accepted') ?? false;
    if (!alreadyShown && context.mounted) {
      show(context);
    }
  }

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PersonalUseDisclaimerDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado llamativo con degradado
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Uso Personal e Individual",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Aviso de Confidencialidad y Precisión Clínica",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido explicativo
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Estimado usuario:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "HealSkin es una plataforma de gestión dermatológica personalizada de uso estrictamente individual.",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildReasonItem(
                      icon: Icons.person_outline,
                      title: "1. Perfil Único y Biométrico",
                      desc: "Tus escaneos de IA, tipo de piel y fototipo pertenecen a tu perfil biológico específico.",
                    ),
                    const SizedBox(height: 12),

                    _buildReasonItem(
                      icon: Icons.analytics_outlined,
                      title: "2. Evita Interferencias en la IA",
                      desc: "Prestar tu dispositivo o cuenta a terceros para analizar su piel corromperá tu historial evolutivo y generará métricas o alertas erróneas.",
                    ),
                    const SizedBox(height: 12),

                    _buildReasonItem(
                      icon: Icons.medical_information_outlined,
                      title: "3. Recetas y Alarmas Personalizadas",
                      desc: "Las indicaciones médicas y recordatorios son formulados exclusivamente para tu tratamiento dermatológico.",
                    ),
                    const SizedBox(height: 12),

                    _buildReasonItem(
                      icon: Icons.devices_outlined,
                      title: "4. Recomendación de Uso",
                      desc: "Cada persona debe contar con su propia cuenta y dispositivo para garantizar la seguridad y privacidad del seguimiento clínico.",
                    ),
                  ],
                ),
              ),
            ),

            // Pie con Botón de Entendido
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('personal_use_disclaimer_accepted', true);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    "Entendido y Aceptar",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
