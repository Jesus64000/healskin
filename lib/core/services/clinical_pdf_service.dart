import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ClinicalPdfService {
  /// Exporta únicamente la información y diagnósticos ingresados por el médico especialista,
  /// permitiendo seleccionar las notas/patologías deseadas (una, varias o todas).
  static Future<void> exportPatientHistory({
    required Map<String, dynamic> profile,
    required List<dynamic> selectedNotes,
  }) async {
    final pdf = pw.Document();

    final String fullName = profile['full_name'] ?? 'Paciente Desconocido';
    final String idCard = profile['identification_id'] ?? 'No registrada';
    final String skinType = (profile['skin_type']?.toString().toUpperCase() ?? 'NO DEFINIDO');
    final String age = profile['age']?.toString() ?? 'No registrada';
    final String gender = profile['gender'] ?? 'No especificado';
    final String allergies = profile['allergies'] ?? 'Ninguna';
    final String medicalHistory = profile['medical_history'] ?? 'Ninguno';

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
                    "REPORTE CLÍNICO MÉDICO",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#FF7A70'), // Color Secundario
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    "Fecha de emisión: ${DateFormat('dd/MM/yyyy - hh:mm a').format(DateTime.now())}",
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 1.5, color: PdfColor.fromHex('#4B39EF')),
          pw.SizedBox(height: 12),

          // 👤 FICHA DEMOGRÁFICA Y SALUD DEL PACIENTE
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
                  "1. DATOS DEL PACIENTE Y FICHA DE SALUD",
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Paciente: $fullName", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900)),
                          pw.SizedBox(height: 3),
                          pw.Text("Cédula / ID: $idCard", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                          pw.SizedBox(height: 3),
                          pw.Text("Tipo de Piel: $skinType", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Edad: $age", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                          pw.SizedBox(height: 3),
                          pw.Text("Género: $gender", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                          pw.SizedBox(height: 3),
                          pw.Text("Alergias: $allergies", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (medicalHistory != 'Ninguno' && medicalHistory.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text("Antecedentes Médicos: $medicalHistory", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // 📝 HISTORIAL DE DIAGNÓSTICOS E INDICACIONES MÉDICAS SELECCIONADAS
          pw.Text(
            "2. DIAGNÓSTICO E INDICACIONES DEL MÉDICO ESPECIALISTA",
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#4B39EF')),
          ),
          pw.SizedBox(height: 8),
          if (selectedNotes.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text("No se seleccionaron evaluaciones ni notas clínicas para incluir en este reporte.", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            )
          else
            pw.Column(
              children: selectedNotes.map((note) {
                final date = DateTime.parse(note['created_at']).toLocal();
                final dateFormatted = DateFormat('dd/MM/yyyy - hh:mm a').format(date);
                final String clinicalDiag = _cleanText(note['clinical_diagnosis'] ?? 'Sin diagnóstico especificado');
                final String prescription = _cleanText(note['prescription_notes'] ?? 'No recetado');
                final String followUp = _cleanText(note['follow_up_plan'] ?? 'No planificado');
                final String procedure = _cleanText(note['procedure'] ?? note['procedure_name'] ?? '');
                final String procedureFreq = _cleanText(note['procedure_frequency'] ?? '');

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(color: PdfColor.fromHex('#4B39EF'), width: 0.8),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("Consulta Médica: $dateFormatted", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#4B39EF'))),
                        ],
                      ),
                      pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                      pw.SizedBox(height: 4),
                      pw.RichText(
                        text: pw.TextSpan(
                          style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.black),
                          children: [
                            pw.TextSpan(text: "Diagnóstico Clínico: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.TextSpan(text: clinicalDiag),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.RichText(
                        text: pw.TextSpan(
                          style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.black),
                          children: [
                            pw.TextSpan(text: "Indicaciones / Receta Médica: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.TextSpan(text: prescription),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.RichText(
                        text: pw.TextSpan(
                          style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.black),
                          children: [
                            pw.TextSpan(text: "Plan de Seguimiento: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.TextSpan(text: followUp),
                          ],
                        ),
                      ),
                      if (procedure.isNotEmpty) ...[
                        pw.SizedBox(height: 6),
                        pw.RichText(
                          text: pw.TextSpan(
                            style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.black),
                            children: [
                              pw.TextSpan(text: "Procedimiento Prescrito: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.TextSpan(text: "$procedure ${procedureFreq.isNotEmpty ? '($procedureFreq)' : ''}"),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          pw.SizedBox(height: 35),

          // ✍️ FIRMA MÉDICA Y CONSENTIMIENTO
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(width: 160, height: 1, color: PdfColors.grey700),
                pw.SizedBox(height: 4),
                pw.Text("Firma y Sello del Especialista", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text("Dermatología Médica HealSkin", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ),
        ],
      ),
    );

    // 🚀 INVOCACIÓN NATIVA DE PREVISUALIZACIÓN Y DESCARGA
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_Clinico_${fullName.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Limpia asteriscos de markdown y caracteres no imprimibles para el PDF
  static String _cleanText(String text) {
    return text.replaceAll('**', '').replaceAll('*', '').replaceAll('☒', '-').replaceAll('📌', '').trim();
  }
}
