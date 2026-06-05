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
              "questions_count": 6
            },
            {
              "id": "q2",
              "title": "Test de Permeabilidad y Enrojecimiento",
              "desc": "Analiza si presentas una barrera cutánea debilitada o síntomas clásicos de rosácea.",
              "skin_type": "Sensible",
              "is_new": false,
              "questions_count": 5
            },
            {
              "id": "q3",
              "title": "Monitoreo de Xerosis y Descamación",
              "desc": "Diseñado para pacientes que sufren de tirantez crónica y grietas por falta de lípidos.",
              "skin_type": "Seca",
              "is_new": true,
              "questions_count": 4
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
    final TextEditingController countController = TextEditingController(text: (quiz?['questions_count'] ?? 4).toString());
    
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
            return Padding(
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
                              TextField(
                                controller: countController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surfaceLight,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

                          final int qCount = int.tryParse(countController.text) ?? 4;

                          setState(() {
                            if (quiz == null) {
                              _quizzes.add({
                                "id": DateTime.now().millisecondsSinceEpoch.toString(),
                                "title": titleController.text.trim(),
                                "desc": descController.text.trim(),
                                "skin_type": skinTypeTarget,
                                "is_new": isNewVal,
                                "questions_count": qCount,
                              });
                            } else if (index != null) {
                              _quizzes[index] = {
                                "id": quiz['id'],
                                "title": titleController.text.trim(),
                                "desc": descController.text.trim(),
                                "skin_type": skinTypeTarget,
                                "is_new": isNewVal,
                                "questions_count": qCount,
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
