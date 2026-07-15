import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/profile_provider.dart';
import '../../auth/initial_quiz_screen.dart';
import '../patient_dashboard.dart';
import 'patient_reminders_view.dart';
import 'patient_profile_view.dart';
import 'pathologies_catalog_screen.dart';
import 'skin_profile_detail_screen.dart';
import 'skincare_products_screen.dart';
import '../../chat/chat_inbox_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dynamic_quiz_screen.dart';

class PatientHomeView extends ConsumerStatefulWidget {
  const PatientHomeView({super.key});

  @override
  ConsumerState<PatientHomeView> createState() => _PatientHomeViewState();
}

class _PatientHomeViewState extends ConsumerState<PatientHomeView> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _customQuizzes = [];

  @override
  void initState() {
    super.initState();
    _loadCustomQuizzes();
  }

  Future<void> _loadCustomQuizzes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? quizzesJson = prefs.getString('healskin_quizzes_db');
      if (quizzesJson != null) {
        setState(() {
          _customQuizzes = List<Map<String, dynamic>>.from(
            (json.decode(quizzesJson) as List).map((item) => Map<String, dynamic>.from(item))
          );
        });
      }
    } catch (e) {
      debugPrint("Error loading custom quizzes: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🚀 Contenido en desarrollo. ¡Estará disponible pronto!"),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final articlesAsync = ref.watch(articlesProvider);



    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: profileAsync.when(
        data: (profile) {
          // Datos limpios y dinámicos
          final String userName = profile?['full_name'] ?? "Usuario";
          final String skinType = profile?['skin_type'] ?? "en evaluación";
          final ageVal = profile?['age'];
          final genderVal = profile?['gender'];
          final bool missingDemographics = (ageVal == null || ageVal.toString().trim().isEmpty || genderVal == null || genderVal.toString().trim().isEmpty);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(userProfileProvider);
              ref.invalidate(articlesProvider);
              await Future.delayed(const Duration(seconds: 1));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  pinned: false,
                  backgroundColor: AppColors.backgroundLight,
                  elevation: 0,
                  titleSpacing: 20,
                  automaticallyImplyLeading: false,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Bienvenido", style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.normal)),
                            Text(
                              userName,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 24),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ChatInboxScreen()),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PatientProfileView()),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary,
                            backgroundImage: (profile?['avatar_url'] != null && (profile!['avatar_url'] as String).isNotEmpty)
                                ? NetworkImage(profile['avatar_url'] as String)
                                : null,
                            child: (profile?['avatar_url'] == null || (profile!['avatar_url'] as String).isEmpty)
                                ? Text(
                                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (missingDemographics)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 5.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.warning, Color(0xFFFF9800)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warning.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PatientProfileView()),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  child: const Icon(Icons.info_outline, color: Colors.white),
                                ),
                                const SizedBox(width: 15),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Completa tu perfil demográfico",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        "Necesitamos saber tu edad y género para realizar análisis clínicos más precisos.",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Builder(
                      builder: (context) {
                        final query = _searchController.text.trim();
                        final isSearching = query.isNotEmpty;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSearchBar(),
                            const SizedBox(height: 20),

                            if (isSearching) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      "Resultados de Búsqueda",
                                      style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                      FocusScope.of(context).unfocus();
                                    },
                                    child: const Text("Limpiar", style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              _buildSearchResults(articlesAsync, query),
                              const SizedBox(height: 40),
                            ] else ...[
                              _buildScannerButton(context),
                              const SizedBox(height: 25),

                              // --- RECOMENDACIONES (ARRIBA DE LAS CATEGORÍAS) ---
                              _buildRecomendaciones(articlesAsync, skinType),
                              const SizedBox(height: 25),

                              _buildRemindersCard(context),
                              const SizedBox(height: 15),
                              _buildChatCard(context),
                              const SizedBox(height: 15),
                              _buildMapCard(context),
                              const SizedBox(height: 25),

                              _buildCategoriasGrid(), // Patologías, Piel, Productos
                              const SizedBox(height: 30),

                              // --- NOVEDADES ---
                              _buildNovedades(articlesAsync),
                              const SizedBox(height: 30),

                              // --- PARA TU PIEL ---
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Para tu piel $skinType",
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)
                                  ),
                                  InkWell(
                                    onTap: _showComingSoon,
                                    child: const Text("Ver todos", style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              _buildDynamicDermotips(articlesAsync, skinType),
                              const SizedBox(height: 35),

                              const Text("Cuestionarios", style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 15),
                              _buildCuestionarioList(),
                              const SizedBox(height: 40),
                            ],
                          ],
                        );
                      }
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text("Error al cargar datos: $err")),
      ),
    );
  }


  Widget _buildDynamicDermotips(AsyncValue<List<Map<String, dynamic>>> articlesAsync, String skinType) {
    return SizedBox(
      height: 180,
      child: articlesAsync.when(
        data: (articles) {
          if (articles.isEmpty) {
            return const Center(child: Text("No hay consejos publicados aún.", style: TextStyle(color: AppColors.textSecondary)));
          }

          final normalizedSkin = skinType.toLowerCase().trim();
          List<Map<String, dynamic>> displayedArticles = [];

          if (normalizedSkin == 'en evaluación' || normalizedSkin == 'ninguno' || normalizedSkin.isEmpty) {
            displayedArticles = articles;
          } else {
            // Algoritmo de filtrado inteligente offline-first usando parseArticleCategory
            displayedArticles = articles.where((article) {
              final parsed = parseArticleCategory(article['category']);
              final skin = parsed['skinType']!.toLowerCase();
              
              if (skin == 'todos' || normalizedSkin.contains(skin) || skin.contains(normalizedSkin)) {
                return true;
              }

              final String title = (article['title'] ?? '').toLowerCase();
              final String content = (article['content'] ?? article['description'] ?? '').toLowerCase();
              
              List<String> keywords = [];
              if (normalizedSkin.contains('sec')) {
                keywords = ['seco', 'seca', 'hidratar', 'hidratacion', 'hidratante', 'dry'];
              } else if (normalizedSkin.contains('gras')) {
                keywords = ['graso', 'grasa', 'sebo', 'acne', 'brillo', 'oily', 'puntos negros'];
              } else if (normalizedSkin.contains('mixt')) {
                keywords = ['mixto', 'mixta', 'zona t', 'combination'];
              } else if (normalizedSkin.contains('sensib')) {
                keywords = ['sensible', 'irritacion', 'rojez', 'sensitive'];
              } else if (normalizedSkin.contains('normal')) {
                keywords = ['normal', 'balance', 'diario', 'diaria'];
              }

              for (var keyword in keywords) {
                if (title.contains(keyword) || content.contains(keyword)) {
                  return true;
                }
              }

              return false;
            }).toList();

            // Fallback: Si no hay específicos, mostramos todos
            if (displayedArticles.isEmpty) {
              displayedArticles = articles;
            }
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: displayedArticles.length,
            itemBuilder: (context, index) {
              final article = displayedArticles[index];
              return _dermotipCard(context, article);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stackTrace) => const Center(child: Text("Error cargando tips.")),
      ),
    );
  }

  Widget _buildSearchResults(AsyncValue<List<Map<String, dynamic>>> articlesAsync, String query) {
    return articlesAsync.when(
      data: (articles) {
        final normalizedQuery = query.toLowerCase();
        final matches = articles.where((article) {
          final title = (article['title'] ?? '').toString().toLowerCase();
          final content = (article['content'] ?? '').toString().toLowerCase();
          final categoryCombined = (article['category'] ?? '').toString().toLowerCase();
          
          return title.contains(normalizedQuery) ||
              content.contains(normalizedQuery) ||
              categoryCombined.contains(normalizedQuery);
        }).toList();

        if (matches.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                  const SizedBox(height: 15),
                  const Text(
                    "No se encontraron resultados",
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Intenta buscar palabras clave como 'acné', 'hidratación' o 'piel'",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final article = matches[index];
            final categoryParsed = parseArticleCategory(article['category'] ?? '');
            final skinLabel = _getSkinTypeLabel(categoryParsed['skinType']!);

            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
              ),
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.surfaceLight,
                    image: article['image_url'] != null && article['image_url'].toString().isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(article['image_url']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: article['image_url'] == null || article['image_url'].toString().isEmpty
                      ? const Center(child: Icon(Icons.image_outlined, color: Colors.grey))
                      : null,
                ),
                title: Text(
                  article['title'] ?? 'Sin título',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            categoryParsed['type']!,
                            style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            categoryParsed['name']!,
                            style: const TextStyle(color: AppColors.secondary, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            skinLabel,
                            style: const TextStyle(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DermotipDetailScreen(article: article),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text("Error de búsqueda: $e")),
    );
  }

  Widget _buildRecomendaciones(AsyncValue<List<Map<String, dynamic>>> articlesAsync, String skinType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Recomendaciones para ti",
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)
            ),
            InkWell(
              onTap: _showComingSoon,
              child: const Text("Ver todas", style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 180,
          child: articlesAsync.when(
            data: (articles) {
              // Filtrar por tipo 'Recomendación'
              final recs = articles.where((art) {
                final parsed = parseArticleCategory(art['category'] ?? '');
                final isRec = parsed['type'] == 'Recomendación';
                final skin = parsed['skinType']!.toLowerCase();
                final userSkin = skinType.toLowerCase();
                
                // Coincidir con tipo de piel del usuario o 'todos'
                final matchesSkin = skin == 'todos' || userSkin.contains(skin) || skin.contains(userSkin);
                return isRec && matchesSkin;
              }).toList();

              if (recs.isEmpty) {
                return const Center(child: Text("No hay recomendaciones publicadas.", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)));
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: recs.length,
                itemBuilder: (context, index) {
                  final article = recs[index];
                  return _dermotipCard(context, article);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => const Center(child: Text("Error al cargar recomendaciones.")),
          ),
        ),
      ],
    );
  }

  Widget _buildNovedades(AsyncValue<List<Map<String, dynamic>>> articlesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Novedades",
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)
            ),
            InkWell(
              onTap: _showComingSoon,
              child: const Text("Ver todas", style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 180,
          child: articlesAsync.when(
            data: (articles) {
              if (articles.isEmpty) {
                return const Center(child: Text("No hay novedades publicadas.", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)));
              }

              // Mostrar los últimos 5 artículos creados, de cualquier tipo (Novedades)
              final novedades = articles.take(5).toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: novedades.length,
                itemBuilder: (context, index) {
                  final article = novedades[index];
                  return _dermotipCard(context, article);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => const Center(child: Text("Error al cargar novedades.")),
          ),
        ),
      ],
    );
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

  Widget _buildScannerButton(BuildContext context) {
    return InkWell(
      onTap: () {
        ref.read(patientTabProvider.notifier).state = 4; // Cambiar a pestaña de IA (Index 4) 🚀
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accentDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8)
              )
            ]
        ),
        child: const Row(
          children: [
            Icon(Icons.document_scanner_rounded, color: Colors.white, size: 40),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Escáner de Piel IA", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text("Analiza tu rostro al instante", style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersCard(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PatientRemindersView()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active, color: AppColors.secondary, size: 28),
            ),
            const SizedBox(width: 18),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Recordatorios y Hábitos",
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Ver rutinas diarias y alarmas activas",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildChatCard(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatInboxScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_rounded, color: AppColors.success, size: 28),
            ),
            const SizedBox(width: 18),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Chat de Consultas",
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Consulta directamente a tu médico especialista",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard(BuildContext context) {
    return InkWell(
      onTap: () {
        ref.read(patientTabProvider.notifier).state = 3; // Cambia a la pestaña de Clínicas (Index 3) 🚀
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.radar_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 18),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Radar de Clínicas y GPS",
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Ubica centros médicos dermatológicos cercanos",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          setState(() {}); // 🚀 Filtra artículos en tiempo real al escribir
        },
        onSubmitted: (value) {
          FocusScope.of(context).unfocus();
        },
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: "Buscar artículos o consejos para tu piel...",
          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                    FocusScope.of(context).unfocus();
                  },
                )
              : const Icon(Icons.search, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildCategoriasGrid() {
    return Row(
      children: [
        Expanded(child: _categoriaItem(context, "Patologías", Icons.coronavirus_outlined, const PathologiesCatalogScreen())),
        const SizedBox(width: 10),
        Expanded(child: _categoriaItem(context, "Piel", Icons.face_retouching_natural, const SkinProfileDetailScreen())),
        const SizedBox(width: 10),
        Expanded(child: _categoriaItem(context, "Productos", Icons.clean_hands_outlined, const SkincareProductsScreen())),
      ],
    );
  }

  Widget _categoriaItem(BuildContext context, String title, IconData icon, Widget targetScreen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => targetScreen),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: AppColors.primary, size: 36),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dermotipCard(BuildContext context, Map<String, dynamic> article) {
    final String title = article['title'] ?? 'Sin título';
    final String? imageUrl = article['image_url'];
    final String category = article['category'] ?? 'Dermotip';

    // Limpiamos los tags usando parseArticleCategory
    final parsed = parseArticleCategory(category);
    final displayCategory = parsed['name']!;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DermotipDetailScreen(article: article),
          ),
        );
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image o fallback
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.surfaceDark,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      )
                    else
                      Container(
                        color: AppColors.surfaceDark,
                        child: const Icon(Icons.spa_rounded, color: AppColors.primary, size: 30),
                      ),
                    
                    // Categoría Pill flotante
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          displayCategory.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Título del artículo
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCuestionarioList() {
    List<Widget> tiles = [
      _cuestionarioTile(
          "Tipo de Piel",
          "Descubre tus necesidades",
          Icons.assignment_outlined,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InitialQuizScreen()))
      ),
      const SizedBox(height: 10),
    ];

    for (var quiz in _customQuizzes) {
      tiles.add(
        _cuestionarioTile(
          quiz['title'] ?? 'Cuestionario',
          quiz['desc'] ?? 'Evaluación clínica',
          Icons.quiz_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DynamicQuizScreen(quiz: quiz),
            ),
          ).then((_) => _loadCustomQuizzes()),
        ),
      );
      tiles.add(const SizedBox(height: 10));
    }

    tiles.add(
      _cuestionarioTile(
          "Hábitos Actuales",
          "Evalúa tu rutina diaria",
          Icons.fact_check_outlined,
          _showComingSoon
      ),
    );

    return Column(children: tiles);
  }

  Widget _cuestionarioTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}

// 📖 PANTALLA DETALLADA DE DERMOTIPS DE ALTA FIDELIDAD
class DermotipDetailScreen extends StatelessWidget {
  final Map<String, dynamic> article;

  const DermotipDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final String title = article['title'] ?? 'Artículo de Cuidado';
    final String content = article['content'] ?? 'Sin contenido disponible.';
    final String category = article['category'] ?? 'Dermotip';
    final String? imageUrl = article['image_url'];

    // Limpiamos los tags de tipo de piel de la categoría para no afear el chip en UI
    final displayCategory = category.contains(" - ") 
        ? category.split(" - ").last 
        : category;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // 🚀 HEADER DINÁMICO CON PARALLAX Y DEGRADADO
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, size: 60, color: Colors.white60),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      child: const Icon(Icons.spa_rounded, size: 80, color: Colors.white30),
                    ),
                  // Gradiente estético oscuro para asegurar legibilidad de los botones
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black54, Colors.transparent, Colors.black87],
                        stops: [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 📄 CUERPO ENRIQUECIDO DEL ARTÍCULO
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              decoration: const BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoría Pill flotante
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      displayCategory.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Título principal del post
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Contenido detallado del artículo
                  Text(
                    content,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}