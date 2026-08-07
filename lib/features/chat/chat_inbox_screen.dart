import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_provider.dart';
import '../doctor/doctor_patients_view.dart';
import '../patient/views/patient_appointments_provider.dart';
import 'chat_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- PROVIDERS DE CAPA DE DATOS ---

final chatInboxProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) async* {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    yield [];
    return;
  }
  final myId = user.id;

  final prefs = await SharedPreferences.getInstance();

  final stream = supabase
      .from('direct_messages')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);

  await for (final messages in stream) {
    final Map<String, Map<String, dynamic>> conversations = {};
    final deletedIds = prefs.getStringList('healskin_deleted_user_ids') ?? [];

    for (var m in messages) {
      final senderId = m['sender_id'];
      final receiverId = m['receiver_id'];

      // Solo interesan mensajes donde el usuario es remitente o destinatario
      if (senderId != myId && receiverId != myId) continue;

      final otherUserId = senderId == myId ? receiverId : senderId;

      // Excluir si está en la lista de usuarios eliminados
      if (deletedIds.contains(otherUserId)) continue;

      // Si ya hay un mensaje más reciente registrado para este canal, omitir
      if (conversations.containsKey(otherUserId)) continue;

      conversations[otherUserId] = {
        'other_user_id': otherUserId,
        'last_message': m['message'] ?? '📷 Imagen adjunta',
        'last_message_time': m['created_at'],
      };
    }

    // Filtrar perfiles que ya fueron borrados de la base de datos de Supabase
    final List<Map<String, dynamic>> validConversations = [];
    for (final conv in conversations.values) {
      final otherId = conv['other_user_id'] as String;
      try {
        final profile = await supabase.from('profiles').select('id, full_name, role').eq('id', otherId).maybeSingle();
        if (profile == null) continue;
        final name = (profile['full_name'] ?? '').toString();
        final role = (profile['role'] ?? '').toString();
        if (role == 'deleted' || name.contains('[Usuario Eliminado]') || name.contains('[Médico Rechazado]')) {
          continue;
        }
        validConversations.add(conv);
      } catch (_) {
        // Si no existe la fila del perfil, omitir esta conversación
      }
    }

    yield validConversations;
  }
});

