import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import 'admin_providers.dart';

// ============================================================================
// 📱 1. PANTALLA DE LISTADO DE USUARIOS (BÚSQUEDA Y SELECCIÓN)
// ============================================================================
class AdminUserListScreen extends ConsumerStatefulWidget {
  final String role; // 'patient' o 'doctor'

  const AdminUserListScreen({
    super.key,
    required this.role,
  });

  @override
  ConsumerState<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends ConsumerState<AdminUserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUserListProvider(widget.role));
    final String title = widget.role == 'doctor' ? "Médicos Registrados" : "Pacientes Registrados";

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // 🔍 Barra de Búsqueda Premium
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
                border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: widget.role == 'doctor' ? "Buscar médico por nombre o email..." : "Buscar paciente por nombre o email...",
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = "";
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),
          ),

          // 👥 Listado de Usuarios
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(adminUserListProvider(widget.role));
              },
              child: usersAsync.when(
                data: (users) {
                  // Filtramos localmente por la query de búsqueda
                  final filteredUsers = users.where((u) {
                    final String name = (u['full_name'] ?? '').toString().toLowerCase();
                    final String email = (u['email'] ?? '').toString().toLowerCase();
                    final String query = _searchQuery.toLowerCase();
                    return name.contains(query) || email.contains(query);
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.role == 'doctor' ? Icons.medical_services_outlined : Icons.people_outline_rounded,
                                  size: 64,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _searchQuery.isNotEmpty ? "Sin resultados" : "No hay registros",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  _searchQuery.isNotEmpty 
                                      ? "No encontramos a nadie que coincida con tu búsqueda. Intenta con otro término."
                                      : "Aún no se registran usuarios con este rol en el sistema.",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final name = user['full_name'] ?? 'Usuario';
                      final email = user['email'] ?? 'Sin correo registrado';
                      final avatarInitials = name.trim().split(' ').take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.01),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: widget.role == 'doctor' 
                                ? AppColors.secondary.withValues(alpha: 0.1) 
                                : AppColors.primary.withValues(alpha: 0.1),
                            backgroundImage: (user['avatar_url'] != null && (user['avatar_url'] as String).isNotEmpty)
                                ? NetworkImage(user['avatar_url'] as String)
                                : null,
                            child: (user['avatar_url'] == null || (user['avatar_url'] as String).isEmpty)
                                ? Text(
                                    avatarInitials.isEmpty ? 'U' : avatarInitials,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: widget.role == 'doctor' ? AppColors.secondary : AppColors.primary,
                                      fontSize: 16,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(email, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              if (widget.role == 'patient')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "PIEL: ${(user['skin_type'] ?? 'No definida').toUpperCase()}",
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    user['specialty'] ?? "Especialidad no configurada",
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                  ),
                                ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminUserDetailScreen(user: user),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Text("Error al cargar la lista: $e", style: const TextStyle(color: AppColors.danger)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 📱 2. PANTALLA DE DETALLE DEL USUARIO (FICHA DE INFORMACIÓN COMPLETA)
// ============================================================================
class AdminUserDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> user;

  const AdminUserDetailScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = user['full_name'] ?? 'Usuario';
    final email = user['email'] ?? 'Sin correo registrado';
    final role = user['role'] ?? 'patient';
    final date = user['created_at'] != null
        ? DateFormat('dd MMMM yyyy, HH:mm', 'es').format(DateTime.parse(user['created_at']).toLocal())
        : 'Fecha desconocida';

    final avatarInitials = name.trim().split(' ').take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Ficha de Usuario",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 👤 Encabezado Principal Visual (Tarjeta Premium)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: CircleAvatar(
                      radius: 41,
                      backgroundColor: Colors.white,
                      backgroundImage: (user['avatar_url'] != null && (user['avatar_url'] as String).isNotEmpty)
                          ? NetworkImage(user['avatar_url'] as String)
                          : null,
                      child: (user['avatar_url'] == null || (user['avatar_url'] as String).isEmpty)
                          ? Text(
                              avatarInitials.isEmpty ? 'U' : avatarInitials,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: role == 'doctor' ? AppColors.secondary : AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      role == 'doctor' ? "MÉDICO DERMATÓLOGO" : "PACIENTE",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 📝 Sección de Información Detallada
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ficha General
                  _buildSectionHeader("Información de Cuenta"),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(),
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.fingerprint_rounded, "Identificación ID (User)", user['id'] ?? 'N/A'),
                        _buildDetailRow(Icons.badge_outlined, "Cédula / Documento", user['identification_id'] ?? 'No registrada'),
                        _buildDetailRow(Icons.calendar_today_outlined, "Fecha de Registro", date),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Campos específicos por rol
                  if (role == 'patient') ...[
                    _buildSectionHeader("Ficha de Salud y Piel"),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: _cardDecoration(),
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.spa_outlined, "Tipo de Piel", (user['skin_type']?.toString().toUpperCase() ?? 'NO DETERMINADO')),
                          _buildDetailRow(Icons.cake_outlined, "Edad", user['age']?.toString() ?? 'No registrada'),
                          _buildDetailRow(Icons.face_outlined, "Género", user['gender'] ?? 'No especificado'),
                          _buildDetailRow(Icons.warning_amber_rounded, "Alergias Conocidas", user['allergies'] ?? 'Ninguna'),
                          _buildDetailRow(Icons.history_edu_outlined, "Antecedentes Médicos", user['medical_history'] ?? 'Ninguno'),
                          _buildDetailRow(Icons.history_outlined, "Tratamientos Previos", user['treatments_past'] ?? 'Ninguno'),
                          _buildDetailRow(Icons.medical_services_outlined, "Tratamientos Actuales", user['treatments_current'] ?? 'Ninguno'),
                        ],
                      ),
                    ),
                  ] else if (role == 'doctor') ...[
                    _buildSectionHeader("Credenciales Médicas"),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: _cardDecoration(),
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.assignment_turned_in_outlined, "Estado de Cuenta", (user['is_approved'] == true) ? "Aprobada / Activa" : "Pendiente de Aprobación", color: (user['is_approved'] == true) ? AppColors.success : Colors.orange),
                          _buildDetailRow(Icons.verified_user_outlined, "Número de Licencia", user['license_number'] ?? 'No registrada'),
                          _buildDetailRow(Icons.school_outlined, "Especialidad", user['specialty'] ?? 'No especificada'),
                          _buildDetailRow(Icons.location_on_outlined, "Ubicación del Consultorio", user['office_address'] ?? 'No configurada'),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmAndCallDelete(context, ref),
                      icon: const Icon(Icons.delete_forever, color: Colors.white),
                      label: const Text("Eliminar Cuenta", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndCallDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        title: const Text("Confirmar Eliminación", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: Text("¿Estás seguro de que deseas eliminar permanentemente a ${user['full_name'] ?? 'este usuario'}? Esta acción no se puede deshacer y eliminará su perfil de la base de datos."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar", style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final userId = user['id'] ?? '';
        final userRole = user['role'] ?? 'patient';
        await ref.read(adminControllerProvider).deleteUser(userId, userRole);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Usuario eliminado correctamente"),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context); // Volver al listado
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
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.01),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color ?? AppColors.primary, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
