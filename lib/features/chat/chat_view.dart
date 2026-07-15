import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import 'chat_provider.dart'; // 🚀 Asegúrate de apuntar a tu nuevo archivo
import 'chat_notification_listener.dart';

class ChatView extends ConsumerStatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatView({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final _messageController = TextEditingController();
  bool _isSendingFile = false;
  String? _otherUserAvatarUrl;
  String? _myAvatarUrl;

  @override
  void initState() {
    super.initState();
    // Registrar el chat activo para silenciar notificaciones locales
    ChatNotificationListener().activeChatUserId = widget.otherUserId;
    _loadAvatars();
  }

  Future<void> _loadAvatars() async {
    try {
      final supabase = Supabase.instance.client;
      final myId = supabase.auth.currentUser?.id;

      // Load other user's avatar
      final otherProfile = await supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', widget.otherUserId)
          .maybeSingle();

      if (otherProfile != null && mounted) {
        setState(() {
          _otherUserAvatarUrl = otherProfile['avatar_url'];
        });
      }

      // Load my avatar
      if (myId != null) {
        final myProfile = await supabase
            .from('profiles')
            .select('avatar_url')
            .eq('id', myId)
            .maybeSingle();
        if (myProfile != null && mounted) {
          setState(() {
            _myAvatarUrl = myProfile['avatar_url'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading avatars in chat: $e");
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    // Limpiar el estado de chat activo al salir
    if (ChatNotificationListener().activeChatUserId == widget.otherUserId) {
      ChatNotificationListener().activeChatUserId = null;
    }
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    _messageController.clear(); // Limpiamos rápido para dar sensación de inmediatez

    try {
      await ref.read(chatControllerProvider).sendMessage(widget.otherUserId, text);
      ref.invalidate(chatStreamProvider(widget.otherUserId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    setState(() {
      _isSendingFile = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final myId = supabase.auth.currentUser!.id;
      final fileExtension = picked.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$fileExtension';
      final storagePath = 'chat_attachments/$myId/$fileName';

      final file = File(picked.path);
      await supabase.storage.from('scan_images').upload(storagePath, file);
      final publicImageUrl = supabase.storage.from('scan_images').getPublicUrl(storagePath);

      await ref.read(chatControllerProvider).sendMessage(
        widget.otherUserId,
        "📷 Imagen adjunta",
        imageUrl: publicImageUrl,
      );
      ref.invalidate(chatStreamProvider(widget.otherUserId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error al enviar imagen: $e"),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingFile = false;
        });
      }
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = Supabase.instance.client.auth.currentUser!.id;
    final chatStream = ref.watch(chatStreamProvider(widget.otherUserId));
    final partnerProfileAsync = ref.watch(partnerProfileProvider(widget.otherUserId));

    final partnerProfile = partnerProfileAsync.value;
    final String partnerName = partnerProfile?['full_name'] ?? widget.otherUserName;
    final String? partnerAvatarUrl = partnerProfile?['avatar_url'] ?? _otherUserAvatarUrl;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              backgroundImage: (partnerAvatarUrl != null && partnerAvatarUrl.isNotEmpty)
                  ? NetworkImage(partnerAvatarUrl)
                  : null,
              child: (partnerAvatarUrl == null || partnerAvatarUrl.isEmpty)
                  ? const Icon(Icons.person, color: AppColors.primary, size: 20)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(partnerName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatStream.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text("Error: $err")),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text("Envía un mensaje para iniciar la consulta.", style: TextStyle(color: AppColors.textSecondary)));
                }

                return ListView.builder(
                  reverse: true, // 🚀 Muestra los mensajes de abajo hacia arriba
                  padding: const EdgeInsets.all(15),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == myId;
                    final imageUrl = msg['image_url'] as String?;
                    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: hasImage
                            ? const EdgeInsets.all(4)
                            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(15),
                            topRight: const Radius.circular(15),
                            bottomLeft: Radius.circular(isMe ? 15 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 15),
                          ),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
                        ),
                        child: hasImage
                            ? GestureDetector(
                                onTap: () => _showFullScreenImage(context, imageUrl),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Image.network(
                                        imageUrl,
                                        width: 220,
                                        height: 180,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            width: 220,
                                            height: 180,
                                            color: Colors.black12,
                                            child: const Center(
                                              child: CircularProgressIndicator(color: AppColors.primary),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 220,
                                            height: 180,
                                            color: Colors.black12,
                                            child: const Center(
                                              child: Icon(Icons.broken_image, color: AppColors.textSecondary),
                                            ),
                                          );
                                        },
                                      ),
                                      if (msg['message'] != null &&
                                          msg['message'].toString().trim().isNotEmpty &&
                                          msg['message'] != "📷 Imagen adjunta")
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          child: Text(
                                            msg['message'],
                                            style: TextStyle(
                                              color: isMe ? Colors.white : AppColors.textPrimary,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                            : Text(
                                msg['message'] ?? '',
                                style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 15),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          if (_isSendingFile)
            const LinearProgressIndicator(color: AppColors.primary, backgroundColor: Colors.white),

          // LA CAJA DE TEXTO INFERIOR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 26),
                    onPressed: _sendImage,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Escribe tu consulta...",
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _send,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}