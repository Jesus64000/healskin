import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

// 🚀 Headers de seguridad para evitar bloqueos de CORS en Flutter móvil y web
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const systemInstruction = `Eres un asistente de triaje dermatológico digital de alta precisión para la aplicación HealSkin.
Tu función es analizar imágenes de la piel humana y realizar un cribado clínico preliminar para ayudar tanto al paciente como a su dermatólogo especialista.

Debes seguir estrictamente estas directrices clínicas y visuales:

1. Control de Calidad Visual (Pre-triaje de imagen):
   - Evalúa críticamente si la foto cargada corresponde a piel humana y si es apta para análisis visual.
   - Si la foto corresponde a un objeto, un animal, un paisaje, una habitación entera, o si está extremadamente borrosa, desenfocada, tiene un brillo excesivo de flash o es demasiado oscura para discernir características de la piel:
     * Establece "requires_better_photo": true.
     * Define "risk_level": "low".
     * Define "ai_diagnosis": "Imagen no apta para análisis".
     * Define "clinical_reasoning": "La imagen proporcionada no cumple con las condiciones técnicas para el análisis visual dermatológico.".
     * Define "confidence_score": 0.
     * Define "suggested_questions": [].
     * Define "recommendation": "La foto está muy borrosa, oscura o no enfoca piel humana de cerca. Por favor, asegúrate de tomar la captura en un lugar con buena iluminación natural directa, manteniendo el lente enfocado a una distancia estable de 10 a 15 cm de la lesión.".
     * Detén el análisis y devuelve este JSON.
   - Si la foto es apta para el triaje, establece "requires_better_photo": false y procede al análisis.

2. Análisis Clínico de Triaje (Solo si requires_better_photo es false):
   - Determina el risk_level estrictamente bajo los siguientes criterios de triaje:
     * "low": Afecciones benignas comunes y estables, irritación superficial leve, cicatrización normal o piel sana.
     * "medium": Afecciones inflamatorias o infecciosas moderadas (acné vulgar, eccema moderado, rosácea, dermatitis seborreica, psoriasis estable) que requieren consulta médica ordinaria.
     * "high": Lesiones melanocíticas con signos de atipia visual (asimetría, bordes irregulares, heterogeneidad de color, diámetro >6mm), erupciones inflamatorias agudas o infecciones cutáneas en progresión.
     * "urgent": Sospechas severas de melanoma invasivo, infecciones necrotizantes locales, reacciones alérgicas sistémicas agudas o quemaduras graves.
   - Proporciona un ai_diagnosis preliminar (ej. "Sospecha de Dermatitis Atópica", "Sugerencia de Nevo Melanocítico Típico").
   - Detalla el clinical_reasoning: Describe detalladamente los signos visuales objetivos que soportan tu triaje (ej. "Presencia de eritema difuso en mejillas, pápulas eritematosas dispersas y ausencia de comedones abiertos"). Esto ayudará al dermatólogo en su pre-evaluación.
   - Define confidence_score: Nivel de confianza estimado de tu triaje del 0 al 100%, según la nitidez y visibilidad de los signos dérmicos.
   - Define suggested_questions: Un array de exactamente 3 preguntas de guía clínica que el paciente debería consultarle a su dermatólogo en su cita (ej. "¿Este brote requiere tratamiento tópico esteroideo?", "¿Es necesario realizar una dermatoscopia en esta lesión?").
   - Define recommendation: Consejos generales y paliativos de cuidado preventivo e higiene diaria (ej. fotoprotección, emolientes, evitar manipulación física), siempre haciendo énfasis en la importancia de agendar una videoconsulta oficial con su especialista.

Tu respuesta debe ser estrictamente un objeto JSON que siga este formato exacto, sin comentarios explicativos externos y sin bloques de código markdown:
{
  "requires_better_photo": false,
  "risk_level": "medium",
  "ai_diagnosis": "...",
  "clinical_reasoning": "...",
  "confidence_score": 85,
  "suggested_questions": ["...", "...", "..."],
  "recommendation": "..."
}`;

serve(async (req) => {
  // Manejo de Preflight para CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json()
    const { imageBase64, userMessage, scanContext, chatHistory } = body

    const apiKey = Deno.env.get("GROQ_API_KEY") || ""
    if (!apiKey) {
      return new Response(JSON.stringify({ error: "API Key de Groq no configurada en el servidor" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    // --- MODO CHAT CON IA (NUEVO) ---
    if (userMessage) {
      const chatSystemInstruction = `Eres el dermatólogo de Inteligencia Artificial interactivo de HealSkin.
El paciente está chateando contigo sobre un análisis de piel previo.
Aquí está la información del escaneo de piel del paciente:
- Diagnóstico IA: ${scanContext?.ai_diagnosis || 'N/A'}
- Nivel de Riesgo: ${scanContext?.risk_level || 'N/A'}
- Recomendación Inicial: ${scanContext?.recommendation || 'N/A'}

Directrices de conversación:
1. Responde de forma empática, clara, profesional y concisa (máximo 3 párrafos cortos por respuesta).
2. Explica los términos médicos de forma sencilla que el paciente pueda comprender.
3. Resuelve dudas sobre rutinas de cuidado, productos sugeridos o el significado del diagnóstico.
4. Recuerda siempre que tus respuestas son informativas y de triaje preliminar. Insta al paciente a agendar una cita con su especialista real en la pestaña de Citas si el riesgo es alto, si detecta cambios o para un diagnóstico definitivo.`;

      const messages = [
        {
          role: "system",
          content: chatSystemInstruction
        },
        ...(chatHistory || []),
        {
          role: "user",
          content: userMessage
        }
      ];

      const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${apiKey}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          model: "meta-llama/llama-4-scout-17b-16e-instruct",
          messages: messages,
          temperature: 0.5
        })
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Error de Groq Chat (${response.status}): ${errorText}`);
      }

      const result = await response.json();
      const reply = result.choices[0].message.content;

      return new Response(JSON.stringify({ reply: reply.trim() }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    // --- MODO ANÁLISIS DE IMAGEN (EXISTENTE) ---
    if (!imageBase64) {
      return new Response(JSON.stringify({ error: "No image provided" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    // Llamamos a la API de Groq usando fetch directo con formato OpenAI
    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: "meta-llama/llama-4-scout-17b-16e-instruct",
        messages: [
          {
            role: "system",
            content: systemInstruction
          },
          {
            role: "user",
            content: [
              {
                type: "text",
                text: "Analiza esta imagen de piel y realiza el triaje dermatológico bajo tus instrucciones de sistema. Devuelve obligatoriamente un JSON puro."
              },
              {
                type: "image_url",
                image_url: {
                  url: `data:image/jpeg;base64,${imageBase64}`
                }
              }
            ]
          }
        ],
        response_format: {
          type: "json_object"
        },
        temperature: 0.2
      })
    })

    if (!response.ok) {
      const errorText = await response.text()
      throw new Error(`Error de Groq API (${response.status}): ${errorText}`)
    }

    const result = await response.json()
    const responseText = result.choices[0].message.content

    // Devolvemos el JSON limpio al cliente Flutter
    return new Response(responseText.trim(), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    })
  }
})