import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../auth/profile_provider.dart';
import 'admin_providers.dart';

class AdminCreateArticleView extends ConsumerStatefulWidget {
  final Map<String, dynamic>? article;
  const AdminCreateArticleView({super.key, this.article});

  @override
  ConsumerState<AdminCreateArticleView> createState() => _AdminCreateArticleViewState();
}

class _AdminCreateArticleViewState extends ConsumerState<AdminCreateArticleView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _categoryController = TextEditingController();

  String _selectedType = 'Recomendación';
  String _selectedSkinType = 'todos';
  
  final List<String> _articleTypes = [
    'Recomendación',
    'Novedad',
    'Producto',
    'Patología',
    'Piel',
  ];
  
  final List<Map<String, String>> _skinTypes = [
    {'label': '✨ Todos', 'value': 'todos'},
    {'label': '💧 Seca', 'value': 'seco'},
    {'label': '🔥 Grasa', 'value': 'graso'},
    {'label': '⚖️ Mixta', 'value': 'mixto'},
    {'label': '🛡️ Sensible', 'value': 'sensible'},
    {'label': '🌿 Normal', 'value': 'normal'},
  ];

  final List<String> _popularCategories = [
    'Rutina Diaria',
    'Prevención',
    'Tratamientos',
    'Protección Solar',
    'Alimentación',
  ];

  File? _coverImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.article != null) {
      _titleController.text = widget.article!['title'] ?? '';
      _contentController.text = widget.article!['content'] ?? '';
      
      final categoryCombined = widget.article!['category'] ?? '';
      final parsed = parseArticleCategory(categoryCombined);
      _selectedType = parsed['type']!;
      _selectedSkinType = parsed['skinType']!;
      _categoryController.text = parsed['name']!;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() => _coverImage = File(pickedFile.path));
    }
  }

  Future<void> _publish() async {
    final bool isEdit = widget.article != null;
    if (!_formKey.currentState!.validate()) return;
    if (_coverImage == null && !isEdit) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Debes seleccionar una imagen de portada"),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String typeTag = _selectedType;
      final String skinTag = _selectedSkinType;
      final String cleanCategory = _categoryController.text.trim();
      final String combinedCategory = "$typeTag | $skinTag | $cleanCategory";

      if (isEdit) {
        await ref.read(adminControllerProvider).updateArticle(
          articleId: widget.article!['id'],
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: combinedCategory,
          coverImage: _coverImage,
          existingImageUrl: widget.article!['image_url'],
        );
      } else {
        await ref.read(adminControllerProvider).publishArticle(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: combinedCategory,
          coverImage: _coverImage!,
        );
      }

      ref.invalidate(articlesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            isEdit ? "¡Artículo actualizado con éxito!" : "¡Artículo publicado con éxito en HealSkin!", 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          ),
          backgroundColor: AppColors.success,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: $e"),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.article != null;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          isEdit ? "Editar Artículo" : "Redactar Artículo", 
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SELECTOR DE PORTADA ESTÉTICO ---
                    const Text(
                      "Imagen de Portada",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: (_coverImage == null && (widget.article?['image_url'] == null || widget.article!['image_url'].toString().isEmpty))
                                ? AppColors.primary.withOpacity(0.2) 
                                : Colors.transparent, 
                            style: (_coverImage == null && (widget.article?['image_url'] == null || widget.article!['image_url'].toString().isEmpty)) ? BorderStyle.solid : BorderStyle.none
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04), 
                              blurRadius: 15, 
                              offset: const Offset(0, 5)
                            )
                          ],
                          image: _coverImage != null
                              ? DecorationImage(image: FileImage(_coverImage!), fit: BoxFit.cover)
                              : (widget.article?['image_url'] != null && widget.article!['image_url'].toString().isNotEmpty)
                                  ? DecorationImage(image: NetworkImage(widget.article!['image_url']), fit: BoxFit.cover)
                                  : null,
                        ),
                        child: (_coverImage == null && (widget.article?['image_url'] == null || widget.article!['image_url'].toString().isEmpty))
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.08),
                                      shape: BoxShape.circle
                                    ),
                                    child: const Icon(Icons.add_photo_alternate_rounded, size: 36, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text("Toca para subir una hermosa portada", style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                  ),
                                ),
                                padding: const EdgeInsets.all(15),
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12)
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit, size: 14, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text("Cambiar", style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // --- TIPO DE ARTÍCULO ---
                    const Text(
                      "Tipo de Artículo",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _articleTypes.map((type) {
                        final isSelected = _selectedType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedType = type);
                            }
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary.withOpacity(0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.grey.shade300,
                            width: isSelected ? 1.5 : 1
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 25),

                    // --- TARGET SKIN TYPE (TIPO DE PIEL DESTINADO) ---
                    const Text(
                      "Target: Tipo de Piel Recomendado",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _skinTypes.map((skin) {
                        final isSelected = _selectedSkinType == skin['value'];
                        return ChoiceChip(
                          label: Text(skin['label']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedSkinType = skin['value']!);
                            }
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.secondary.withOpacity(0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(
                            color: isSelected ? AppColors.secondary : Colors.grey.shade300,
                            width: isSelected ? 1.5 : 1
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.secondary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 25),

                    // --- TÍTULO ---
                    const Text(
                      "Título del Artículo",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: "Ej. Rutina matutina contra la deshidratación",
                        prefixIcon: const Icon(Icons.title_rounded, color: AppColors.primary),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      ),
                      validator: (v) => v!.isEmpty ? "Por favor, ingresa el título" : null,
                    ),
                    const SizedBox(height: 25),

                    // --- CATEGORÍAS POPULARES ---
                    const Text(
                      "Categoría o Temática",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Selecciona una popular o redacta una personalizada abajo:",
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _popularCategories.map((cat) {
                        final isSelected = _categoryController.text == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _categoryController.text = cat);
                            }
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary.withOpacity(0.12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.grey.shade300,
                            width: isSelected ? 1.5 : 1
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _categoryController,
                      style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: "Escribe tu propia categoría aquí",
                        prefixIcon: const Icon(Icons.style_rounded, color: AppColors.primary),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      ),
                      validator: (v) => v!.isEmpty ? "Por favor, define una categoría" : null,
                    ),
                    const SizedBox(height: 25),

                    // --- CONTENIDO ---
                    const Text(
                      "Contenido del Artículo",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _contentController,
                      maxLines: 8,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
                      decoration: InputDecoration(
                        hintText: "Escribe aquí todos los consejos detallados, pasos y recomendaciones...",
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 120),
                          child: Icon(Icons.description_rounded, color: AppColors.primary),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      ),
                      validator: (v) => v!.isEmpty ? "El contenido del artículo no puede estar vacío" : null,
                    ),
                    const SizedBox(height: 35),

                    // --- BOTÓN PUBLICAR PREMIUM ---
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6)
                          )
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _publish,
                        icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white),
                        label: Text(
                          isEdit ? "Actualizar Artículo" : "Publicar Artículo", 
                          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
}