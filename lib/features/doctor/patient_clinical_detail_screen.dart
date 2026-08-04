import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import 'telemedicine_room_screen.dart';
import 'doctor_agenda_view.dart';
import 'doctor_dashboard.dart';
import '../chat/chat_view.dart';
import '../patient/views/skin_comparator_view.dart';
import '../../core/services/clinical_pdf_service.dart';
import '../auth/profile_provider.dart';
import '../../core/utils/image_utils.dart';

// ============================================================================
// 🚀 CAPA DE DATOS: Provider del Expediente Clínico
// ============================================================================
final patientClinicalDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, patientId) async {
  final supabase = Supabase.instance.client;

  // 1. Datos del Perfil del Paciente
  final profile = await supabase
      .from('profiles')
      .select()
      .eq('id', patientId)
      .single();

  // 2. Escaneos de IA (Lo que le importa al dermatólogo)
  List<dynamic> scans = [];
  try {
    final scansResponse = await supabase
        .from('ai_scans')
        .select()
        .eq('patient_id', patientId);
    scans = List.from(scansResponse);
    scans.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
  } catch (e) {
    debugPrint("⚠️ Error al obtener escaneos de IA: $e");
  }

  // 3. Notas Médicas
  List<dynamic> notes = [];
  try {
    final notesResponse = await supabase
        .from('medical_notes')
        .select()
        .eq('patient_id', patientId);
    notes = List.from(notesResponse);
    notes.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
  } catch (e) {
    debugPrint("⚠️ Error al obtener notas médicas: $e");
  }

  // 4. CITAS: Traemos el historial de citas de este paciente específico
  List<dynamic> enrichedApts = [];
  try {
    final appointmentsResponse = await supabase
        .from('appointments')
        .select()
        .eq('patient_id', patientId)
        .order('appointment_date', ascending: false);

    for (final apt in appointmentsResponse) {
      try {
        final docProfile = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', apt['doctor_id'])
            .single();
        enrichedApts.add({
          ...apt,
          'doctor_name': docProfile['full_name'],
        });
      } catch (_) {
        enrichedApts.add(apt);
      }
    }
  } catch (e) {
    debugPrint("⚠️ Error al obtener citas: $e");
  }

  // 4.5. Procedimientos e Indicaciones Clínicas
  List<dynamic> procedures = [];
  try {
    final proceduresResponse = await supabase
        .from('patient_procedures')
        .select()
        .eq('patient_id', patientId);
    procedures = List.from(proceduresResponse);
    procedures.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
  } catch (e) {
    debugPrint("⚠️ Error al obtener procedimientos recetados: $e");
  }

  return {
    'profile': profile,
    'latestScan': scans.isNotEmpty ? scans.first : null,
    'scansHistory': scans,
    'notesHistory': notes,
    'appointmentsHistory': enrichedApts,
    'proceduresHistory': procedures,
  };
});

// ============================================================================
// 📱 CAPA DE PRESENTACIÓN (UI)
// ============================================================================
class PatientClinicalDetailScreen extends ConsumerWidget {
  final String patientId;
  final String? appointmentId;

  const PatientClinicalDetailScreen({
    super.key,
    required this.patientId,
    this.appointmentId,
  });

