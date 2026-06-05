import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ClinicalPdfService {
  static Future<void> exportPatientHistory({
    required Map<String, dynamic> profile,
    required List<dynamic> scans,
    required List<dynamic> notes,
    required List<dynamic> appointments,
  }) async {
    final pdf = pw.Document();

    final String fullName = profile['full_name'] ?? 'Paciente Desconocido';
    final String idCard = profile['identification_id'] ?? 'No registrada';
    final String skinType = (profile['skin_type']?.toString().toUpperCase() ?? 'NO DEFINIDO');
    final String glow = profile['glow_frequency'] ?? 'No respondido';
    final String acne = profile['has_acne'] ?? 'No respondido';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(35),
        build: (context) => [
          // 🚀 CABECERA CLÍNICA CORPORATIVA
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "HEALSKIN CLINIC",
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#4B39EF'), // Color Primario
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    "Preservación Inteligente del Cuidado de la Piel",
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "REPORTE CLÍNICO",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#FF7A70'), // Color Secundario
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    "Fecha: ${DateFormat('dd/MM/yyyy - hh:mm a').format(DateTime.now())}",
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 1.5, color: PdfColor.fromHex('#4B39EF')),
          pw.SizedBox(height: 15),

          // 👤 FICHA DEMOGRÁFICA DEL PACIENTE
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "1. DATOS PERSONALES DEL PACIENTE",
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Nombre Completo: $fullName", style: const pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(height: 4),
                          pw.Text("Cédula / ID: $idCard", style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Tipo de Piel: $skinType", style: const pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(height: 4),
                          pw.Text("Propensión Acné: $acne", style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // 🔬 HISTORIAL DE ESCANEOS IA (DIAGNOSTICO ASISTIDO)
          pw.Text(
            "2. DIAGNÓSTICO ASISTIDO POR IA - EVOLUCIÓN",
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#4B39EF')),
          ),
          pw.SizedBox(height: 8),
          if (scans.isEmpty)
            pw.Text("El paciente aún no ha realizado escaneos de evolución en-app.", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
          else
            pw.Table(
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                verticalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(4),
              },
              children: [
                // Cabecera Tabla
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Fecha", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Diagnóstico IA", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Riesgo", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Recomendación IA", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                // Filas Tabla
                ...scans.map((scan) {
                  final date = DateTime.parse(scan['created_at']).toLocal();
                  final dateFormatted = DateFormat('dd/MM/yyyy').format(date);
                  final String rawRisk = (scan['risk_level'] ?? 'low').toString().toLowerCase().trim();
                  String riskLabel = 'Bajo';
                  if (rawRisk.contains('medium') || rawRisk.contains('medio')) {
                    riskLabel = 'Medio';
                  } else if (rawRisk.contains('high') || rawRisk.contains('alto')) {
                    riskLabel = 'Alto';
                  } else if (rawRisk.contains('urgent') || rawRisk.contains('urgente')) {
                    riskLabel = 'Urgente';
                  }
                  final String diag = scan['ai_diagnosis'] ?? 'Análisis Dérmico';
                  final String rec = scan['recommendation'] ?? 'Sin observaciones';

                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(dateFormatted, style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(diag, style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(riskLabel, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(rec, style: const pw.TextStyle(fontSize: 8))),
                    ],
                  );
                }),
              ],
            ),
          pw.SizedBox(height: 20),

          // 📝 HISTORIAL CLÍNICO DE NOTAS MÉDICAS (DERMATÓLOGO)
          pw.Text(
            "3. HISTORIAL DE NOTAS CLÍNICAS (MÉDICO)",
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#4B39EF')),
          ),
          pw.SizedBox(height: 8),
          if (notes.isEmpty)
            pw.Text("No se registran consultas ni notas clínicas de especialistas aún.", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
          else
            pw.Column(
              children: notes.map((note) {
                final date = DateTime.parse(note['created_at']).toLocal();
                final dateFormatted = DateFormat('dd/MM/yyyy - hh:mm a').format(date);
                final String clinicalDiag = note['clinical_diagnosis'] ?? '';
                final String prescription = note['prescription_notes'] ?? 'No recetado';
                final String followUp = note['follow_up_plan'] ?? 'No planificado';

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("Consulta: $dateFormatted", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                        ],
                      ),
                      pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                      pw.SizedBox(height: 4),
                      pw.RichText(
                        text: pw.TextSpan(
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                          children: [
                            pw.TextSpan(text: "Diagnóstico Clínico: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.TextSpan(text: clinicalDiag),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.RichText(
                        text: pw.TextSpan(
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                          children: [
                            pw.TextSpan(text: "Receta/Tratamiento: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.TextSpan(text: prescription),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.RichText(
                        text: pw.TextSpan(
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                          children: [
                            pw.TextSpan(text: "Plan Seguimiento: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.TextSpan(text: followUp),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          pw.SizedBox(height: 30),

          // ✍️ FIRMA MÉDICA Y CONSENTIMIENTO
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(width: 150, height: 1, color: PdfColors.grey700),
                pw.SizedBox(height: 4),
                pw.Text("Firma del Especialista", style: const pw.TextStyle(fontSize: 9)),
                pw.Text("Dermatólogo HealSkin", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ),
        ],
      ),
    );

    // 🚀 INVOCACIÓN NATIVA DE PREVISUALIZACIÓN Y DESCARGA
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Expediente_${fullName.replaceAll(' ', '_')}.pdf',
    );
  }
}
