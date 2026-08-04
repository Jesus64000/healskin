import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/theme/app_colors.dart';

class QuizzesAdminScreen extends StatefulWidget {
  const QuizzesAdminScreen({super.key});

  @override
  State<QuizzesAdminScreen> createState() => _QuizzesAdminScreenState();
}

class _QuizzesAdminScreenState extends State<QuizzesAdminScreen> {
  List<Map<String, dynamic>> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? quizzesJson = prefs.getString('healskin_quizzes_db');

      setState(() {
        if (quizzesJson != null) {
          _quizzes = List<Map<String, dynamic>>.from(
            (json.decode(quizzesJson) as List).map((item) => Map<String, dynamic>.from(item))
          );
        } else {
          // Valores iniciales por defecto (Seed Data de alta fidelidad)
          _quizzes = [
            {
              "id": "q1",
              "title": "Evaluación Inicial de Acné",
              "desc": "Preguntas de cribado para identificar el grado de acné comedogénico o inflamatorio.",
              "skin_type": "Grasa",
              "is_new": true,
              "questions_count": 6,
              "questions": [
                {
                  "text": "¿Con qué frecuencia experimentas brotes de acné?",
                  "options": ["Diariamente", "Ocasionalmente", "Solo en ciclo menstrual", "Raras veces"]
                },
                {
                  "text": "¿Qué tipo de lesiones predomina en tu piel?",
                  "options": ["Comedones (puntos negros/blancos)", "Pápulas y pústulas (granos rojos con pus)", "Nódulos o quistes dolorosos", "Ninguno"]
                },
                {
                  "text": "¿En qué zonas de tu rostro se concentran los brotes?",
                  "options": ["Zona T (frente, nariz, barbilla)", "Mejillas y mandíbula", "Todo el rostro", "No tengo brotes"]
                },
                {
                  "text": "¿Tienes marcas o cicatrices residuales de acné anterior?",
                  "options": ["Sí, manchas oscuras/rojas", "Sí, cicatrices profundas", "No, sanan sin dejar marcas", "No he tenido acné"]
                },
                {
                  "text": "¿Qué productos usas en tu rutina actual?",
                  "options": ["Limpiador especial y exfoliantes", "Hidratante ligero", "Tratamiento médico recetado", "Ninguno"]
                },
                {
                  "text": "¿Sueles pellizcarte o tocarte las lesiones?",
                  "options": ["Sí, con frecuencia", "A veces", "Nunca"]
                }
              ]
            },
            {
              "id": "q2",
              "title": "Test de Permeabilidad y Enrojecimiento",
              "desc": "Analiza si presentas una barrera cutánea debilitada o síntomas clásicos de rosácea.",
              "skin_type": "Sensible",
              "is_new": false,
              "questions_count": 5,
              "questions": [
                {
                  "text": "¿Tu piel se enrojece con facilidad ante estímulos externos?",
                  "options": ["Sí, casi siempre (sol, viento, comida picante)", "Solo con productos específicos", "Ocasionalmente", "Nunca"]
                },
                {
                  "text": "¿Sientes tirantez, ardor o picazón en el rostro?",
                  "options": ["Frecuentemente durante el día", "Solo después de lavarme la cara", "Raras veces", "Nunca"]
                },
                {
                  "text": "¿Cómo reacciona tu piel al probar un producto nuevo?",
                  "options": ["Suele arder o irritarse de inmediato", "A veces presenta rojeces", "Se adapta sin inconvenientes", "No suelo probar productos nuevos"]
                },
                {
                  "text": "¿Observas capilares sanguíneos visibles (arañitas vasculares)?",
                  "options": ["Sí, en mejillas y nariz", "Muy pocos", "No, ninguno"]
                },
                {
                  "text": "¿Qué tipo de clima tolera peor tu piel?",
                  "options": ["Clima muy frío o ventoso", "Clima extremadamente caluroso", "Ambos", "Tolera bien cualquier clima"]
                }
              ]
            },
            {
              "id": "q3",
              "title": "Monitoreo de Xerosis y Descamación",
              "desc": "Diseñado para pacientes que sufren de tirantez crónica y grietas por falta de lípidos.",
              "skin_type": "Seca",
              "is_new": true,
              "questions_count": 4,
              "questions": [
                {
                  "text": "¿Cómo describirías la textura al tacto de tu piel?",
                  "options": ["Áspera y descamada", "Seca pero suave", "Normal", "Grasa o aceitosa"]
                },
                {
                  "text": "¿Con qué frecuencia aplicas crema hidratante?",
                  "options": ["Varias veces al día para aliviar la tirantez", "Una vez al día", "De vez en cuando", "Nunca"]
                },
                {
                  "text": "¿Se te descama la piel en alguna zona en particular?",
                  "options": ["Sí, en la frente, mejillas y alrededor de la boca", "Solo en la nariz", "Ocasionalmente en invierno", "No se descama"]
                },
                {
                  "text": "¿Qué textura de crema prefieres utilizar?",
                  "options": ["Ungüentos o cremas muy ricas y espesas", "Emulsiones o lociones ligeras", "Geles hidratantes", "No utilizo cremas"]
                }
              ]
            }
          ];
          _saveQuizzesToPrefs();
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading quizzes: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveQuizzesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('healskin_quizzes_db', json.encode(_quizzes));
    } catch (e) {
      debugPrint("Error saving quizzes: $e");
    }
  }

  void _showAddEditModal({Map<String, dynamic>? quiz, int? index}) {
    final TextEditingController titleController = TextEditingController(text: quiz?['title'] ?? '');
    final TextEditingController descController = TextEditingController(text: quiz?['desc'] ?? '');
    
    // Copiar la lista de preguntas localmente para editar temporalmente
    List<Map<String, dynamic>> tempQuestions = [];
    if (quiz != null && quiz['questions'] != null) {
      tempQuestions = List<Map<String, dynamic>>.from(
        (quiz['questions'] as List).map((q) => Map<String, dynamic>.from(q))
      );
    }

    String skinTypeTarget = quiz?['skin_type'] ?? 'Todas';
    bool isNewVal = quiz?['is_new'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 24, right: 24, top: 24
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz == null ? "Crear Nuevo Cuestionario" : "Editar Cuestionario",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 15),

                    // Título
                    const Text("Título del Cuestionario *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: "Ej. Diagnóstico de Rosácea y Sensibilidad...",
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Descripción
                    const Text("Descripción / Introducción *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "Ej. Cuestionario enfocado en evaluar la reacción epidérmica ante irritantes...",
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Fila de Tipo de Piel y Número de Preguntas
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Tipo de Piel Objetivo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: skinTypeTarget,
                                    isExpanded: true,
                                    items: ['Todas', 'Seca', 'Grasa', 'Mixta', 'Sensible', 'Normal'].map((String type) {
                                      return DropdownMenuItem<String>(
                                        value: type,
                                        child: Text(type),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() {
                                          skinTypeTarget = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Nº de Preguntas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 5),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  "${tempQuestions.length}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Botón para editar preguntas
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showQuestionsEditor(context, tempQuestions, (updatedQuestions) {
                            setModalState(() {
                              tempQuestions = updatedQuestions;
                            });
                          });
                        },
                        icon: const Icon(Icons.quiz_outlined, color: AppColors.primary),
                        label: Text(
                          "Administrar Preguntas (${tempQuestions.length})",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Switch "Novedad"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Marcar como Novedad (Destacado):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                        Switch.adaptive(
                          activeColor: AppColors.primary,
                          value: isNewVal,
                          onChanged: (val) {
                            setModalState(() {
                              isNewVal = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Botón Guardar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(quiz == null ? "Crear Cuestionario" : "Guardar Cambios", style: const TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          if (titleController.text.trim().isEmpty || descController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Completa los campos obligatorios"), backgroundColor: AppColors.warning),
                            );
                            return;
                          }

                          setState(() {
                            if (quiz == null) {
                              _quizzes.add({
                                "id": DateTime.now().millisecondsSinceEpoch.toString(),
                                "title": titleController.text.trim(),
                                "desc": descController.text.trim(),
                                "skin_type": skinTypeTarget,
                                "is_new": isNewVal,
                                "questions_count": tempQuestions.length,
                                "questions": tempQuestions,
                              });
                            } else if (index != null) {
                              _quizzes[index] = {
                                "id": quiz['id'],
                                "title": titleController.text.trim(),
                                "desc": descController.text.trim(),
                                "skin_type": skinTypeTarget,
                                "is_new": isNewVal,
                                "questions_count": tempQuestions.length,
                                "questions": tempQuestions,
                              };
                            }
                          });

                          _saveQuizzesToPrefs();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(quiz == null ? "🎉 Cuestionario creado con éxito" : "✏️ Cuestionario modificado con éxito"),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showQuestionsEditor(
    BuildContext context,
    List<Map<String, dynamic>> initialQuestions,
    Function(List<Map<String, dynamic>>) onSave,
  ) {
    // Copia profunda local para editar
    final List<Map<String, dynamic>> localQuestions = List<Map<String, dynamic>>.from(
      initialQuestions.map((q) => {
        "text": q["text"] ?? "",
        "options": List<String>.from(q["options"] ?? []),
      })
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setEditorState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          "Editar Preguntas y Respuestas",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: localQuestions.isEmpty
                        ? const Center(
                            child: Text(
                              "No hay preguntas en este cuestionario.\nPulsa el botón de abajo para añadir una.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            itemCount: localQuestions.length,
                            itemBuilder: (context, qIndex) {
                              final question = localQuestions[qIndex];
                              final List<String> options = List<String>.from(question["options"]);

                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Pregunta ${qIndex + 1}",
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                            onPressed: () {
                                              setEditorState(() {
                                                localQuestions.removeAt(qIndex);
                                              });
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        initialValue: question["text"],
                                        decoration: InputDecoration(
                                          labelText: "Enunciado de la pregunta",
                                          filled: true,
                                          fillColor: AppColors.surfaceLight,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                        ),
                                        onChanged: (val) {
                                          question["text"] = val;
                                        },
                                      ),
                                      const SizedBox(height: 15),
                                      const Text(
                                        "Opciones de respuesta:",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 5),
                                      ...List.generate(options.length, (oIndex) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  initialValue: options[oIndex],
                                                  decoration: InputDecoration(
                                                    hintText: "Opción ${oIndex + 1}",
                                                    filled: true,
                                                    fillColor: AppColors.surfaceLight,
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  ),
                                                  onChanged: (val) {
                                                    options[oIndex] = val;
                                                    question["options"] = options;
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 20),
                                                onPressed: () {
                                                  setEditorState(() {
                                                    options.removeAt(oIndex);
                                                    question["options"] = options;
                                                  });
                                                },
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                      TextButton.icon(
                                        onPressed: () {
                                          setEditorState(() {
                                            options.add("");
                                            question["options"] = options;
                                          });
                                        },
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text("Añadir opción", style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setEditorState(() {
                              localQuestions.add({
                                "text": "",
                                "options": ["", ""], // Empieza con dos opciones vacías por defecto
                              });
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Nueva Pregunta"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Guardar y cerrar
                            onSave(localQuestions);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Aplicar Preguntas", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _deleteQuiz(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Eliminar Cuestionario"),
        content: const Text("¿Estás seguro de que deseas eliminar permanentemente este cuestionario del panel?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              setState(() {
                _quizzes.removeAt(index);
              });
              _saveQuizzesToPrefs();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("🗑️ Cuestionario eliminado con éxito"), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text("Gestión de Cuestionarios", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditModal(),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _quizzes.isEmpty
              ? const Center(child: Text("No hay cuestionarios creados aún.", style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = _quizzes[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  quiz['title'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                                    onPressed: () => _showAddEditModal(quiz: quiz, index: index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                    onPressed: () => _deleteQuiz(index),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            quiz['desc'],
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Divider(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "Piel: ${quiz['skin_type']}",
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (quiz['is_new'] == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        "Novedad",
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                "${quiz['questions_count']} Preguntas",
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
