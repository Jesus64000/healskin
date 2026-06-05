import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/profile_provider.dart';
import 'patient_home_view.dart';

class SkincareProductsScreen extends ConsumerWidget {
  const SkincareProductsScreen({super.key});

  List<Map<String, dynamic>> _getRoutineSteps(String skinType) {
    final normalized = skinType.toLowerCase().trim();
    if (normalized.contains('sec')) {
      return [
        {
          "step": "1. Limpieza",
          "time": "Día y Noche",
          "action": "Dermolimpiador Hidratante en Crema o Leche",
          "actives": "Glicerina, Aceite de Jojoba, Ceramidas",
          "desc": "Limpia sin retirar la escasa grasa natural de la piel, protegiendo la barrera de humedad.",
          "badge": "Syndet Suave",
          "badgeColor": AppColors.success
        },
        {
          "step": "2. Tratamiento (Suero)",
          "time": "Noche (Opcional)",
          "action": "Suero de Ácido Hialurónico Ultra Concentrado",
          "actives": "Ácido Hialurónico Multipeso Molecular, Pantenol",
          "desc": "Atrae agua a las capas profundas de la piel rellenando y calmando la tirantez.",
          "badge": "Hidratante",
          "badgeColor": AppColors.primary
        },
        {
          "step": "3. Hidratación",
          "time": "Día y Noche",
          "action": "Crema Rica Emoliente Barrera",
          "actives": "Ceramidas AP/NP/EOP, Manteca de Karité, Escualano",
          "desc": "Sella la humedad y restaura los lípidos perdidos en la barrera lipídica deficiente.",
          "badge": "Nutritiva",
          "badgeColor": Colors.orangeAccent
        },
        {
          "step": "4. Protección Solar",
          "time": "Cada Mañana",
          "action": "Protector Solar FPS 50+ Crema Hidratante",
          "actives": "Filtros Orgánicos Hidratantes, Vitamina E",
          "desc": "Brinda protección solar alta con textura cremosa para evitar resequedad extrema.",
          "badge": "FPS 50+",
          "badgeColor": AppColors.secondary
        }
      ];
    } else if (normalized.contains('gras')) {
      return [
        {
          "step": "1. Limpieza",
          "time": "Día y Noche",
          "action": "Gel Limpiador Purificante Sebo-Regulador",
          "actives": "Ácido Salicílico (BHA), Gluconato de Zinc, Árbol de Té",
          "desc": "Limpia los poros en profundidad eliminando el sebo y reduciendo bacterias asociadas al acné.",
          "badge": "Purificante",
          "badgeColor": AppColors.success
        },
        {
          "step": "2. Tratamiento (Suero)",
          "time": "Día / Noche",
          "action": "Suero de Niacinamida al 10% y Zinc PCA",
          "actives": "Niacinamida, Zinc PCA, Ácido Salicílico",
          "desc": "Controla la seborrea y el brillo persistente mientras reduce rojeces y marcas de acné.",
          "badge": "Sebo-Regulador",
          "badgeColor": AppColors.primary
        },
        {
          "step": "3. Hidratación",
          "time": "Día y Noche",
          "action": "Gel-Crema Ultra Ligero Matificante",
          "actives": "Ácido Hialurónico Base Agua, Extracto de Té Verde",
          "desc": "Brinda agua sin aportar aceites pesados, dejando la piel con acabado fresco y mate.",
          "badge": "Toque Seco",
          "badgeColor": Colors.teal
        },
        {
          "step": "4. Protección Solar",
          "time": "Cada Mañana",
          "action": "Fotoprotector Gel Toque Seco FPS 50+ Mate",
          "actives": "Filtros Físicos/Químicos Toque Seco, Niacinamida",
          "desc": "Protege de la radiación UV controlando los brillos y con efecto absorbente de sebo.",
          "badge": "FPS 50+ Mate",
          "badgeColor": AppColors.secondary
        }
      ];
    } else if (normalized.contains('mixt')) {
      return [
        {
          "step": "1. Limpieza",
          "time": "Día y Noche",
          "action": "Gel Limpiador Balanceador Suave",
          "actives": "Glicerina, Alantoína, Aminoácidos de Trigo",
          "desc": "Equilibra: remueve grasa de la zona T sin maltratar ni resecar las mejillas.",
          "badge": "Equilibrante",
          "badgeColor": AppColors.success
        },
        {
          "step": "2. Tratamiento (Suero)",
          "time": "Día y Noche",
          "action": "Suero Fluidificado Hidratante Balanceador",
          "actives": "Ácido Hialurónico, Niacinamida al 5%",
          "desc": "Hidrata las zonas secas y regula el brillo de la zona T simultáneamente.",
          "badge": "Antioxidante",
          "badgeColor": AppColors.primary
        },
        {
          "step": "3. Hidratación",
          "time": "Día y Noche",
          "action": "Loción o Emulsión Hidratante Balanceadora",
          "actives": "Escualano Vegetal, Ácido Hialurónico, Ceramidas ligeras",
          "desc": "Proporciona una nutrición equilibrada y ligera apta para todo el rostro.",
          "badge": "Emulsión Ligera",
          "badgeColor": Colors.teal
        },
        {
          "step": "4. Protección Solar",
          "time": "Cada Mañana",
          "action": "Protector Solar Fluido Mate FPS 50+",
          "actives": "Filtros solares fluidos, Vitamina C/E",
          "desc": "Textura ultra líquida no grasosa que previene el brillo en la frente y nariz.",
          "badge": "Fluido Ligero",
          "badgeColor": AppColors.secondary
        }
      ];
    } else if (normalized.contains('sensib')) {
      return [
        {
          "step": "1. Limpieza",
          "time": "Día y Noche",
          "action": "Loción Limpiadora Tolerancia Syndet Sin Enjuague",
          "actives": "Agua Termal, Pantenol, Extracto de Avena Coloidal",
          "desc": "Retira impurezas de forma sumamente delicada respetando la hipersensibilidad dérmica.",
          "badge": "Hipoalergénico",
          "badgeColor": AppColors.success
        },
        {
          "step": "2. Tratamiento (Suero)",
          "time": "Día / Noche",
          "action": "Suero Calmante Anti-Rojeces",
          "actives": "Centella Asiática (CICA), Alantoína, Madecasósido",
          "desc": "Repara la barrera cutánea dañada aliviando el picor y disminuyendo las rojeces epidérmicas.",
          "badge": "Calmante CICA",
          "badgeColor": AppColors.primary
        },
        {
          "step": "3. Hidratación",
          "time": "Día y Noche",
          "action": "Crema Reparadora Tolerancia Extrema",
          "actives": "Ceramidas puras, Escualano, Manteca de Karité refinada",
          "desc": "Protege y nutre la piel sensible reconstruyendo la barrera de defensas comprometida.",
          "badge": "Anti-Irritante",
          "badgeColor": Colors.pinkAccent
        },
        {
          "step": "4. Protección Solar",
          "time": "Cada Mañana",
          "action": "Protector Solar 100% Mineral FPS 50+",
          "actives": "Óxido de Zinc, Dióxido de Titanio, Bisabolol",
          "desc": "Filtros puramente físicos que reflejan los rayos UV sin generar ardor ni irritación química.",
          "badge": "Filtro Mineral",
          "badgeColor": AppColors.secondary
        }
      ];
    } else {
      // Normal
      return [
        {
          "step": "1. Limpieza",
          "time": "Día y Noche",
          "action": "Espuma Limpiadora Suave e Iluminadora",
          "actives": "Glicerina, Alantoína, Extracto de Manzanilla",
          "desc": "Limpia y tonifica la piel conservando su óptimo balance hidrolipídico.",
          "badge": "Limpieza Diaria",
          "badgeColor": AppColors.success
        },
        {
          "step": "2. Tratamiento (Suero)",
          "time": "Día (Vitamina C) / Noche (Ácido Hialurónico)",
          "action": "Suero de Vitamina C al 10% / Ácido Hialurónico",
          "actives": "Ácido Ascórbico Estabilizado, Vitamina E",
          "desc": "Protege contra radicales libres y potencia la luminosidad natural de tu rostro.",
          "badge": "Antioxidante",
          "badgeColor": AppColors.primary
        },
        {
          "step": "3. Hidratación",
          "time": "Día y Noche",
          "action": "Loción Hidratante de Textura Sedosa",
          "actives": "Ácido Hialurónico, Ceramidas básicas",
          "desc": "Mantiene el nivel saludable y estable de hidratación celular durante 24 horas.",
          "badge": "Nutrición Equilibrada",
          "badgeColor": Colors.teal
        },
        {
          "step": "4. Protección Solar",
          "time": "Cada Mañana",
          "action": "Protector Solar Fluido Invisible FPS 50+",
          "actives": "Filtros químicos invisibles de amplio espectro",
          "desc": "Fotoprotección de amplio espectro con un acabado sedoso ideal para uso cotidiano.",
          "badge": "Toque Invisible",
          "badgeColor": AppColors.secondary
        }
      ];
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
          "Rutina e Ingredientes Activos",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: profileAsync.when(
        data: (profile) {
          final skinType = profile?['skin_type'] ?? "en evaluación";
          final steps = _getRoutineSteps(skinType);

          return articlesAsync.when(
            data: (articles) {
              final dbProductos = articles.where((art) {
                final parsed = parseArticleCategory(art['category'] ?? '');
                return parsed['type'] == 'Producto';
              }).toList();

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 1. Cabecera
                  Container(
                    margin: const EdgeInsets.only(bottom: 25),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 8)]),
                          child: const Icon(Icons.science, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Ingredientes Sugeridos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(height: 4),
                              Text(
                                "Rutina de cuidado facial de 4 pasos optimizada de acuerdo a tu piel: $skinType.",
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Pasos de la Rutina
                  ...steps.map((step) => Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.01),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              step['step'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (step['badgeColor'] as Color).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                step['badge'],
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: step['badgeColor']),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              "Aplicación: ${step['time']}",
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        const Text("FÓRMULA RECOMENDADA:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text(
                          step['action'],
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const SizedBox(height: 12),
                        const Text("ACTIVOS CLAVE:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text(
                          step['actives'],
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          step['desc'],
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  )),

                  // 3. Artículos Dinámicos de Productos
                  if (dbProductos.isNotEmpty) ...[
                    const SizedBox(height: 25),
                    const Text(
                      "Artículos de Productos Recomendados",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 15),
                    ...dbProductos.map((article) {
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
                            categoryParsed['name'] ?? 'Producto',
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
            error: (e, _) => Center(child: Text("Error al cargar artículos de productos: $e")),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }
}

