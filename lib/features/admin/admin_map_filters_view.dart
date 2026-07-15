import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../auth/profile_provider.dart';
import 'admin_providers.dart';

class AdminMapFiltersView extends ConsumerStatefulWidget {
  const AdminMapFiltersView({super.key});

  @override
  ConsumerState<AdminMapFiltersView> createState() => _AdminMapFiltersViewState();
}

class _AdminMapFiltersViewState extends ConsumerState<AdminMapFiltersView> {
  bool _isSaving = false;

  void _showFilterDialog({Map<String, dynamic>? filter}) {
    final isEdit = filter != null;
    final nameController = TextEditingController(text: filter?['name'] ?? '');
    final keywordsController = TextEditingController(text: filter?['keywords'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEdit ? "Editar Filtro" : "Agregar Filtro",
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Nombre de Categoría",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: "Ej. Pediatría",
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Palabras Clave (separadas por comas)",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: keywordsController,
                    decoration: InputDecoration(
                      hintText: "Ej. pedi, niño, infan",
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Cualquier clínica o médico que contenga estas palabras en su especialidad o nombre aparecerá bajo esta pestaña en el mapa.",
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text("Cancelar", style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final keywords = keywordsController.text.trim();
                          if (name.isEmpty || keywords.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Por favor rellene todos los campos"),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => _isSaving = true);
                          setState(() => _isSaving = true);

                          try {
                            final controller = ref.read(adminControllerProvider);
                            if (isEdit) {
                              await controller.updateMapFilter(
                                filterId: filter['id'],
                                name: name,
                                keywords: keywords,
                              );
                            } else {
                              await controller.addMapFilter(name, keywords);
                            }
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEdit ? "Filtro actualizado" : "Filtro creado con éxito"),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.danger),
                              );
                            }
                          } finally {
                            setDialogState(() => _isSaving = false);
                            if (mounted) setState(() => _isSaving = false);
                          }
                        },
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(isEdit ? "Guardar" : "Crear"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteFilter(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Filtro"),
        content: const Text("¿Está seguro de que desea eliminar este filtro del mapa?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      try {
        await ref.read(adminControllerProvider).deleteMapFilter(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Filtro eliminado con éxito"), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.danger),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtersAsync = ref.watch(mapFiltersProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Filtros de Búsqueda Mapa",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _showFilterDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Agregar Filtro", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: filtersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (filters) {
          // Detectar si estamos usando los datos de fallback (lo que indica que la tabla no existe en la BD)
          final isFallback = filters.any((f) => f['id'].toString().startsWith('default-'));

          return Column(
            children: [
              if (isFallback)
                Container(
                  margin: const EdgeInsets.all(15),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Modo de compatibilidad: No se encontró la tabla 'map_filters' en Supabase. "
                          "Por favor ejecute el script SQL provisto para poder crear, editar o eliminar filtros.",
                          style: TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: filters.isEmpty
                    ? const Center(
                        child: Text(
                          "No hay filtros personalizados agregados.",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 80),
                        itemCount: filters.length,
                        itemBuilder: (context, index) {
                          final f = filters[index];
                          final id = f['id'].toString();
                          final isDefault = id.startsWith('default-');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black.withOpacity(0.04)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.01),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                f['name'] ?? 'Sin nombre',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  "Palabras clave: ${f['keywords'] ?? ''}",
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ),
                              trailing: isDefault
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        "Por defecto",
                                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                                          onPressed: () => _showFilterDialog(filter: f),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                                          onPressed: () => _deleteFilter(id),
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
