import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/profile_provider.dart';
import '../../auth/initial_quiz_screen.dart';
import 'patient_home_view.dart';

class SkinProfileDetailScreen extends ConsumerWidget {
  const SkinProfileDetailScreen({super.key});

  Map<String, dynamic> _getSkinDetails(String skinType) {
    final normalized = skinType.toLowerCase().trim();
    if (normalized.contains('sec')) {
      return {
        "title": "Piel Seca",
        "description": "Tu piel produce menos sebo del necesario, comprometiendo la barrera lipídica y causando tirantez y descamación ocasional.",
        "characteristics": [
          "Sensación frecuente de tirantez tras el lavado",
          "Descamación y parches secos en mejillas",
          "Poros muy finos y textura ligeramente opaca"
        ],
        "recommended": [
          "Ceramidas",
          "Ácido Hialurónico",
          "Manteca de Karité",
          "Escualano"
        ],
        "avoided": [
          "Jabones espumosos (sulfatos)",
          "Alcohol desnaturalizado",
          "Exfoliantes físicos ásperos"
        ],
        "advice": [
          "Evita jabones astringentes; prefiere aceites o leches limpiadoras syndet.",
          "Busca activos emolientes como ceramidas, manteca de shea o aceite de jojoba.",
          "Aplica capas delgadas de hidratación (método sándwich) sellando con crema oclusiva.",
          "Evita exfoliarte más de una vez cada 15 días con exfoliantes químicos suaves."
        ],
        "bgGradient": [const Color(0xFFFFF2E6), const Color(0xFFFFD9B3)]
      };
    } else if (normalized.contains('gras')) {
      return {
        "title": "Piel Grasa",
        "description": "Tienes glándulas sebáceas hiperactivas que producen un exceso de sebo, favoreciendo poros dilatados, brillo persistente e imperfecciones.",
        "characteristics": [
          "Brillo constante y persistente en todo el rostro",
          "Poros visiblemente dilatados en zona T y mejillas",
          "Textura más gruesa y propensión a brotes"
        ],
        "recommended": [
          "Ácido Salicílico (BHA)",
          "Niacinamida",
          "Zinc PCA",
          "Ácido Hialurónico fluido"
        ],
        "avoided": [
          "Aceites pesados (coco, mineral)",
          "Cremas hidratantes oclusivas",
          "Cosméticos comedogénicos"
        ],
        "advice": [
          "Usa limpiadores tipo gel espumoso con ácido salicílico o gluconolactona.",
          "Prefiere hidratantes ligeros con base de agua (texturas gel o gel-crema).",
          "Incorpora niacinamida al 5% para regular la seborrea y minimizar poros.",
          "Usa protector solar con toque seco (oil-free) y acabado mate diariamente."
        ],
        "bgGradient": [const Color(0xFFE6F7FF), const Color(0xFFB3E6FF)]
      };
    } else if (normalized.contains('mixt')) {
      return {
        "title": "Piel Mixta",
        "description": "Presentas producción de grasa en la zona T (frente, nariz y barbilla) con poros dilatados, mientras las mejillas permanecen normales o secas.",
        "characteristics": [
          "Brillo evidente en frente, nariz y mentón (Zona T)",
          "Mejillas secas o normales con sensación de tirantez",
          "Poros visibles concentrados en la zona de la nariz"
        ],
        "recommended": [
          "Ácido Hialurónico",
          "Niacinamida",
          "Pantenol (Vitamina B5)",
          "Ácido Salicílico suave"
        ],
        "avoided": [
          "Geles astringentes fuertes en todo el rostro",
          "Aceites pesados en la zona T"
        ],
        "advice": [
          "Aplica multimasking: arcillas reguladoras en zona T, hidratación en mejillas.",
          "Usa limpiadores suaves equilibrantes que no resequen pero limpien poros.",
          "Incorpora sueros fluidos con ácido hialurónico y niacinamida mixta.",
          "Utiliza fórmulas fluidas matificantes que balanceen ambas zonas."
        ],
        "bgGradient": [const Color(0xFFF9F2FF), const Color(0xFFEBD6FF)]
      };
    } else if (normalized.contains('sensib')) {
      return {
        "title": "Piel Sensible",
        "description": "Tu barrera cutánea es altamente permeable y reacciona de forma exagerada ante factores externos, causando rojez, ardor y resequedad.",
        "characteristics": [
          "Enrojecimiento fácil ante cambios térmicos o roces",
          "Sensación frecuente de ardor, tirantez o picazón",
          "Barrera cutánea debilitada y reactividad a productos"
        ],
        "recommended": [
          "Centella Asiática (Cica)",
          "Avena Coloidal",
          "Alantoína",
          "Ceramidas puras"
        ],
        "avoided": [
          "Fragancias sintéticas y perfumes",
          "Aceites esenciales concentrados",
          "Exfoliantes químicos concentrados"
        ],
        "advice": [
          "Usa productos catalogados como hipoalergénicos y libres de fragancias.",
          "Busca activos sumamente calmantes como avena coloidal, pantenol y caléndula.",
          "Realiza una prueba de parche en tu antebrazo antes de usar cualquier producto nuevo.",
          "Protege tu rostro del frío, calor extremo y sol directo con fórmulas minerales."
        ],
        "bgGradient": [const Color(0xFFFFECEF), const Color(0xFFFFD1D8)]
      };
    } else {
      return {
        "title": "Piel Normal",
        "description": "Posees una piel en perfecto equilibrio hidrolipídico. No es propensa a imperfecciones, sequedad extrema ni sensibilidad relevante.",
        "characteristics": [
          "Textura suave, elástica y de tono uniforme",
          "Poros muy finos y poco visibles",
          "Ausencia de brillo excesivo o resequedad"
        ],
        "recommended": [
          "Vitamina C",
          "Ácido Hialurónico",
          "Antioxidantes",
          "Péptidos"
        ],
        "avoided": [
          "Rutinas sobrecargadas con demasiados activos",
          "Productos agresivos innecesarios"
        ],
        "advice": [
          "Mantén tu rutina simple y consistente: limpieza, hidratación y fotoprotección.",
          "Agrega antioxidantes matutinos como Vitamina C para potenciar luminosidad.",
          "Exfolia suavemente una vez por semana con ácido láctico o enzimas.",
          "Conserva la constancia y duerme las horas reparadoras necesarias."
        ],
        "bgGradient": [const Color(0xFFEBFDF7), const Color(0xFFC7F9E5)]
      };
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final articlesAsync = ref.watch(articlesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Tu Perfil Cutáneo",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: profileAsync.when(
        data: (profile) {
          final skinType = profile?['skin_type'] ?? "en evaluación";
          final details = _getSkinDetails(skinType);

          return articlesAsync.when(
            data: (articles) {
              final normalizedUserSkinType = skinType.toLowerCase().trim();

              final dbArticles = articles.where((art) {
                final parsed = parseArticleCategory(art['category'] ?? '');
                if (parsed['type'] != 'Piel') return false;

                final artSkinType = parsed['skinType']?.toLowerCase().trim() ?? 'todos';
                if (artSkinType == 'todos' || artSkinType.isEmpty) return true;

                if (normalizedUserSkinType.contains('sec') && artSkinType.contains('sec')) return true;
                if (normalizedUserSkinType.contains('gras') && artSkinType.contains('gras')) return true;
                if (normalizedUserSkinType.contains('mixt') && artSkinType.contains('mixt')) return true;
                if (normalizedUserSkinType.contains('sensib') && artSkinType.contains('sensib')) return true;
                if (normalizedUserSkinType.contains('normal') && artSkinType.contains('normal')) return true;

                return normalizedUserSkinType.contains(artSkinType) || artSkinType.contains(normalizedUserSkinType);
              }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🏷️ Tarjeta WOW del Tipo de Piel
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: details['bgGradient'] as List<Color>,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: (details['bgGradient'] as List<Color>)[1].withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "BIOTIPO DE PIEL",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            details['title'],
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            details['description'],
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // 📋 Características Clínicas
                    const Text("Características Clínicas", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 15),
                    _buildCharacteristicsCard(details['characteristics'] as List),
                    const SizedBox(height: 25),

                    // 🔬 Guía de Ingredientes y Activos
                    const Text("Guía de Ingredientes y Activos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 15),
                    _buildIngredientsGuideCard(
                      details['recommended'] as List,
                      details['avoided'] as List,
                    ),
                    const SizedBox(height: 25),

                    // 📋 Consejos del Dermatólogo
                    const Text("Directrices de Cuidado Diario", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 15),
                    ...List.generate(
                      (details['advice'] as List).length,
                      (index) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.star, color: AppColors.primary, size: 14),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                details['advice'][index],
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Artículos Dinámicos de Piel
                    if (dbArticles.isNotEmpty) ...[
                      const SizedBox(height: 25),
                      const Text(
                        "Artículos de Interés para tu Piel",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 15),
                      ...dbArticles.map((article) {
                        final categoryParsed = parseArticleCategory(article['category'] ?? '');
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
                              width: 70,
                              height: 70,
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
                            subtitle: Text(
                              categoryParsed['name'] ?? 'Cuidado de la piel',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                      }),
                    ],

                    const SizedBox(height: 30),

                    // ⚙️ Botón de Re-evaluación
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const InitialQuizScreen()),
                          );
                        },
                        icon: const Icon(Icons.refresh, color: AppColors.primary, size: 18),
                        label: const Text("Volver a evaluar mi piel", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.primary, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(child: Text("Error al cargar artículos de piel: $e")),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildCharacteristicsCard(List<dynamic> chars) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: chars.map((char) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    char.toString(),
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIngredientsGuideCard(List<dynamic> recommended, List<dynamic> avoided) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Para tu tipo de piel es recomendable:",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recommended.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.15)),
                ),
                child: Text(
                  item.toString(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            "No es recomendable usar:",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: avoided.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15)),
                ),
                child: Text(
                  item.toString(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
