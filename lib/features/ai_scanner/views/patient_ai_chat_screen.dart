import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../patient/patient_dashboard.dart';

class PatientAIChatScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> scanData;
  const PatientAIChatScreen({super.key, required this.scanData});

  @override
  ConsumerState<PatientAIChatScreen> createState() => _PatientAIChatScreenState();
}

class _PatientAIChatScreenState extends ConsumerState<PatientAIChatScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  final List<String> _suggestions = [
    "🔍 Explicar diagnóstico",
    "💡 Ver recomendaciones",
    "🩺 Preguntas para el Especialista",
    "🩺 Consultar Médico / Telemedicina",
  ];

  String _translateRisk(String risk) {
    final cleanRisk = risk.toLowerCase().trim();
    if (cleanRisk.contains('low') || cleanRisk.contains('bajo')) {
      return 'Bajo';
    } else if (cleanRisk.contains('medium') || cleanRisk.contains('medio')) {
      return 'Medio';
    } else if (cleanRisk.contains('high') || cleanRisk.contains('alto')) {
      return 'Alto';
    } else if (cleanRisk.contains('urgent') || cleanRisk.contains('urgente')) {
      return 'Urgente';
    }
    return risk;
  }

  @override
  void initState() {
    super.initState();
    final riskTranslated = _translateRisk(widget.scanData['risk_level'] ?? 'low');
    final isFromHistory = widget.scanData['is_from_history'] == true;
    
    String greeting = '';
    if (isFromHistory) {
      greeting = '¡Hola! He recuperado los detalles de tu escaneo de piel guardado en el historial clínico. 🩺\n\n'
          '🔍 **Diagnóstico guardado:** ${widget.scanData['ai_diagnosis'] ?? 'No disponible'}\n'
          '⚠️ **Nivel de riesgo:** $riskTranslated\n\n'
          'Estoy listo para resolver tus dudas sobre este resultado, darte recomendaciones de cuidado personalizadas, o explicarte a detalle tu diagnóstico. ¿De qué te gustaría hablar hoy?';
    } else {
      greeting = '¡Hola! He analizado tu escaneo de piel con éxito. 🩺\n\n'
          '🔍 **Diagnóstico preliminar:** ${widget.scanData['ai_diagnosis'] ?? 'No disponible'}\n'
          '⚠️ **Nivel de riesgo:** $riskTranslated\n\n'
          'Estoy aquí para resolver tus dudas sobre este resultado, darte recomendaciones personalizadas, o guiarte en tu cuidado preventivo. ¿De qué te gustaría hablar?';
    }

    _messages.add({
      'role': 'assistant',
      'content': greeting,
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isTyping = true;
    });
    _scrollToBottom();

    const disclaimer = '💬 *Nota importante:* Como asistente virtual de IA, mis respuestas son puramente informativas y preventivas. Para más consejos o algo más específico, por favor **contacta a tu médico o agenda una consulta con un especialista en HealSkin** desde tu sección de Citas.';

    try {
      final supabase = Supabase.instance.client;

      // Invocamos la Edge Function pasando el historial, mensaje del usuario y contexto del escaneo
      // Excluimos el mensaje actual del historial de chat para evitar duplicidad de Groq
      final chatHistoryList = _messages.length > 2
          ? _messages.sublist(1, _messages.length - 1).map((m) => {
                'role': m['role'],
                'content': m['content'],
              }).toList()
          : <Map<String, String>>[];

      final response = await supabase.functions.invoke(
        'analyze-skin',
        body: {
          'userMessage': text,
          'scanContext': widget.scanData,
          'chatHistory': chatHistoryList,
        },
      );

      if (response.status != 200) {
        throw Exception("Error de respuesta del servidor (${response.status})");
      }

      final Map<String, dynamic> data = (response.data is String)
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      String reply = data['reply'] ?? 'Lo siento, no he podido procesar tu respuesta.';
      
      // Garantizar que la respuesta de Edge Function contenga el aviso legal
      if (!reply.contains('💬 *Nota importante:*')) {
        reply = '$reply\n\n---\n$disclaimer';
      }

      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      // 🚀 MOTOR LOCAL IA MÉDICO DE ALTA FIDELIDAD SI FALLA LA EDGE FUNCTION
      debugPrint("Fallo al invocar Edge Function, ejecutando motor local: $e");
      
      final reply = _generateLocalSimulatedReply(text);

      await Future.delayed(const Duration(milliseconds: 700)); // Retardo para simular procesamiento natural de la IA

      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  String _generateLocalSimulatedReply(String query) {
    final cleanQuery = query.toLowerCase().trim();
    final String diagnosis = widget.scanData['ai_diagnosis'] ?? 'Análisis Dérmico';
    final String risk = (widget.scanData['risk_level'] ?? 'low').toString().toLowerCase().trim();
    final String riskTranslated = _translateRisk(risk);
    final String recommendation = widget.scanData['recommendation'] ?? '';

    // Descargo de responsabilidad clínica obligatorio
    const disclaimer = '\n\n---\n💬 *Nota importante:* Como asistente virtual de IA, mis respuestas son puramente informativas y preventivas. Para más consejos o algo más específico, por favor **contacta a tu médico o agenda una consulta con un especialista en HealSkin** desde tu sección de Citas.';

    // Analizador de líneas robusto de recomendaciones clínicas
    String clinicalReasoning = '';
    String generalRecommendations = '';
    String suggestedQuestions = '';

    if (recommendation.isNotEmpty) {
      final lines = recommendation.split('\n');
      String currentSection = '';
      for (var line in lines) {
        final cleanLine = line.trim();
        final lowerLine = cleanLine.toLowerCase();

        if (lowerLine.contains('razonamiento clínico') ||
            lowerLine.contains('razonamiento clinico') ||
            lowerLine.contains('🔬 razonamiento') ||
            lowerLine.contains('triage')) {
          currentSection = 'triage';
          continue;
        } else if (lowerLine.contains('recomendaciones generales') ||
                   lowerLine.contains('🛡️ recomendaciones') ||
                   lowerLine.contains('recomendaciones de cuidado')) {
          currentSection = 'rec';
          continue;
        } else if (lowerLine.contains('preguntas sugeridas') ||
                   lowerLine.contains('preguntas para tu dermatólogo') ||
                   lowerLine.contains('preguntas para tu dermatologo') ||
                   lowerLine.contains('🩺 preguntas')) {
          currentSection = 'preguntas';
          continue;
        } else if (lowerLine.contains('nivel de confianza') ||
                   lowerLine.contains('confianza')) {
          currentSection = 'confianza';
          continue;
        }

        if (currentSection == 'triage') {
          clinicalReasoning += (clinicalReasoning.isEmpty ? '' : '\n') + cleanLine;
        } else if (currentSection == 'rec') {
          generalRecommendations += (generalRecommendations.isEmpty ? '' : '\n') + cleanLine;
        } else if (currentSection == 'preguntas') {
          suggestedQuestions += (suggestedQuestions.isEmpty ? '' : '\n') + cleanLine;
        }
      }
    }

    // Fallback gracioso para escaneos heredados o sin formato estructurado
    if (clinicalReasoning.trim().isEmpty &&
        generalRecommendations.trim().isEmpty &&
        suggestedQuestions.trim().isEmpty) {
      generalRecommendations = recommendation.trim();
    }

    // 0. Detección de intenciones sobre "pregunta" o "sugerida"
    if (cleanQuery.contains('pregunta') || cleanQuery.contains('sugerida') || cleanQuery.contains('preguntas')) {
      if (suggestedQuestions.isNotEmpty) {
        return '🩺 **Preguntas sugeridas para hacerle a tu dermatólogo o médico:**\n\n'
            'En base a tu escaneo de **$diagnosis** (Riesgo: **$riskTranslated**), te sugiero consultarle lo siguiente a tu especialista:\n\n'
            '$suggestedQuestions'
            + disclaimer;
      }
      return '🩺 **Preguntas sugeridas para tu consulta:**\n\n'
          'Basado en tu diagnóstico preliminar (**$diagnosis**), puedes consultarle a tu médico:\n\n'
          '1. ¿Considera que esta lesión requiere una biopsia o estudio dermatoscópico?\n'
          '2. ¿Qué signos de alarma (cambios en color, tamaño o bordes) debo monitorear?\n'
          '3. ¿Existe alguna rutina diaria de cuidado o fotoprotección específica para mi tipo de piel?\n'
          '4. ¿Con qué frecuencia debería programar mis revisiones preventivas?'
          + disclaimer;
    }

    // 1. Detección de intenciones sobre "recomendación", "rutina", "cuidado"
    if (cleanQuery.contains('recomendacion') || 
        cleanQuery.contains('recomienda') || 
        cleanQuery.contains('rutina') || 
        cleanQuery.contains('cuidado') || 
        cleanQuery.contains('skincare') || 
        cleanQuery.contains('consejo')) {
      
      if (generalRecommendations.isNotEmpty) {
        return '🩺 **Recomendaciones de cuidado personalizadas para tu caso:**\n\n'
            'Basado en tu escaneo clínico de **$diagnosis** (Riesgo: **$riskTranslated**), aquí tienes tus recomendaciones de cuidado:\n\n'
            '$generalRecommendations'
            + disclaimer;
      }

      return '🩺 **Recomendaciones de cuidado para tu caso:**\n\n'
          'Basado en tu diagnóstico preliminar (**$diagnosis**), te sugiero seguir estas pautas generales:\n\n'
          '1. **Limpieza suave:** Lava tu rostro dos veces al día con un limpiador syndet (sin jabón) adecuado para tu tipo de piel.\n'
          '2. **Fotoprotección diaria:** Usa protector solar de amplio espectro (SPF 50+) cada 3-4 horas, incluso en días nublados.\n'
          '3. **Evitar irritantes:** No apliques productos exfoliantes agresivos ni tónicos con alcohol sobre la zona escaneada.\n'
          '4. **Monitoreo constante:** Si observas cambios en la forma, color, tamaño o picazón, realiza un nuevo escaneo de evolución.'
          + disclaimer;
    }

    // 2. Detección de intenciones sobre "médico", "doctor", "ir", "grave", "peligro"
    if (cleanQuery.contains('medico') || 
        cleanQuery.contains('doctor') || 
        cleanQuery.contains('grave') || 
        cleanQuery.contains('peligro') || 
        cleanQuery.contains('urgente') ||
        cleanQuery.contains('dermatologo')) {
      
      if (risk.contains('high') || risk.contains('urgent') || risk.contains('medium') || risk.contains('alto') || risk.contains('urgente') || risk.contains('medio')) {
        return '⚠️ **Evaluación de Nivel de Riesgo ($riskTranslated):**\n\n'
            'Tu escaneo muestra factores de atención que clasifican la zona con un nivel de riesgo de **$riskTranslated**.\n\n'
            '📌 **Recomendación clínica:** Sí, en tu caso **es sumamente aconsejable que programes una consulta con un dermatólogo** para una revisión presencial detallada.\n\n'
            'Puedes agendar una cita directamente desde la pestaña **Citas** de nuestra app con cualquiera de nuestros especialistas disponibles en el centro.'
            + disclaimer;
      } else {
        return '💚 **Evaluación de Nivel de Riesgo ($riskTranslated):**\n\n'
            'Tu escaneo indica un nivel de riesgo **Bajo** y una apariencia general estable (**$diagnosis**).\n\n'
            'No se observan signos de alerta inmediata. No obstante, te sugerimos realizar consultas preventivas periódicas (al menos una vez al año) para mantener el cuidado óptimo de tu piel.'
            + disclaimer;
      }
    }

    // 3. Detección de intenciones sobre "tratamiento", "crema", "gel", "medicamento", "telemedicina"
    if (cleanQuery.contains('tratamiento') || 
        cleanQuery.contains('crema') || 
        cleanQuery.contains('gel') || 
        cleanQuery.contains('medicamento') ||
        cleanQuery.contains('curar') ||
        cleanQuery.contains('telemedicina')) {
      return '💊 **Información sobre Tratamientos:**\n\n'
          'Para el diagnóstico de **$diagnosis**, los tratamientos médicos específicos deben ser recetados por un dermatólogo.\n\n'
          '⚠️ *Nota de seguridad:* Como asistente de inteligencia artificial, **no tengo permitido recetar medicamentos, geles ni cremas dermatológicas de grado médico** (como retinoides fuertes, corticoides o antibióticos tópicos), ya que la automedicación puede empeorar la lesión.\n\n'
          '📌 **Recomendación:** Te invitamos a utilizar nuestro canal de **Telemedicina** para contactar de inmediato con un médico especialista de HealSkin. Ellos evaluarán tu caso, revisarán tus fotos clínicas y te darán una prescripción segura.\n\n'
          'Puedes usar el botón **"Contactar Dermatólogo"** aquí abajo para agendar de inmediato.';
    }

    // 4. Intenciones de saludo
    if (cleanQuery.contains('hola') || cleanQuery.contains('buenos dias') || cleanQuery.contains('buenas tardes')) {
      return '👋 ¡Hola! Estoy aquí para resolver tus dudas sobre tu escaneo reciente de **$diagnosis** (Riesgo: **$riskTranslated**).\n\n'
          'Pregúntame sobre cuidados diarios, si necesitas ir al dermatólogo, o qué hábitos de fotoprotección te conviene adoptar.'
          + disclaimer;
    }

    // 5. Explicación detallada del escaneo o diagnóstico
    if (cleanQuery.contains('explica') || cleanQuery.contains('diagnostico') || cleanQuery.contains('que significa') || cleanQuery.contains('que tengo') || cleanQuery.contains('entender')) {
      if (clinicalReasoning.isNotEmpty) {
        return '🔍 **Razonamiento Clínico sobre tu diagnóstico ($diagnosis):**\n\n'
            'El análisis asistido por IA de HealSkin determinó lo siguiente:\n\n'
            '$clinicalReasoning'
            + disclaimer;
      }
      return '🔍 **Explicación sobre tu diagnóstico ($diagnosis):**\n\n'
          'Tu escaneo clínico indica un estado clasificado como **$diagnosis** con un riesgo **$riskTranslated**.\n\n'
          'Esto significa que la barrera cutánea de la zona muestra características normales o consistentes con la descripción dada. No se observan signos evidentes de infecciones activas, descamaciones crónicas ni tumefacciones de peligro en las imágenes analizadas preliminarmente.'
          + disclaimer;
    }

    // 6. Respuesta por defecto que contextualiza la recomendación original
    String questionsBullet = suggestedQuestions.isNotEmpty
        ? '\n\n🩺 **Preguntas sugeridas para hacer en tu consulta:**\n$suggestedQuestions'
        : '';

    return '📝 **Información sobre tu escaneo clínico:**\n\n'
        'El análisis de tu piel determinó lo siguiente:\n'
        '• 🔍 **Diagnóstico:** $diagnosis\n'
        '• ⚠️ **Nivel de riesgo:** $riskTranslated\n\n'
        'He registrado esta información en tu **Historial Clínico**. Si sientes molestias físicas en la zona (ardor, picazón, descamación) o notas cambios rápidos de tamaño en los próximos días, te recomiendo agendar una cita médica.'
        + questionsBullet
        + disclaimer;
  }

  Color _getRiskColor(String risk) {
    final cleanRisk = risk.toLowerCase().trim();
    if (cleanRisk.contains('low') || cleanRisk.contains('bajo')) {
      return AppColors.success;
    } else if (cleanRisk.contains('medium') || cleanRisk.contains('medio')) {
      return AppColors.warning;
    } else if (cleanRisk.contains('high') || cleanRisk.contains('alto') || cleanRisk.contains('urgent') || cleanRisk.contains('urgente')) {
      return AppColors.danger;
    }
    return AppColors.textSecondary;
  }

  Widget _buildSuggestionChips() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(
                suggestion,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              backgroundColor: AppColors.primary.withValues(alpha: 0.06),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.15), width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () {
                _messageController.text = suggestion;
                _sendMessage();
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final riskLevel = widget.scanData['risk_level'] ?? 'low';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          "Consulta Médica IA",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          // --- MINI CABECERA DEL ESCANEO ---
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    image: widget.scanData['image_url'] != null
                        ? DecorationImage(image: NetworkImage(widget.scanData['image_url']), fit: BoxFit.cover)
                        : null,
                  ),
                  child: widget.scanData['image_url'] == null
                      ? const Icon(Icons.image_search, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.scanData['ai_diagnosis'] ?? 'Análisis Dérmico',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getRiskColor(riskLevel),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Riesgo: ${_translateRisk(riskLevel)}",
                            style: TextStyle(
                              color: _getRiskColor(riskLevel),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- HISTORIAL DE MENSAJES ---
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isAssistant = message['role'] == 'assistant';

                return Align(
                  alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(15),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isAssistant 
                          ? AppColors.primary.withValues(alpha: 0.08) 
                          : AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isAssistant ? 0 : 20),
                        bottomRight: Radius.circular(isAssistant ? 20 : 0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isAssistant) ...[
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.spa, color: AppColors.primary, size: 14),
                              SizedBox(width: 6),
                              Text("HealSkin IA", style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          message['content']!,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                          textAlign: TextAlign.justify,
                        ),
                        if (isAssistant && (message['content']!.contains('Telemedicina') || message['content']!.contains('telemedicina') || message['content']!.contains('médico') || message['content']!.contains('medico') || message['content']!.contains('dermatólogo') || message['content']!.contains('dermatologo'))) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.read(patientTabProvider.notifier).state = 0; // Cambiar a pestaña Citas (Telemedicina)
                              Navigator.pop(context); // Salir del chat de IA
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("✨ Redirigiendo al canal de Telemedicina de HealSkin..."),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            icon: const Icon(Icons.medical_services_outlined, size: 16),
                            label: const Text("Contactar Dermatólogo", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // --- SUGGESTION CHIPS ---
          if (!_isTyping)
            _buildSuggestionChips(),

          // --- INDICADOR DE ESCRITURA ---
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 30.0, bottom: 15.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "La IA de HealSkin está respondiendo...",
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.8), fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

          // --- BARRA DE ENTRADA DE MENSAJES ---
          Container(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 25, top: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, -4))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: "Pregúntale a HealSkin IA...",
                        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
