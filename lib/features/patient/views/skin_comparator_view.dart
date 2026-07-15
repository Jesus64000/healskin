import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

// ============================================================================
// 📱 1. PANTALLA DE SELECCIÓN DE IMÁGENES
// ============================================================================
class SkinComparatorSelectionScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String title;

  const SkinComparatorSelectionScreen({
    super.key,
    required this.items,
    this.title = "Comparar Evolución",
  });

  @override
  State<SkinComparatorSelectionScreen> createState() => _SkinComparatorSelectionScreenState();
}

class _SkinComparatorSelectionScreenState extends State<SkinComparatorSelectionScreen> {
  final List<Map<String, dynamic>> _selectedItems = [];

  // Filtramos los ítems que realmente tengan una URL de imagen válida
  late final List<Map<String, dynamic>> _validItems;

  @override
  void initState() {
    super.initState();
    _validItems = widget.items.where((item) {
      final url = item['image_url'] as String?;
      return url != null && url.isNotEmpty;
    }).toList();
  }

  void _toggleSelection(Map<String, dynamic> item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        if (_selectedItems.length >= 2) {
          // Si ya seleccionó 2, removemos el primero seleccionado e insertamos el nuevo
          _selectedItems.removeAt(0);
        }
        _selectedItems.add(item);
      }
    });
  }

  void _startComparison() {
    if (_selectedItems.length != 2) return;

    // Ordenamos por fecha de creación para saber cuál es el "Antes" y cuál es el "Después"
    final itemA = _selectedItems[0];
    final itemB = _selectedItems[1];

    final dateA = DateTime.parse(itemA['created_at'] ?? DateTime.now().toIso8601String());
    final dateB = DateTime.parse(itemB['created_at'] ?? DateTime.now().toIso8601String());

    final Map<String, dynamic> beforeItem;
    final Map<String, dynamic> afterItem;

    if (dateA.isBefore(dateB)) {
      beforeItem = itemA;
      afterItem = itemB;
    } else {
      beforeItem = itemB;
      afterItem = itemA;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BeforeAfterSliderScreen(
          beforeUrl: beforeItem['image_url'],
          beforeDate: dateA.isBefore(dateB) ? dateA : dateB,
          afterUrl: afterItem['image_url'],
          afterDate: dateA.isBefore(dateB) ? dateB : dateA,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _validItems.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "No hay suficientes imágenes con análisis en tu historial para realizar comparaciones.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Selecciona exactamente 2 imágenes para compararlas. (${_selectedItems.length}/2)",
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _validItems.length,
                    itemBuilder: (context, index) {
                      final item = _validItems[index];
                      final isSelected = _selectedItems.contains(item);
                      final url = item['image_url']!;

                      final date = DateTime.parse(item['created_at'] ?? DateTime.now().toIso8601String()).toLocal();
                      final dateFormatted = DateFormat('dd MMM, yyyy', 'es').format(date);

                      return GestureDetector(
                        onTap: () => _toggleSelection(item),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.black.withValues(alpha: 0.05),
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(url, fit: BoxFit.cover),
                              // Overlay negro sutil abajo para leer el texto
                              Positioned(
                                bottom: 0, left: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.transparent, Colors.black87],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  child: Text(
                                    dateFormatted,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              // Selector numérico o checkbox
                              Positioned(
                                top: 8, right: 8,
                                child: Container(
                                  width: 26, height: 26,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : Colors.black45,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: Center(
                                    child: isSelected
                                        ? Text(
                                            "${_selectedItems.indexOf(item) + 1}",
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _selectedItems.length == 2 ? _startComparison : null,
                        icon: const Icon(Icons.compare_arrows_rounded, color: Colors.white),
                        label: const Text("Comparar Ahora", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: Colors.grey[300],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
    );
  }
}

// ============================================================================
// ↕️ 2. INTERFAZ DESLIZABLE COMPARA-LESIONES (ANTES Y DESPUÉS)
// ============================================================================
class BeforeAfterSliderScreen extends StatefulWidget {
  final String beforeUrl;
  final DateTime beforeDate;
  final String afterUrl;
  final DateTime afterDate;

  const BeforeAfterSliderScreen({
    super.key,
    required this.beforeUrl,
    required this.beforeDate,
    required this.afterUrl,
    required this.afterDate,
  });

  @override
  State<BeforeAfterSliderScreen> createState() => _BeforeAfterSliderScreenState();
}

class _BeforeAfterSliderScreenState extends State<BeforeAfterSliderScreen> {
  double _slidePercent = 0.5; // Comienza a la mitad (50%)
  bool _showSideBySide = false;

  @override
  Widget build(BuildContext context) {
    final beforeDateStr = DateFormat('dd/MM/yyyy').format(widget.beforeDate);
    final afterDateStr = DateFormat('dd/MM/yyyy').format(widget.afterDate);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Evolutivo Dérmico Táctil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Selector de modo de comparación (Deslizar vs Lado a Lado)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _showSideBySide = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: !_showSideBySide ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text("Deslizar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _showSideBySide = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: _showSideBySide ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text("Lado a Lado", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),

              if (_showSideBySide)
                // 📱 VISTA LADO A LADO
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            // Antes
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "ANTES ($beforeDateStr)",
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Image.network(widget.beforeUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            // Después
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "DESPUÉS ($afterDateStr)",
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Image.network(widget.afterUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                // 📦 CONTENEDOR PRINCIPAL DEL COMPARADOR (SLIDER)
                Container(
                  height: 480,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final height = constraints.maxHeight;

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // A. FOTO "DESPUÉS" (Fondo)
                          Image.network(
                            widget.afterUrl,
                            width: width,
                            height: height,
                            fit: BoxFit.cover,
                          ),

                          // B. FOTO "ANTES" (Superior con recorte inteligente)
                          ClipRect(
                            clipper: _BeforeAfterClipper(_slidePercent),
                            child: Image.network(
                              widget.beforeUrl,
                              width: width,
                              height: height,
                              fit: BoxFit.cover,
                            ),
                          ),

                          // C. LÍNEA DIVISORIA VERTICAL
                          Positioned(
                            left: width * _slidePercent - 1.5,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 3,
                              color: Colors.white,
                            ),
                          ),

                          // D. MANIJA DESLIZABLE CENTRAL
                          Positioned(
                            left: width * _slidePercent - 20,
                            top: height / 2 - 20,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)
                                ],
                                border: Border.all(color: Colors.white, width: 2.5),
                              ),
                              child: const Icon(Icons.unfold_more_rounded, color: Colors.white, size: 24),
                            ),
                          ),

                          // E. ETIQUETAS DE TEXTO
                          Positioned(
                            left: 15,
                            top: 15,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                "ANTES ($beforeDateStr)",
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 15,
                            top: 15,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                "DESPUÉS ($afterDateStr)",
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            ),
                          ),

                          // F. GESTOS TÁCTILES (Capa Invisible superior)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragUpdate: (details) {
                                final localX = details.localPosition.dx;
                                setState(() {
                                  _slidePercent = (localX / width).clamp(0.0, 1.0);
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 30),
              Text(
                _showSideBySide
                    ? "Observa ambas imágenes en su tamaño completo para comparar detalladamente tu evolución clínica."
                    : "Desliza el botón central con tu dedo de izquierda a derecha para comparar los cambios dérmicos.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ✂️ 3. CORTADOR PERSONALIZADO PARA EFECTO ANTES/DESPUÉS
// ============================================================================
class _BeforeAfterClipper extends CustomClipper<Rect> {
  final double slidePercent;
  _BeforeAfterClipper(this.slidePercent);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * slidePercent, size.height);
  }

  @override
  bool shouldReclip(_BeforeAfterClipper oldClipper) {
    return oldClipper.slidePercent != slidePercent;
  }
}
