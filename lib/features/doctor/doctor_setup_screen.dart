import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import 'doctor_dashboard.dart';

class DoctorSetupScreen extends StatefulWidget {
  const DoctorSetupScreen({super.key});

  @override
  State<DoctorSetupScreen> createState() => _DoctorSetupScreenState();
}

class _DoctorSetupScreenState extends State<DoctorSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();

  String? _selectedSpecialty;
  bool _isLoading = false;

  final List<String> _specialties = [
    "Dermatología Clínica",
    "Dermatología Estética",
    "Dermatología Pediátrica",
    "Oncología Cutánea",
    "Médico General"
  ];

  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _saveDoctorProfile() async {
    if (!_formKey.currentState!.validate() || _selectedSpecialty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor completa todos los campos"), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("Usuario no encontrado");

      // 🚀 ARQUITECTURA: Usamos 'update' en lugar de 'upsert' porque el perfil ya
      // existe (se creó en el SignUp). Solo lo estamos actualizando.
      await _supabase.from('profiles').update({
        'specialty': _selectedSpecialty,
        'license_number': _licenseController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      if (!mounted) return;

      // 🚀 UX/NEGOCIO: Lanzamos el flujo de contención legal
      _showApprovalPendingDialog();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e"), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showApprovalPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Obligamos al usuario a interactuar
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, color: AppColors.primary, size: 44),
            SizedBox(height: 12),
            Text(
              "Perfil en Revisión",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: const Text(
          "Tus credenciales han sido enviadas exitosamente. Por políticas de seguridad, nuestro equipo médico verificará tu licencia.\n\nTe notificaremos en cuanto tu cuenta sea activada para que puedas comenzar a atender.",
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          textAlign: TextAlign.justify,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              // Lo enviamos al Dashboard. Como 'is_approved' es false, en un
              // futuro Sprint haremos que el Dashboard le muestre un banner de "Cuenta inactiva".
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const DoctorDashboard()),
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
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medical_services, size: 60, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text("Perfil Profesional", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)),
                  const SizedBox(height: 10),
                  const Text("Completa tus credenciales para poder atender a los pacientes en HealSkin.", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 40),

                  // CAMPO: ESPECIALIDAD
                  const Text("Especialidad", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedSpecialty,
                    hint: const Text("Selecciona tu especialidad", style: TextStyle(color: Colors.black54)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                    items: _specialties.map((String specialty) {
                      return DropdownMenuItem<String>(
                        value: specialty,
                        child: Text(specialty),
                      );
                    }).toList(),
                    onChanged: (newValue) => setState(() => _selectedSpecialty = newValue),
                  ),
                  const SizedBox(height: 25),

                  // CAMPO: LICENCIA MÉDICA
                  const Text("Número de Colegiado / Licencia", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _licenseController,
                    decoration: InputDecoration(
                      hintText: "Ej. MPPS-123456",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                    validator: (value) => value == null || value.isEmpty ? "La licencia es obligatoria" : null,
                  ),
                  const SizedBox(height: 50),

                  // BOTÓN GUARDAR (Refactorizado el texto)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveDoctorProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                          : const Text("Enviar Credenciales", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}