class ChatInboxScreen extends ConsumerStatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  ConsumerState<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends ConsumerState<ChatInboxScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final DateTime date = DateTime.parse(dateStr).toLocal();
      final DateTime now = DateTime.now();
      final Duration diff = now.difference(date);

      if (diff.inDays == 0) {
        return DateFormat('hh:mm a').format(date);
      } else if (diff.inDays == 1) {
        return 'Ayer';
      } else if (diff.inDays < 7) {
        final dayStr = DateFormat('EEEE', 'es_ES').format(date);
        return dayStr[0].toUpperCase() + dayStr.substring(1);
      } else {
        return DateFormat('dd/MM/yyyy').format(date);
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final bool isDoctor = authState.role == UserRole.doctor;
    final inboxAsync = ref.watch(chatInboxProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Bandeja de Consultas",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase().trim();
                  });
                },
                decoration: const InputDecoration(
                  hintText: "Buscar chat por nombre...",
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Lista de chats activos
          Expanded(
            child: inboxAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text("Error al cargar chats: $err")),
              data: (conversations) {
                if (conversations.isEmpty) {
                  return _buildEmptyState(context, isDoctor);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  itemCount: conversations.length + 1,
                  itemBuilder: (context, index) {
                    if (index == conversations.length) {
                      // Sección inferior para nuevos contactos
                      return _buildNewContactsSection(context, isDoctor);
                    }

                    final conv = conversations[index];
                    final otherUserId = conv['other_user_id'] as String;
                    final lastMessage = conv['last_message'] as String;
                    final lastTime = conv['last_message_time'] as String;

                    return Consumer(
                      builder: (context, ref, child) {
                        final profileAsync = ref.watch(partnerProfileProvider(otherUserId));

                        return profileAsync.when(
                          loading: () => const SizedBox(height: 70),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (profile) {
                            if (profile == null) return const SizedBox.shrink();

                            final String fullName = profile['full_name'] ?? 'Usuario';
                            final String? avatarUrl = profile['avatar_url'];
                            final String roleLabel = profile['role'] == 'doctor' ? 'Médico' : 'Paciente';

                            // Filtro de búsqueda
                            if (_searchQuery.isNotEmpty && !fullName.toLowerCase().contains(_searchQuery)) {
                              return const SizedBox.shrink();
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
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
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: (avatarUrl == null || avatarUrl.isEmpty)
                                      ? Text(
                                          fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        profile['role'] == 'doctor' ? "Dr. $fullName" : fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(lastTime),
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (profile['role'] == 'doctor' ? AppColors.primary : AppColors.secondary).withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          roleLabel,
                                          style: TextStyle(
                                            color: profile['role'] == 'doctor' ? AppColors.primary : AppColors.secondary,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          lastMessage,
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatView(
                                        otherUserId: otherUserId,
                                        otherUserName: profile['role'] == 'doctor' ? "Dr. $fullName" : fullName,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDoctor) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 60.0, bottom: 20.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                const Text(
                  "No tienes chats activos",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  isDoctor
                      ? "Selecciona un paciente a continuación para iniciar una consulta."
                      : "Ponte en contacto con tu especialista asignado.",
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          _buildNewContactsSection(context, isDoctor),
        ],
      ),
    );
  }

  Widget _buildNewContactsSection(BuildContext context, bool isDoctor) {
    if (isDoctor) {
      // Vista para Doctor: Lista a sus pacientes
      final patientsAsync = ref.watch(patientsDirectoryProvider);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0),
            child: Text(
              "Iniciar Chat con Paciente",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
            ),
          ),
          patientsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text("Error al cargar pacientes: $err", style: const TextStyle(fontSize: 12, color: AppColors.danger)),
            ),
            data: (patients) {
              if (patients.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text("No tienes pacientes registrados aún.", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                );
              }

              final filteredList = patients.where((p) {
                final name = (p['full_name'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery);
              }).toList();

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final patient = filteredList[index];
                  final String patientName = patient['full_name'] ?? 'Paciente';
                  final String? avatarUrl = patient['avatar_url'];

                  return _buildContactTile(
                    context: context,
                    userId: patient['id'] ?? '',
                    displayName: patientName,
                    avatarUrl: avatarUrl,
                    subLabel: "Cédula: ${patient['identification_id'] ?? 'N/A'}",
                  );
                },
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      );
    } else {
      // Vista para Paciente: Lista a su doctor principal y especialistas disponibles
      final primaryDoctorAsync = ref.watch(primaryDoctorProvider);
      final availableDoctorsAsync = ref.watch(availableDoctorsProvider);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0),
            child: Text(
              "Especialistas Médicos",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
            ),
          ),
          primaryDoctorAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (doc) {
              if (doc == null) return const SizedBox.shrink();
              final String name = doc['full_name'] ?? 'Doctor';
              final String? avatarUrl = doc['avatar_url'];

              if (_searchQuery.isNotEmpty && !name.toLowerCase().contains(_searchQuery)) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Tu Médico Principal", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    _buildContactTile(
                      context: context,
                      userId: doc['id'] ?? '',
                      displayName: "Dr. $name",
                      avatarUrl: avatarUrl,
                      subLabel: doc['specialty'] ?? 'Dermatólogo de Cabecera',
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              );
            },
          ),
          availableDoctorsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text("Error al cargar médicos: $err", style: const TextStyle(fontSize: 12, color: AppColors.danger)),
            ),
            data: (doctors) {
              final specialists = doctors.where((doc) {
                final name = (doc['full_name'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery);
              }).toList();

              if (specialists.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Text("Otros Especialistas Disponibles", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    itemCount: specialists.length,
                    itemBuilder: (context, index) {
                      final doc = specialists[index];
                      final String name = doc['full_name'] ?? 'Doctor';
                      final String? avatarUrl = doc['avatar_url'];

                      return _buildContactTile(
                        context: context,
                        userId: doc['id'] ?? '',
                        displayName: "Dr. $name",
                        avatarUrl: avatarUrl,
                        subLabel: doc['specialty'] ?? 'Dermatólogo Especialista',
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      );
    }
  }

  Widget _buildContactTile({
    required BuildContext context,
    required String userId,
    required String displayName,
    required String? avatarUrl,
    required String subLabel,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
          child: (avatarUrl == null || avatarUrl.isEmpty)
              ? Text(
                  displayName.replaceFirst("Dr. ", "").substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                )
              : null,
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
        ),
        subtitle: Text(subLabel, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.primary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatView(
                otherUserId: userId,
                otherUserName: displayName,
              ),
            ),
          );
        },
      ),
    );
  }
}
