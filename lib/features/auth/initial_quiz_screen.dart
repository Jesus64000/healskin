import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../patient/patient_dashboard.dart';

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

  // 🚀 Cálculo dinámico del progreso del cuestionario
  double get _progress {
    double p = 0.0;
    if (_skinType != null) p += 0.33;
    if (_glowFreq != null) p += 0.33;
    if (_acneFreq != null) p += 0.34;
    return p;
  }

  // 🩺 Cálculo dinámico del paso actual (Humano-legible)
  int get _currentStep {
    if (_skinType == null) return 1;
    if (_glowFreq == null) return 2;
    if (_acneFreq == null) return 3;
    return 3;
  }

  Future<void> _saveQuiz() async {
    if (_skinType == null || _glowFreq == null || _acneFreq == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor responde todas las preguntas del cuestionario"),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser!.id;

      // 🩺 MAPEO CLÍNICO SEGURO: Convertimos a los tags minúsculos exactos de la base de datos
      final String mappedSkinType;
      switch (_skinType) {
        case "Seca":
          mappedSkinType = "seco";
          break;
        case "Grasa":
          mappedSkinType = "graso";
          break;
        case "Mixta":
          mappedSkinType = "mixto";
          break;
        case "Sensible":
          mappedSkinType = "sensible";
          break;
        case "Normal":
        default:
          mappedSkinType = "normal";
          break;
      }

      await _supabase.from('profiles').upsert({
        'id': userId,
        'skin_type': mappedSkinType,
        'glow_frequency': _glowFreq,
        'has_acne': _acneFreq,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      // Navegación fluida directa al panel principal
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PatientDashboard()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar tu perfil: $e"), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = _progress >= 1.0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.accentDark,
              Colors.black,
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- BARRA DE PROGRESO DE ALTA FIDELIDAD ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Paso $_currentStep de 3",
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${(_progress * 100).round()}% completado",
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: 6,
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _progress.clamp(0.01, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.white, AppColors.success],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- CUERPO PRINCIPAL DESLIZABLE ---
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Queremos conocerte",
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 32, 
                          fontWeight: FontWeight.bold, 
                          height: 1.2
                        )
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Responde estas sencillas preguntas clínicas para configurar tu rutina dermatológica personalizada en HealSkin.",
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.4),
                      ),
                      const SizedBox(height: 35),

                      // PREGUNTA 1
                      _buildQuestion(
                        "¿Cuál es tu tipo de piel?", 
                        [
                          {"label": "💧 Seca", "value": "Seca"},
                          {"label": "🔥 Grasa", "value": "Grasa"},
                          {"label": "⚖️ Mixta", "value": "Mixta"},
                          {"label": "🛡️ Sensible", "value": "Sensible"},
                          {"label": "🌿 Normal", "value": "Normal"},
                        ], 
                        _skinType, 
                        (val) => setState(() => _skinType = val)
                      ),

                      const SizedBox(height: 35),

                      // PREGUNTA 2
                      _buildQuestion(
                        "¿Con qué frecuencia notas brillo en el rostro?", 
                        [
                          {"label": "❌ Nunca", "value": "Nunca"},
                          {"label": "⏳ Rara vez", "value": "Rara vez"},
                          {"label": "✨ Siempre", "value": "Siempre"},
                          {"label": "🤷 No lo sé", "value": "No lo sé"},
                        ], 
                        _glowFreq, 
                        (val) => setState(() => _glowFreq = val)
                      ),

                      const SizedBox(height: 35),

                      // PREGUNTA 3
                      _buildQuestion(
                        "¿Constantemente tienes acné o espinillas?", 
                        [
                          {"label": "🌸 Nunca", "value": "Nunca"},
                          {"label": "⚠️ A veces", "value": "A veces"},
                          {"label": "🔥 Seguido", "value": "Seguido"},
                        ], 
                        _acneFreq, 
                        (val) => setState(() => _acneFreq = val)
                      ),

                      const SizedBox(height: 45),

                      // --- BOTÓN DE FINALIZACIÓN ANCHO COMPLETO ---
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: isCompleted && !_isLoading
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  )
                                ]
                              : null,
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            disabledBackgroundColor: Colors.white.withOpacity(0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24, 
                                  width: 24, 
                                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3)
                                )
                              : Text(
                                  "Finalizar", 
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 18, 
                                    color: isCompleted ? AppColors.accentDark : Colors.grey.shade400
                                  )
                                ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(
    String title, 
    List<Map<String, String>> options, 
    String? selectedValue, 
    Function(String) onSelect
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: options.map((option) {
            final isSelected = selectedValue == option['value'];

            return GestureDetector(
              onTap: () => onSelect(option['value']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  option['label']!,
                  style: TextStyle(
                    color: isSelected ? AppColors.accentDark : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}