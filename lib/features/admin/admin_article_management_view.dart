import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../auth/profile_provider.dart';
import 'admin_providers.dart';
import 'admin_create_article_view.dart';

class AdminArticleManagementView extends ConsumerWidget {
  const AdminArticleManagementView({super.key});

  // Método auxiliar para parsear y limpiar la categoría combinada (ej. "seco - Rutina Diaria")
  Map<String, String> _parseCategory(String categoryCombined) {
    if (!categoryCombined.contains(' - ')) {
      return {'skinType': 'todos', 'name': categoryCombined};
    }
    final parts = categoryCombined.split(' - ');
    return {
      'skinType': parts[0].trim(),
      'name': parts.sublist(1).join(' - ').trim(),
    };
  }

  String _getSkinTypeLabel(String skinValue) {
    switch (skinValue.toLowerCase()) {
      case 'todos': return '✨ Todos';
      case 'seco': return '💧 Seca';
      case 'graso': return '🔥 Grasa';
      case 'mixto': return '⚖️ Mixta';
      case 'sensible': return '🛡️ Sensible';
      case 'normal': return '🌿 Normal';
      default: return '✨ $skinValue';
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            SizedBox(width: 10),
            Text("¿Eliminar Artículo?", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "¿Estás seguro de que deseas eliminar \"${article['title']}\"? Esta acción no se puede deshacer.",
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Cierra dialog
              try {
                await ref.read(adminControllerProvider).deleteArticle(article['id']);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Artículo eliminado exitosamente"),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error al eliminar: $e"),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Eliminar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(articlesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          "Gestión de Artículos",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(articlesProvider);
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: articlesAsync.when(
          data: (articles) {
            if (articles.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined, size: 80, color: AppColors.primary.withOpacity(0.3)),
                      const SizedBox(height: 15),
                      const Text(
                        "No hay artículos creados",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Toca el botón flotante '+' para publicar tu primer tip de skincare.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: articles.length,
              itemBuilder: (context, index) {
                final article = articles[index];
                final categoryParsed = parseArticleCategory(article['category'] ?? '');
                final skinLabel = _getSkinTypeLabel(categoryParsed['skinType']!);

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withOpacity(0.04)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      // Portada Miniatura
                      Container(
                        width: 100,
                        height: 100,
                        color: AppColors.surfaceLight,
                        child: article['image_url'] != null && article['image_url'].toString().isNotEmpty
                            ? Image.network(
                                article['image_url'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                              )
                            : const Center(child: Icon(Icons.image_outlined, color: Colors.grey)),
                      ),
                      const SizedBox(width: 15),

                      // Detalles del Artículo
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge de Categoría
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  // Tipo (ej: Recomendación, Novedad, etc.)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      categoryParsed['type']!,
                                      style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  // Nombre Subcategoría
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      categoryParsed['name']!,
                                      style: const TextStyle(color: AppColors.secondary, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  // Tipo de Piel
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orangeAccent.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      skinLabel,
                                      style: const TextStyle(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Título
                              Text(
                                article['title'] ?? 'Sin título',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Botones de Acción
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminCreateArticleView(article: article),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                            onPressed: () => _showDeleteDialog(context, ref, article),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(child: Text("Error al cargar artículos: $err")),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminCreateArticleView()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
