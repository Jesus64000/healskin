import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { RtcTokenBuilder, RtcRole } from "https://esm.sh/agora-token@2.0.5"

// 🚀 Headers de seguridad para evitar bloqueos de CORS en Flutter móvil y web
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Manejo de Preflight para CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { channelName, uid } = await req.json()

    if (!channelName) {
      return new Response(JSON.stringify({ error: "Missing required parameter: channelName" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    // Leemos de forma segura las credenciales de Agora en el backend
    const appId = Deno.env.get("AGORA_APP_ID") || ""
    const appCertificate = Deno.env.get("AGORA_APP_CERTIFICATE") || ""

    if (!appId || !appCertificate) {
      return new Response(
        JSON.stringify({ 
          error: "Error del servidor: Las credenciales de Agora no están configuradas en Supabase (AGORA_APP_ID o AGORA_APP_CERTIFICATE)" 
        }), 
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        }
      )
    }

    // El UID de la llamada. Si no se pasa o es 0, usamos 0 (Agora le asignará un ID dinámico)
    const agoraUid = uid !== undefined ? Number(uid) : 0

    // Tiempo de expiración del token (1 hora)
    const expirationTimeInSeconds = 3600
    const currentTimestamp = Math.floor(Date.now() / 1000)
    const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds

    // Generamos el token de Agora RTC con rol de publicador
    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      channelName,
      agoraUid,
      RtcRole.PUBLISHER,
      privilegeExpiredTs
    )

    return new Response(JSON.stringify({ token }), {
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
