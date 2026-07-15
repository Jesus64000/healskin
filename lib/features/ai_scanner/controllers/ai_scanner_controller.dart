import 'dart:io';
import 'dart:async';
import 'dart:convert'; // 🚀 Necesario para codificar a Base64
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../auth/profile_provider.dart';
import '../../../core/services/notification_service.dart';

final aiScannerControllerProvider = AsyncNotifierProvider<AiScannerController, Map<String, dynamic>?>(
  AiScannerController.new,
);

class AiScannerController extends AsyncNotifier<Map<String, dynamic>?> {

  @override
  FutureOr<Map<String, dynamic>?> build() {
    return null;
  }

  Future<void> analyzeAndSave(File image) async {
    state = const AsyncLoading();

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) throw Exception("Sesión no encontrada. Por favor, inicia sesión de nuevo.");

      // --- FASE A: CODIFICACIÓN BASE64 ---
      final bytes = await image.readAsBytes();
      final String base64Image = base64Encode(bytes);

      // --- FASE B: INFERENCIA IA (SUPABASE EDGE FUNCTION) ---
      // 🚀 Llamamos al microservicio que creamos en el paso anterior
      final response = await supabase.functions.invoke(
        'analyze-skin',
        body: {'imageBase64': base64Image},
      );

      // Manejo de errores si la función falla o devuelve un JSON no válido
      if (response.status != 200) {
        throw Exception("Error del servidor: ${response.status}");
      }

      // Aseguramos decodificación robusta sea Map directo o String
      final Map<String, dynamic> data = (response.data is String) 
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      // 🧠 FILTRO DE CALIDAD INTELIGENTE: Calidad de la foto insuficiente o sin piel humana
      if (data['requires_better_photo'] == true) {
        final String failReason = data['recommendation'] ?? "La foto no es clara o no se detecta la piel correctamente.";
        throw Exception(failReason);
      }

      // Mapeamos los datos clínicos del triaje estructurado que programamos en Deno
      final String riskLevel = data['risk_level'] ?? 'medium';
      final String diagnosis = data['ai_diagnosis'] ?? 'Análisis completado';
      final String clinicalReasoning = data['clinical_reasoning'] ?? 'Análisis visual preliminar completado.';
      final int confidenceScore = data['confidence_score'] ?? 80;
      final List<dynamic> suggestedQuestionsList = data['suggested_questions'] ?? [];
      final String generalRec = data['recommendation'] ?? 'Mantener observación de la zona.';

      // Formateamos una recomendación de grado clínico enriquecida
      final String formattedQuestions = suggestedQuestionsList.isNotEmpty 
          ? suggestedQuestionsList.map((q) => "• $q").join("\n")
          : "• ¿Podría evaluar si este brote en mi piel requiere un tratamiento tópico específico?\n• ¿Con qué frecuencia me recomienda monitorear esta zona de mi rostro?\n• ¿Cuáles serían los signos de alarma por los que debería consultar de emergencia?";

      final String richRecommendation = 
          "🛡️ **NIVEL DE CONFIANZA IA:** $confidenceScore%\n\n"
          "🔬 **RAZONAMIENTO CLÍNICO (TRIAGE):**\n$clinicalReasoning\n\n"
          "💡 **RECOMENDACIONES GENERALES:**\n$generalRec\n\n"
          "🩺 **PREGUNTAS SUGERIDAS PARA TU DERMATÓLOGO:**\n$formattedQuestions";

      // --- FASE C: SUBIDA AL STORAGE (SUPABASE) ---
      final fileExtension = image.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$fileExtension';
      final storagePath = '${user.id}/$fileName';

      // ⚠️ Asegúrate de que el bucket 'scan_images' exista en tu panel de Supabase y sea Público
      await supabase.storage.from('scan_images').upload(storagePath, image);
      final publicImageUrl = supabase.storage.from('scan_images').getPublicUrl(storagePath);

      // --- FASE D: TRANSACCIÓN DE BASE DE DATOS ---
      await supabase.from('ai_scans').insert({
        'patient_id': user.id,
        'image_url': publicImageUrl,
        'ai_diagnosis': diagnosis,
        'risk_level': riskLevel,
        'recommendation': richRecommendation,
      });

      await supabase.from('skin_evolution').insert({
        'user_id': user.id,
        'title': 'Análisis IA: $diagnosis',
        'description': '$richRecommendation\n\n[risk_level: $riskLevel]',
        'event_type': (riskLevel == 'high' || riskLevel == 'urgent') ? 'warning' : 'info',
        'image_url': publicImageUrl,
      });

      // --- FASE E: EVALUACIÓN DE EVOLUCIÓN PARA NOTIFICACIÓN INSTANTÁNEA ---
      try {
        final evolutionEvents = await supabase
            .from('skin_evolution')
            .select('event_type')
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .limit(2);

        if (evolutionEvents.length >= 2) {
          final currentEvent = evolutionEvents[0];
          final previousEvent = evolutionEvents[1];

          final bool curWarning = currentEvent['event_type'] == 'warning';
          final bool prevWarning = previousEvent['event_type'] == 'warning';

          String notifTitle = "";
          String notifBody = "";

          if (curWarning && !prevWarning) {
            notifTitle = "⚠️ Alerta de Evolución Dérmica";
            notifBody = "Se ha detectado un cambio desfavorable en tu piel en comparación con tu análisis anterior. Te aconsejamos programar una consulta.";
          } else if (!curWarning && prevWarning) {
            notifTitle = "🎉 ¡Progreso en tu Piel!";
            notifBody = "Se observa una mejora notable en tu sintomatología con respecto al último análisis. ¡Continúa con tus cuidados!";
          }

          if (notifTitle.isNotEmpty) {
            await NotificationService().showInstantNotification(
              id: 2001,
              title: notifTitle,
              body: notifBody,
            );
          }
        }
      } catch (e) {
        // Capturar errores para no arruinar el flujo si la notificación falla
        print("⚠️ Error al evaluar evolución para notificación: $e");
      }

      ref.invalidate(skinTimelineProvider);
      
      final Map<String, dynamic> scanResult = {
        'risk_level': riskLevel,
        'ai_diagnosis': diagnosis,
        'recommendation': richRecommendation,
        'image_url': publicImageUrl,
      };

      state = AsyncData(scanResult);

    } on FunctionException catch (e) {
      // Capturamos errores específicos de las Edge Functions
      state = AsyncError("Error de la IA: ${e.details ?? e.reasonPhrase}", StackTrace.current);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }
}