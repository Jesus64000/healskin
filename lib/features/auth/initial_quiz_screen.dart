import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';

class InitialQuizScreen extends StatefulWidget {
  const InitialQuizScreen({super.key});

  @override
  State<InitialQuizScreen> createState() => _InitialQuizScreenState();
}

class _InitialQuizScreenState extends State<InitialQuizScreen> {
  String? _skinType;
  String? _glowFreq;
  String? _acneFreq;
  bool _isLoading = false;

  final _supabase = Supabase.instance.client;

  Future<void> _saveQuiz() async {
    if (_skinType == null || _glowFreq == null || _acneFreq == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor responde todas las preguntas")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('profiles').upsert({
        'id': userId,
        'skin_type': _skinType,
        'glow_frequency': _glowFreq,
        'has_acne': _acneFreq,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // ARREGLO AQUÍ: Verificamos si el widget sigue "vivo" antes de navegar
      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      // ARREGLO AQUÍ: También verificamos antes de mostrar el error
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e"), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.accentDark, // El rosa oscuro del PDF
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Queremos conocerte",
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Esto nos ayudará a personalizar tu experiencia.",
                  style: TextStyle(color: Colors.white70, fontSize: 16)),

              const SizedBox(height: 40),

              _buildQuestion("¿Cuál es tu tipo de piel?", ["Grasa", "Mixta", "Seca"], _skinType, (val) => setState(() => _skinType = val)),

              const SizedBox(height: 30),

              _buildQuestion("¿Con qué frecuencia notas brillo en el rostro?", ["Nunca", "Rara vez", "Siempre", "No lo sé"], _glowFreq, (val) => setState(() => _glowFreq = val)),

              const SizedBox(height: 30),

              _buildQuestion("¿Constantemente tienes acné o espinillas?", ["Nunca", "A veces", "Seguido"], _acneFreq, (val) => setState(() => _acneFreq = val)),

              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppColors.primary)
                      : const Text("Finalizar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(String title, List<String> options, String? selectedValue, Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 8, // Espacio horizontal entre chips
          runSpacing: 10, // Espacio vertical si saltan de línea
          children: options.map((option) {
            final isSelected = selectedValue == option;

            return Padding(
              padding: const EdgeInsets.only(right: 4.0), // El espacio que preguntabas
              child: ChoiceChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (_) => onSelect(option),
                selectedColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.15),

                // ESTO ES LO QUE HACE QUE EL TEXTO SE VEA
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.accentDark : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            );
          }).toList(), // Aquí es donde termina el .map y convierte a lista
        ),
      ],
    );
  }
}