  // 🚀 LÓGICA DE NEGOCIO: Adaptado a TU tabla de base de datos
  void _showAddNoteModal(BuildContext context, WidgetRef ref, String doctorId) {
    final TextEditingController diagnosisController = TextEditingController();
    final TextEditingController prescriptionTopicalController = TextEditingController();
    final TextEditingController prescriptionOralController = TextEditingController();
    final TextEditingController followUpController = TextEditingController();
    
    // Controladores para el procedimiento integrado
    final TextEditingController procedureController = TextEditingController();
    final TextEditingController frequencyController = TextEditingController();
    final TextEditingController procedureInstructionsController = TextEditingController();
    bool prescribeProcedure = false;
    bool isSaving = false;
    String frequencyUnit = "días";

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setState) {
                return Padding(
                   padding: EdgeInsets.only(
                       bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                       left: 20, right: 20, top: 20
                   ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Nueva Nota Clínica", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 15),

                        // 1. Diagnóstico Clínico (Obligatorio)
                        const Text("Diagnóstico Clínico *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(
                          controller: diagnosisController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: "Ej. Dermatitis atópica leve...",
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 2. Receta Tópica (Opcional)
                        const Text("Receta Médica - Tratamiento Tópico", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(
                          controller: prescriptionTopicalController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: "Ej. Hidrocortisona 1% crema cada 12h, Limpiador facial...",
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Receta Vía Oral (Opcional)
                        const Text("Receta Médica - Tratamiento Vía Oral / Tomado", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(
                          controller: prescriptionOralController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: "Ej. Isotretinoína 20mg diario con el almuerzo, Antibiótico...",
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 3. Plan de seguimiento (Opcional)
                        const Text("Plan de Seguimiento", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(
                          controller: followUpController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: "Ej. Control en 15 días...",
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                        ),

                        // Checkbox para prescribir procedimiento de seguimiento integrado
                        const Divider(height: 25),
                        Row(
                          children: [
                            Checkbox(
                              value: prescribeProcedure,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  prescribeProcedure = val ?? false;
                                });
                              },
                            ),
                            const Expanded(
                              child: Text(
                                "Prescribir Procedimiento de Seguimiento",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),

                        if (prescribeProcedure) ...[
                          const SizedBox(height: 10),
                          const Text("Procedimiento *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 5),
                          TextField(
                            controller: procedureController,
                            decoration: InputDecoration(
                              hintText: "Ej. Limpieza Facial Profunda, Peeling, etc.",
                              filled: true,
                              fillColor: AppColors.surfaceLight,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text("Frecuencia de Cuidado *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: frequencyController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: "Ej. 2",
                                    filled: true,
                                    fillColor: AppColors.surfaceLight,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  initialValue: frequencyUnit,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.surfaceLight,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: "días", child: Text("Días")),
                                    DropdownMenuItem(value: "semanas", child: Text("Semanas")),
                                    DropdownMenuItem(value: "meses", child: Text("Meses")),
                                    DropdownMenuItem(value: "años", child: Text("Años")),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        frequencyUnit = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text("Indicaciones del Procedimiento", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 5),
                          TextField(
                            controller: procedureInstructionsController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: "Escribe recomendaciones, productos, cuidados...",
                              filled: true,
                              fillColor: AppColors.surfaceLight,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : () async {
                              if (diagnosisController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El diagnóstico es obligatorio"), backgroundColor: AppColors.danger));
                                return;
                              }

                              int? freq;
                              if (prescribeProcedure) {
                                if (procedureController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El nombre del procedimiento es obligatorio"), backgroundColor: AppColors.danger));
                                  return;
                                }
                                final qty = int.tryParse(frequencyController.text.trim());
                                if (qty == null || qty <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("La cantidad de frecuencia debe ser un número válido"), backgroundColor: AppColors.danger));
                                  return;
                                }
                                int multiplier = 1;
                                if (frequencyUnit == "semanas") {
                                  multiplier = 7;
                                } else if (frequencyUnit == "meses") {
                                  multiplier = 30;
                                } else if (frequencyUnit == "años") {
                                  multiplier = 365;
                                }
                                freq = qty * multiplier;
                              }

                              setState(() => isSaving = true);
                              try {
                                final cleanAppointmentId = (appointmentId == null || appointmentId == 'directory_view') ? null : appointmentId;

                                // Obtener nombre del doctor para el hito del timeline
                                String doctorName = 'Especialista';
                                try {
                                  final docProfile = await Supabase.instance.client
                                      .from('profiles')
                                      .select('full_name')
                                      .eq('id', doctorId)
                                      .single();
                                  doctorName = docProfile['full_name'] ?? 'Especialista';
                                } catch (e) {
                                  debugPrint("Error fetching doctor name for timeline: $e");
                                }

                                // Concatenar recetas
                                final String topicalText = prescriptionTopicalController.text.trim();
                                final String oralText = prescriptionOralController.text.trim();
                                String combinedPrescription = '';
                                if (topicalText.isNotEmpty || oralText.isNotEmpty) {
                                  combinedPrescription = "[Tópico]\n${topicalText.isEmpty ? 'Ninguno' : topicalText}\n\n[Vía Oral]\n${oralText.isEmpty ? 'Ninguno' : oralText}";
                                }

                                await Supabase.instance.client.from('medical_notes').insert({
                                  'appointment_id': cleanAppointmentId,
                                  'patient_id': patientId,
                                  'doctor_id': doctorId,
                                  'clinical_diagnosis': diagnosisController.text.trim(),
                                  'prescription_notes': combinedPrescription.isEmpty ? null : combinedPrescription,
                                  'follow_up_plan': followUpController.text.trim().isEmpty ? null : followUpController.text.trim(),
                                });

                                // Insertar hito médico en el timeline (skin_evolution)
                                try {
                                  await Supabase.instance.client.from('skin_evolution').insert({
                                    'user_id': patientId,
                                    'title': 'Diagnóstico Médico: ${diagnosisController.text.trim()}',
                                    'description': 'Confirmado por Dr/Dra. $doctorName. Receta e indicaciones registradas en tu historial.',
                                    'event_type': 'success',
                                    'image_url': null,
                                  });
                                } catch (timelineErr) {
                                  debugPrint("Error registering milestone in skin_evolution: $timelineErr");
                                }

                                if (prescribeProcedure) {
                                  await Supabase.instance.client.from('patient_procedures').insert({
                                    'patient_id': patientId,
                                    'doctor_id': doctorId,
                                    'procedure_name': procedureController.text.trim(),
                                    'frequency_days': freq,
                                    'instructions': procedureInstructionsController.text.trim().isEmpty ? null : procedureInstructionsController.text.trim(),
                                    'status': 'active',
                                  });
                                }

                                if (cleanAppointmentId != null) {
                                  await Supabase.instance.client
                                      .from('appointments')
                                      .update({
                                        'status': 'completed',
                                        'doctor_in_room': false,
                                      })
                                      .eq('id', cleanAppointmentId);
                                }

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ref.invalidate(patientClinicalDetailProvider(patientId));
                                  ref.invalidate(dailyAppointmentsProvider);
                                  ref.invalidate(todayAgendaPreviewProvider);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nota guardada exitosamente"), backgroundColor: AppColors.success));
                                }
                              } catch (e) {
                                setState(() => isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.danger));
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: isSaving
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Guardar Expediente", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }
          );
        }
    );
  }

  void _showAddProcedureModal(BuildContext context, WidgetRef ref, String doctorId) {
    final TextEditingController procedureController = TextEditingController();
    final TextEditingController frequencyController = TextEditingController();
    final TextEditingController instructionsController = TextEditingController();
    bool isSaving = false;
    String frequencyUnit = "días";

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setState) {
                return Padding(
                   padding: EdgeInsets.only(
                       bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                       left: 20, right: 20, top: 20
                   ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Recetar Nuevo Procedimiento", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 15),

                        // 1. Nombre del Procedimiento
                        const Text("Procedimiento *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(
                          controller: procedureController,
                          decoration: InputDecoration(
                            hintText: "Ej. Limpieza Facial Profunda, Peeling, etc.",
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // 2. Frecuencia de Cuidado
                        const Text("Frecuencia de Cuidado *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: frequencyController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "Ej. 2",
                                  filled: true,
                                  fillColor: AppColors.surfaceLight,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                initialValue: frequencyUnit,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surfaceLight,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: const [
                                  DropdownMenuItem(value: "días", child: Text("Días")),
                                  DropdownMenuItem(value: "semanas", child: Text("Semanas")),
                                  DropdownMenuItem(value: "meses", child: Text("Meses")),
                                  DropdownMenuItem(value: "años", child: Text("Años")),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      frequencyUnit = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // 3. Indicaciones / Instrucciones
                        const Text("Indicaciones y Cuidados Post-Tratamiento", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(
                          controller: instructionsController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Escribe las recomendaciones, productos a aplicar y precauciones...",
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : () async {
                              final name = procedureController.text.trim();
                              final freqStr = frequencyController.text.trim();
                              final inst = instructionsController.text.trim();

                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El nombre del procedimiento es obligatorio"), backgroundColor: AppColors.danger));
                                return;
                              }
                              final qty = int.tryParse(freqStr);
                              if (qty == null || qty <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("La cantidad de frecuencia debe ser un número válido"), backgroundColor: AppColors.danger));
                                return;
                              }
                              int multiplier = 1;
                              if (frequencyUnit == "semanas") {
                                multiplier = 7;
                              } else if (frequencyUnit == "meses") {
                                multiplier = 30;
                              } else if (frequencyUnit == "años") {
                                multiplier = 365;
                              }
                              final freq = qty * multiplier;

                              setState(() => isSaving = true);
                              try {
                                await Supabase.instance.client.from('patient_procedures').insert({
                                  'patient_id': patientId,
                                  'doctor_id': doctorId,
                                  'procedure_name': name,
                                  'frequency_days': freq,
                                  'instructions': inst.isEmpty ? null : inst,
                                  'status': 'active',
                                });

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ref.invalidate(patientClinicalDetailProvider(patientId));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Procedimiento recetado con éxito"), backgroundColor: AppColors.success));
                                }
                              } catch (e) {
                                setState(() => isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.danger));
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: isSaving
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Recetar Tratamiento", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }
          );
        }
    );
  }

  void _showEditNoteModal(BuildContext context, WidgetRef ref, Map<String, dynamic> note, String patientId) {
    final String rawPrescription = note['prescription_notes'] ?? '';
    String topical = '';
    String oral = '';
    if (rawPrescription.contains('[Tópico]') || rawPrescription.contains('[Vía Oral]')) {
      final RegExp topicalReg = RegExp(r'\[Tópico\]\n([\s\S]*?)(?=\n\n\[Vía Oral\]|$)');
      final RegExp oralReg = RegExp(r'\[Vía Oral\]\n([\s\S]*?)$');
      
      final topicalMatch = topicalReg.firstMatch(rawPrescription);
      final oralMatch = oralReg.firstMatch(rawPrescription);
      
      topical = (topicalMatch?.group(1) ?? '').trim();
      oral = (oralMatch?.group(1) ?? '').trim();
      if (topical == 'Ninguno') topical = '';
      if (oral == 'Ninguno') oral = '';
    } else {
      topical = rawPrescription;
    }

    final TextEditingController diagnosisController = TextEditingController(text: note['clinical_diagnosis']);
    final TextEditingController prescriptionTopicalController = TextEditingController(text: topical);
    final TextEditingController prescriptionOralController = TextEditingController(text: oral);
    final TextEditingController followUpController = TextEditingController(text: note['follow_up_plan']);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20, right: 20, top: 20
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Editar Nota Clínica", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 15),

                    const Text("Diagnóstico Clínico *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: diagnosisController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),

                    const Text("Receta Médica - Tratamiento Tópico", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: prescriptionTopicalController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),

                    const Text("Receta Médica - Tratamiento Vía Oral / Tomado", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: prescriptionOralController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),

                    const Text("Plan de Seguimiento", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: followUpController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () async {
                          if (diagnosisController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El diagnóstico es obligatorio"), backgroundColor: AppColors.danger));
                            return;
                          }

                          setState(() => isSaving = true);
                          try {
                            final String topicalText = prescriptionTopicalController.text.trim();
                            final String oralText = prescriptionOralController.text.trim();
                            String combinedPrescription = '';
                            if (topicalText.isNotEmpty || oralText.isNotEmpty) {
                              combinedPrescription = "[Tópico]\n${topicalText.isEmpty ? 'Ninguno' : topicalText}\n\n[Vía Oral]\n${oralText.isEmpty ? 'Ninguno' : oralText}";
                            }

                            await Supabase.instance.client.from('medical_notes').update({
                              'clinical_diagnosis': diagnosisController.text.trim(),
                              'prescription_notes': combinedPrescription.isEmpty ? null : combinedPrescription,
                              'follow_up_plan': followUpController.text.trim().isEmpty ? null : followUpController.text.trim(),
                            }).eq('id', note['id']);

                            if (context.mounted) {
                              Navigator.pop(context);
                              ref.invalidate(patientClinicalDetailProvider(patientId));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nota actualizada exitosamente"), backgroundColor: AppColors.success));
                            }
                          } catch (e) {
                            setState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.danger));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Guardar Cambios", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  void _confirmDeleteNote(BuildContext context, WidgetRef ref, String noteId, String patientId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¿Eliminar Nota?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("¿Estás seguro de que deseas eliminar esta nota clínica? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client.from('medical_notes').delete().eq('id', noteId);
                ref.invalidate(patientClinicalDetailProvider(patientId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nota eliminada exitosamente"), backgroundColor: AppColors.success));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al eliminar nota: $e"), backgroundColor: AppColors.danger));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Eliminar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditProcedureModal(BuildContext context, WidgetRef ref, Map<String, dynamic> proc, String patientId) {
    int initialDays = proc['frequency_days'] ?? 7;
    int initialQty = initialDays;
    String initialUnit = "días";
    if (initialDays % 365 == 0) {
      initialQty = initialDays ~/ 365;
      initialUnit = "años";
    } else if (initialDays % 30 == 0) {
      initialQty = initialDays ~/ 30;
      initialUnit = "meses";
    } else if (initialDays % 7 == 0) {
      initialQty = initialDays ~/ 7;
      initialUnit = "semanas";
    }

    final TextEditingController procedureController = TextEditingController(text: proc['procedure_name']);
    final TextEditingController frequencyController = TextEditingController(text: initialQty.toString());
    final TextEditingController instructionsController = TextEditingController(text: proc['instructions']);
    String frequencyUnit = initialUnit;
    bool isSaving = false;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setState) {
                return Padding(
                   padding: EdgeInsets.only(
                       bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                       left: 20, right: 20, top: 20
                   ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Editar Tratamiento / Procedimiento", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 15),

                        const Text("Procedimiento *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(
                          controller: procedureController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 15),

                        const Text("Frecuencia de Cuidado *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: frequencyController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surfaceLight,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                initialValue: frequencyUnit,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surfaceLight,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: const [
                                  DropdownMenuItem(value: "días", child: Text("Días")),
                                  DropdownMenuItem(value: "semanas", child: Text("Semanas")),
                                  DropdownMenuItem(value: "meses", child: Text("Meses")),
                                  DropdownMenuItem(value: "años", child: Text("Años")),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      frequencyUnit = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        const Text("Indicaciones y Cuidados Post-Tratamiento", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 5),
                        TextField(
                          controller: instructionsController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : () async {
                              final name = procedureController.text.trim();
                              final freqStr = frequencyController.text.trim();
                              final inst = instructionsController.text.trim();

                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El nombre del procedimiento es obligatorio"), backgroundColor: AppColors.danger));
                                return;
                              }
                              final qty = int.tryParse(freqStr);
                              if (qty == null || qty <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("La cantidad de frecuencia debe ser un número válido"), backgroundColor: AppColors.danger));
                                return;
                              }
                              int multiplier = 1;
                              if (frequencyUnit == "semanas") {
                                multiplier = 7;
                              } else if (frequencyUnit == "meses") {
                                multiplier = 30;
                              } else if (frequencyUnit == "años") {
                                multiplier = 365;
                              }
                              final freq = qty * multiplier;

                              setState(() => isSaving = true);
                              try {
                                await Supabase.instance.client.from('patient_procedures').update({
                                  'procedure_name': name,
                                  'frequency_days': freq,
                                  'instructions': inst.isEmpty ? null : inst,
                                }).eq('id', proc['id']);

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ref.invalidate(patientClinicalDetailProvider(patientId));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tratamiento actualizado exitosamente"), backgroundColor: AppColors.success));
                                }
                              } catch (e) {
                                setState(() => isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.danger));
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: isSaving
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Guardar Cambios", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }
          );
        }
    );
  }

  void _confirmDeleteProcedure(BuildContext context, WidgetRef ref, String procId, String patientId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¿Eliminar Tratamiento?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("¿Estás seguro de que deseas eliminar este tratamiento? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client.from('patient_procedures').delete().eq('id', procId);
                ref.invalidate(patientClinicalDetailProvider(patientId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tratamiento eliminado exitosamente"), backgroundColor: AppColors.success));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al eliminar tratamiento: $e"), backgroundColor: AppColors.danger));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Eliminar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientDataAsync = ref.watch(patientClinicalDetailProvider(patientId));
    final currentDoctorId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final bool hasValidAppointment = appointmentId != null && appointmentId != 'directory_view';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text("Expediente Clínico", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary, size: 26),
            tooltip: "Exportar Reporte Médico (PDF)",
            onPressed: () async {
              final data = patientDataAsync.value;
              if (data == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Espere a que carguen los datos del paciente..."),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }

              final profile = data['profile'];
              final notesHistory = data['notesHistory'] as List<dynamic>? ?? [];

              if (notesHistory.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("El paciente no cuenta con evaluaciones médicas registradas para exportar."),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }

              _showPdfNoteSelectionDialog(context, profile, notesHistory);
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_outlined, color: AppColors.primary, size: 26),
            tooltip: "Chat con Paciente",
            onPressed: () {
              final profile = patientDataAsync.value?['profile'];
              final String fullName = profile?['full_name'] ?? 'Paciente';

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatView(
                    otherUserId: patientId,
                    otherUserName: fullName,
                  ),
                ),
              );
            },
          ),
          if (hasValidAppointment)
            IconButton(
              icon: const Icon(Icons.videocam_outlined, color: AppColors.secondary, size: 28),
              onPressed: () {
                final profile = patientDataAsync.value?['profile'];
                final String fullName = profile?['full_name'] ?? 'Paciente';

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TelemedicineRoomScreen(
                      patientId: patientId,
                      patientName: fullName,
                      appointmentId: appointmentId!,
                      isDoctor: true,
                    ),
                  ),
                );
              },
            )
        ],
      ),
      body: patientDataAsync.when(
        data: (data) {
          final profile = data['profile'];
          final latestScan = data['latestScan'];
          final scansHistory = data['scansHistory'] as List<dynamic>;
          final notesHistory = data['notesHistory'] as List<dynamic>;
          final appointmentsHistory = data['appointmentsHistory'] as List<dynamic>;
          final proceduresHistory = data['proceduresHistory'] as List<dynamic>? ?? [];

          final String fullName = profile['full_name'] ?? 'Paciente Desconocido';
          final String avatarInitials = fullName.trim().split(' ').take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join();

          final bool hasScan = latestScan != null;
          final String rawLatestRisk = hasScan ? (latestScan['risk_level'] ?? 'low').toString().toLowerCase().trim() : 'low';
          final bool isUrgent = hasScan && (rawLatestRisk.contains('high') || rawLatestRisk.contains('urgent') || rawLatestRisk.contains('alto') || rawLatestRisk.contains('urgente'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TARJETA DE RESUMEN DEL PACIENTE
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
                    border: Border.all(color: isUrgent ? AppColors.danger.withValues(alpha: 0.3) : Colors.transparent, width: 2),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: isUrgent ? AppColors.danger.withValues(alpha: 0.1) : AppColors.surfaceDark,
                        backgroundImage: profile['avatar_url'] != null && profile['avatar_url'].toString().trim().isNotEmpty
                            ? NetworkImage(profile['avatar_url'].toString())
                            : null,
                        child: profile['avatar_url'] != null && profile['avatar_url'].toString().trim().isNotEmpty
                            ? null
                            : Text(avatarInitials.isEmpty ? 'P' : avatarInitials,
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isUrgent ? AppColors.danger : AppColors.primary)),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                if (isUrgent) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                    child: const Text("URGENTE", style: TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Text(
                                  "Piel: ${profile['skin_type']?.toString().toUpperCase() ?? 'No definido'}",
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // 1.5. TARJETA DE INFORMACIÓN DEMOGRÁFICA Y CLÍNICA (NUEVO) 🚀
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.assignment_ind_outlined, color: AppColors.primary, size: 22),
                          SizedBox(width: 10),
                          Text("Ficha Demográfica", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                      const Divider(height: 25),
                      _buildInfoRow(Icons.badge_outlined, "Cédula / ID", profile['identification_id'] ?? 'No registrada'),
                      _buildInfoRow(Icons.cake_outlined, "Edad", profile['age']?.toString() ?? 'No registrada'),
                      _buildInfoRow(Icons.face_outlined, "Género", profile['gender'] ?? 'No especificado'),
                      _buildInfoRow(Icons.spa_outlined, "Tipo de Piel", (profile['skin_type']?.toString().toUpperCase() ?? 'NO DEFINIDO')),
                      _buildInfoRow(Icons.wb_sunny_outlined, "Brillo Facial", profile['glow_frequency'] ?? 'No respondido'),
                      _buildInfoRow(Icons.bug_report_outlined, "Propensión al Acné", profile['has_acne'] ?? 'No respondido'),
                      _buildInfoRow(Icons.warning_amber_rounded, "Alergias", profile['allergies'] ?? 'Ninguna especificada'),
                      _buildInfoRow(Icons.history_edu_outlined, "Antecedentes Médicos", profile['medical_history'] ?? 'Ninguno especificado'),
                      _buildInfoRow(Icons.history_outlined, "Tratamientos Previos", profile['treatments_past'] ?? 'Ninguno especificado'),
                      _buildInfoRow(Icons.medical_services_outlined, "Tratamientos Actuales", profile['treatments_current'] ?? 'Ninguno especificado'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. SECCIÓN: ACCIONES MÉDICAS
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showAddNoteModal(context, ref, currentDoctorId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.note_add_outlined, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Añadir Nota",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showAddProcedureModal(context, ref, currentDoctorId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.medical_services_outlined, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Tratamiento",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // 3. SECCIÓN: DIAGNÓSTICO IA
                const Text("Último Análisis de IA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 15),

                if (hasScan)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.biotech_outlined, color: isUrgent ? AppColors.danger : AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(latestScan['ai_diagnosis'] ?? 'Análisis completado',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: isUrgent ? AppColors.danger : AppColors.primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        if (latestScan['image_url'] != null)
                          GestureDetector(
                            onTap: () => showFullScreenImage(context, latestScan['image_url']),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                latestScan['image_url'],
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 100,
                                  color: Colors.grey[300],
                                  child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 15),
                        Text(
                          latestScan['recommendation'] ?? 'Sin recomendaciones adicionales.',
                          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(15)),
                    child: const Center(child: Text("El paciente aún no ha realizado escaneos.", style: TextStyle(color: AppColors.textSecondary))),
                  ),

                if (scansHistory.length >= 2) ...[
                  const SizedBox(height: 25),
                  _buildComparatorBanner(context, scansHistory),
                ],

                // 3.6. HISTORIAL COMPLETO DE ESCANEOS DE IA (NUEVO) 🚀
                if (scansHistory.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  const Text("Historial de Escaneos IA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 15),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: scansHistory.length,
                    itemBuilder: (context, index) {
                      final scan = scansHistory[index];
                      final date = DateTime.parse(scan['created_at']).toLocal();
                      final dateFormatted = DateFormat('dd MMM, yyyy - hh:mm a', 'es').format(date);
                       final String rawRisk = (scan['risk_level'] ?? 'low').toString().toLowerCase().trim();
                      String riskLabel = 'Bajo';
                      Color riskColor = AppColors.success;
                      if (rawRisk.contains('medium') || rawRisk.contains('medio')) {
                        riskLabel = 'Medio';
                        riskColor = AppColors.warning;
                      } else if (rawRisk.contains('high') || rawRisk.contains('alto')) {
                        riskLabel = 'Alto';
                        riskColor = AppColors.danger;
                      } else if (rawRisk.contains('urgent') || rawRisk.contains('urgente')) {
                        riskLabel = 'Urgente';
                        riskColor = AppColors.danger;
                      }

                      return InkWell(
                        onTap: () => _showScanDetailsDialog(context, scan),
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 5)],
                          ),
                          child: Row(
                            children: [
                              if (scan['image_url'] != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    scan['image_url'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40),
                                  ),
                                )
                              else
                                const Icon(Icons.biotech, size: 40, color: AppColors.primary),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      scan['ai_diagnosis'] ?? 'Análisis de IA',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(dateFormatted, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: riskColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  riskLabel,
                                  style: TextStyle(color: riskColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],

                // 3.8. SECCIÓN: HISTORIAL DE CITAS (NUEVO) 🚀
                const SizedBox(height: 30),
                const Text("Historial de Citas Médicas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 15),

                if (appointmentsHistory.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                    ),
                    child: const Center(child: Text("El paciente no registra citas agendadas.", style: TextStyle(color: AppColors.textSecondary))),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: appointmentsHistory.length,
                    itemBuilder: (context, index) {
                      final apt = appointmentsHistory[index];
                      final date = DateTime.parse(apt['appointment_date']).toLocal();
                      final dateFormatted = DateFormat('dd MMM, yyyy - hh:mm a', 'es').format(date);
                      final String rawStatus = (apt['status'] ?? 'scheduled').toString().toUpperCase();
                      final Color statusColor = rawStatus == 'COMPLETED' 
                          ? AppColors.success 
                          : (rawStatus == 'CANCELLED' ? AppColors.danger : AppColors.secondary);
                      final String statusLabel = rawStatus == 'COMPLETED'
                          ? 'COMPLETADA'
                          : (rawStatus == 'CANCELLED' ? 'CANCELADA' : 'PROGRAMADA');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateFormatted,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  "Médico: Dr/Dra. ${apt['doctor_name'] ?? 'No especificado'}",
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                            if (apt['reason'] != null && apt['reason'].toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Motivo: ${apt['reason']}",
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 30),

                // 3.9. SECCIÓN: PROCEDIMIENTOS DE SEGUIMIENTO (NUEVO) 🚀
                const Text("Procedimientos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 15),

                if (proceduresHistory.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                    ),
                    child: const Center(child: Text("El paciente no tiene procedimientos registrados.", style: TextStyle(color: AppColors.textSecondary))),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: proceduresHistory.length,
                    itemBuilder: (context, index) {
                      final proc = proceduresHistory[index];
                      final date = DateTime.parse(proc['created_at']).toLocal();
                      final dateFormatted = DateFormat('dd MMM, yyyy - hh:mm a', 'es').format(date);
                      final String status = (proc['status'] ?? 'active').toString().toUpperCase();
                      final Color statusColor = status == 'ACTIVE' ? AppColors.success : Colors.grey;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    proc['procedure_name'] ?? 'Procedimiento',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _showEditProcedureModal(context, ref, proc, patientId),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _confirmDeleteProcedure(context, ref, proc['id'], patientId),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status == 'ACTIVE' ? 'ACTIVO' : 'COMPLETADO',
                                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  "Recetado: $dateFormatted",
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.repeat_on_outlined, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  formatFrequencyDays(proc['frequency_days'] ?? 0),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            if (proc['instructions'] != null && proc['instructions'].toString().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Text("Instrucciones del médico:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                proc['instructions'],
                                style: const TextStyle(color: AppColors.textPrimary, height: 1.3, fontSize: 12),
                              ),
                            ],
                            if (status == 'ACTIVE') ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    try {
                                      await Supabase.instance.client
                                          .from('patient_procedures')
                                          .update({'status': 'completed'})
                                          .eq('id', proc['id']);
                                      ref.invalidate(patientClinicalDetailProvider(patientId));
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Tratamiento marcado como completado"), backgroundColor: AppColors.success)
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.danger)
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                                  label: const Text("Dar de baja / Completar", style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              )
                            ]
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 30),

                // 4. HISTORIAL DE NOTAS CLÍNICAS (Adaptado a tu tabla)
                const Text("Historial Clínico (Notas)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 15),

                if (notesHistory.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                    ),
                    child: const Center(child: Text("No hay notas clínicas registradas.", style: TextStyle(color: AppColors.textSecondary))),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: notesHistory.length,
                    itemBuilder: (context, index) {
                      final note = notesHistory[index];
                      final date = DateTime.parse(note['created_at']).toLocal();
                      final dateFormatted = DateFormat('dd MMM, yyyy - hh:mm a', 'es').format(date);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.history_edu, color: AppColors.secondary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(dateFormatted, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _showEditNoteModal(context, ref, note, patientId),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _confirmDeleteNote(context, ref, note['id'], patientId),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 15),

                            // Diagnóstico
                            const Text("Diagnóstico:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(note['clinical_diagnosis'] ?? '', style: const TextStyle(color: AppColors.textPrimary, height: 1.3)),

                            // Receta (Si existe)
                            if (note['prescription_notes'] != null && note['prescription_notes'].toString().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Text("Receta:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(note['prescription_notes'], style: const TextStyle(color: AppColors.textPrimary, height: 1.3)),
                            ],

                            // Plan de seguimiento (Si existe)
                            if (note['follow_up_plan'] != null && note['follow_up_plan'].toString().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Text("Plan de seguimiento:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(note['follow_up_plan'], style: const TextStyle(color: AppColors.textPrimary, height: 1.3)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text("Error al cargar expediente: $err", style: const TextStyle(color: AppColors.danger))),
      ),
    );
  }

  Widget _buildComparatorBanner(BuildContext context, List<dynamic> scans) {
    final list = List<Map<String, dynamic>>.from(scans);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "✨ Comparador de Lesiones",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Contraste visualmente dos fotos históricas de la piel del paciente en un comparador deslizable táctil.",
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SkinComparatorSelectionScreen(
                          items: list,
                          title: "Comparar Lesiones",
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text("Comparar Fotos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                )
              ],
            ),
          ),
          const SizedBox(width: 15),
          const Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 45),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 12),
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showScanDetailsDialog(BuildContext context, Map<String, dynamic> scan) {
    final date = DateTime.parse(scan['created_at']).toLocal();
    final dateFormatted = DateFormat('dd MMM, yyyy - hh:mm a', 'es').format(date);
    final String rawRisk = (scan['risk_level'] ?? 'low').toString().toLowerCase().trim();
    String riskLabel = 'Bajo';
    Color riskColor = AppColors.success;
    if (rawRisk.contains('medium') || rawRisk.contains('medio')) {
      riskLabel = 'Medio';
      riskColor = AppColors.warning;
    } else if (rawRisk.contains('high') || rawRisk.contains('alto')) {
      riskLabel = 'Alto';
      riskColor = AppColors.danger;
    } else if (rawRisk.contains('urgent') || rawRisk.contains('urgente')) {
      riskLabel = 'Urgente';
      riskColor = AppColors.danger;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        clipBehavior: Clip.hardEdge,
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (scan['image_url'] != null)
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () => showFullScreenImage(context, scan['image_url']),
                        child: Image.network(
                          scan['image_url'],
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 15,
                        right: 15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: riskColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)
                            ],
                          ),
                          child: Text(
                            "Riesgo: $riskLabel",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    height: 120,
                    color: AppColors.surfaceLight,
                    child: const Center(
                      child: Icon(Icons.biotech, size: 60, color: AppColors.primary),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scan['ai_diagnosis'] ?? 'Análisis de IA',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Realizado: $dateFormatted",
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const Divider(height: 25, thickness: 1.2),
                      const Text(
                        "Informe y Recomendaciones Clínicas:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        scan['recommendation'] ?? 'Sin recomendaciones detalladas.',
                        style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPdfNoteSelectionDialog(BuildContext context, Map<String, dynamic> profile, List<dynamic> notes) {
    List<dynamic> selectedNotes = List.from(notes); // Por defecto todas seleccionadas

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allSelected = selectedNotes.length == notes.length;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.picture_as_pdf, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Seleccionar Diagnósticos para PDF",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Selecciona las patologías / evaluaciones médicas que deseas incluir en el reporte:",
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Seleccionar Todas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      value: allSelected,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setModalState(() {
                          if (val == true) {
                            selectedNotes = List.from(notes);
                          } else {
                            selectedNotes.clear();
                          }
                        });
                      },
                    ),
                    const Divider(),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: notes.map((note) {
                            final isChecked = selectedNotes.contains(note);
                            final diag = note['clinical_diagnosis'] ?? 'Sin diagnóstico';
                            final dateStr = note['created_at'] != null ? note['created_at'].toString() : '';
                            String dateFormatted = '';
                            if (dateStr.isNotEmpty) {
                              try {
                                final date = DateTime.parse(dateStr).toLocal();
                                dateFormatted = DateFormat('dd/MM/yyyy - hh:mm a').format(date);
                              } catch (_) {}
                            }

                            return CheckboxListTile(
                              dense: true,
                              activeColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                diag,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              subtitle: dateFormatted.isNotEmpty
                                  ? Text("Fecha: $dateFormatted", style: const TextStyle(fontSize: 11))
                                  : null,
                              value: isChecked,
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    selectedNotes.add(note);
                                  } else {
                                    selectedNotes.remove(note);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancelar", style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, size: 18, color: Colors.white),
                  label: const Text("Generar PDF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: selectedNotes.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          try {
                            await ClinicalPdfService.exportPatientHistory(
                              profile: profile,
                              selectedNotes: selectedNotes,
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error al generar PDF: $e"),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }
}