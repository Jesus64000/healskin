import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../patient_dashboard.dart';
import '../../auth/profile_provider.dart';
import 'patient_home_view.dart';

class PathologiesCatalogScreen extends ConsumerWidget {
  const PathologiesCatalogScreen({super.key});

  final List<Map<String, dynamic>> _pathologies = const [
    {
      "name": "Acné Vulgar",
      "symptoms": "Erupciones cutáneas, puntos negros, pústulas inflamadas, exceso de sebo.",
      "desc": "Afección cutánea común que se produce cuando los folículos pilosos se tapan con grasa y células cutáneas muertas, provocando inflamación bacteriana.",
      "tips": [
        "Limpia tu rostro dos veces al día con un dermolimpiador espumoso suave.",
        "Evita tocar o exprimir las lesiones para prevenir cicatrices duraderas.",
        "Usa productos no comedogénicos y libres de aceites minerales.",
        "Aplica protector solar gel libre de grasa diariamente."
      ],
      "icon": Icons.healing,
      "severity": "Leve a Moderado",
      "severityColor": AppColors.warning
    },
    {
      "name": "Rosácea",
      "symptoms": "Enrojecimiento persistente, vasos sanguíneos visibles (telangiectasias), ardor.",
      "desc": "Enfermedad inflamatoria crónica que afecta principalmente la piel de las mejillas, nariz, frente y barbilla. Causa sensibilidad extrema ante cambios térmicos.",
      "tips": [
        "Evita comidas muy picantes, bebidas muy calientes y la exposición solar directa.",
        "Elige fórmulas calmantes con niacinamida, ácido hialurónico o centella asiática.",
        "Limpia tu piel con agua templada; evita frotar con toallas ásperas.",
        "Utiliza protectores solares minerales (óxido de zinc o dióxido de titanio)."
      ],
      "icon": Icons.face,
      "severity": "Moderado",
      "severityColor": AppColors.warning
    },
    {
      "name": "Dermatitis Atópica",
      "symptoms": "Picazón intensa (prurito), descamación extrema, placas rojizas y secas.",
      "desc": "Trastorno que provoca el enrojecimiento y picor de la piel, caracterizado por una barrera cutánea debilitada y propensa a reacciones alérgicas y sequedad profunda.",
      "tips": [
        "Toma duchas cortas con agua tibia (menos de 10 minutos) y jabón syndet.",
        "Aplica una crema emoliente ultra-nutritiva inmediatamente después del baño.",
        "Prefiere ropa de algodón y evita fibras sintéticas o lana irritantes.",
        "Mantén los ambientes ventilados y libres de polvo."
      ],
      "icon": Icons.waves,
      "severity": "Moderado",
      "severityColor": AppColors.warning
    },
    {
      "name": "Psoriasis",
      "symptoms": "Escamas gruesas y plateadas sobre placas rojizas, picor, descamación en codos.",
      "desc": "Afección en la que las células de la piel se acumulan rápidamente, formando escamas gruesas y secas de recambio acelerado debido a una respuesta inmune.",
      "tips": [
        "Hidrata profundamente tu piel con queratolíticos (urea o ácido salicílico suave).",
        "Toma baños de sol controlados por breves minutos matutinos.",
        "Evita el rascado excesivo para no inducir lesiones secundarias.",
        "Controla los niveles de estrés, que actúan como desencadenante común."
      ],
      "icon": Icons.texture,
      "severity": "Moderado a Crítico",
      "severityColor": AppColors.danger
    },
    {
      "name": "Melanoma y Lunares Típicos",
      "symptoms": "Cambio de color o tamaño en lunares (Regla ABCDE), bordes irregulares, asimetría.",
      "desc": "El tipo más serio de cáncer de piel, que se desarrolla en las células productoras de melanina. Es fundamental el diagnóstico médico precoz.",
      "tips": [
        "Aplica y reaplica protector solar FPS 50+ de amplio espectro cada 3 horas.",
        "Evita cámaras de bronceo y exposición solar intensa entre 10 a.m. y 4 p.m.",
        "Revisa tus lunares mensualmente buscando cambios de tamaño o color.",
        "Agenda un control anual con tu dermatólogo certificado."
      ],
      "icon": Icons.report_problem,
      "severity": "Crítico (Urgente)",
      "severityColor": AppColors.danger
    }
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(articlesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Enciclopedia de Patologías",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: articlesAsync.when(
        data: (articles) {
          final dbPatologias = articles.where((art) {
            final parsed = parseArticleCategory(art['category'] ?? '');
            return parsed['type'] == 'Patología';
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 1. Catálogo Estático (Enciclopedia)
              const Text(
                "Condiciones Comunes",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 15),
              ...List.generate(_pathologies.length, (index) {
                final path = _pathologies[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ExpansionTile(
                    shape: const Border(),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(path['icon'], color: AppColors.primary, size: 24),
                    ),
                    title: Text(
                      path['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: path['severityColor'], shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Severidad: ${path['severity']}",
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              "¿Qué es?",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              path['desc'],
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Síntomas Comunes:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              path['symptoms'],
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              "Consejos y Cuidados recomendados:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(
                              (path['tips'] as List).length,
                              (tIndex) => Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        path['tips'][tIndex],
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context); // Cierra enciclopedia
                                  ref.read(patientTabProvider.notifier).state = 4; // Cambia a pestaña IA (Index 4) 🚀
                                },
                                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                label: const Text(
                                  "Escanear Lesión con IA",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // 2. Artículos Dinámicos de Patologías
              if (dbPatologias.isNotEmpty) ...[
                const SizedBox(height: 25),
                const Text(
                  "Artículos y Guías Informativas",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 15),
                ...dbPatologias.map((article) {
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
                        categoryParsed['name'] ?? 'Patología',
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
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }
}
