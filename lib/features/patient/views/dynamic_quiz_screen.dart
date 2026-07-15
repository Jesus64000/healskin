import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';

class DynamicQuizScreen extends StatefulWidget {
  final Map<String, dynamic> quiz;
  const DynamicQuizScreen({super.key, required this.quiz});

  @override
  State<DynamicQuizScreen> createState() => _DynamicQuizScreenState();
}

class _DynamicQuizScreenState extends State<DynamicQuizScreen> {
  int _currentIndex = 0;
  final Map<int, String> _answers = {};
  bool _isLoading = false;

  List<dynamic> get _questions => widget.quiz['questions'] ?? [];

  double get _progress {
    if (_questions.isEmpty) return 0.0;
    return (_answers.length) / _questions.length;
  }

  Future<void> _submitQuiz() async {
    if (_answers.length < _questions.length) {
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
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("Sesión inválida");

      final List<String> summaryAnswers = [];
      for (int i = 0; i < _questions.length; i++) {
        final qText = _questions[i]['text'] ?? '';
        final ans = _answers[i] ?? '';
        summaryAnswers.add("- **$qText**: $ans");
      }

      // Guardar el evento en el historial de evolución dérmica
      await supabase.from('skin_evolution').insert({
        'user_id': user.id,
        'title': 'Cuestionario: ${widget.quiz['title']}',
        'description': 'Respuestas registradas:\n${summaryAnswers.join('\n')}',
        'event_type': 'info',
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("🎉 ¡Cuestionario Completado!", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            "Tus respuestas han sido registradas exitosamente. El especialista podrá verlas en tu expediente clínico.",
            style: TextStyle(color: Colors.grey.shade600, height: 1.3),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context); // cerrar diálogo
                Navigator.pop(context); // volver al inicio
              },
              child: const Text("Aceptar", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar respuestas: $e"), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quiz['title'] ?? 'Cuestionario')),
        body: const Center(child: Text("Este cuestionario no tiene preguntas.")),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    final String qText = currentQuestion['text'] ?? '';
    final List<dynamic> options = currentQuestion['options'] ?? [];
    final selectedValue = _answers[_currentIndex];

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
              // --- CABECERA DE PROGRESO ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          "Pregunta ${_currentIndex + 1} de ${_questions.length}",
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${(_progress * 100).round()}% listo",
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

              // --- PREGUNTA ---
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.quiz['title'] ?? 'Evaluación Especializada',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        qText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 35),
                      ...options.map((option) {
                        final optionStr = option.toString();
                        final isSelected = selectedValue == optionStr;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _answers[_currentIndex] = optionStr;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(18),
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    optionStr,
                                    style: TextStyle(
                                      color: isSelected ? AppColors.accentDark : Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle, color: AppColors.accentDark, size: 20),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentIndex > 0)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _currentIndex--;
                                });
                              },
                              icon: const Icon(Icons.arrow_back, color: Colors.white70),
                              label: const Text("Anterior", style: TextStyle(color: Colors.white70)),
                            )
                          else
                            const SizedBox.shrink(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    if (selectedValue == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Selecciona una opción para continuar"),
                                          backgroundColor: AppColors.warning,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }
                                    if (_currentIndex < _questions.length - 1) {
                                      setState(() {
                                        _currentIndex++;
                                      });
                                    } else {
                                      _submitQuiz();
                                    }
                                  },
                            child: _isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                                  )
                                : Text(
                                    _currentIndex == _questions.length - 1 ? "Enviar" : "Siguiente",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ],
                      ),
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
}
