import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

interface NotificacaoPayload {
  versao: string
  apk_url: string
  changelog?: string
}

serve(async (req) => {
  try {
    // Verifica autenticação (deve vir do Supabase Management API ou cron)
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Não autorizado" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      })
    }

    const payload: NotificacaoPayload = await req.json()
    const { versao, apk_url, changelog } = payload

    if (!versao || !apk_url) {
      return new Response(
        JSON.stringify({ error: "Campos obrigatórios: versao, apk_url" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    // Cria cliente Supabase com a service role key
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    )

    // Busca todos os usuários com FCM token
    const { data: profiles, error: profilesError } = await supabaseClient
      .from("profiles")
      .select("id, fcm_token")
      .not("fcm_token", "is", null)

    if (profilesError) {
      return new Response(
        JSON.stringify({ error: "Erro ao buscar perfis: " + profilesError.message }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      )
    }

    if (!profiles || profiles.length === 0) {
      return new Response(
        JSON.stringify({ message: "Nenhum usuário com FCM token encontrado", usuarios_notificados: 0 }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      )
    }

    // Envia notificação para cada usuário
    let notificados = 0
    const erros: string[] = []

    for (const perfil of profiles) {
      const tokenFcm = perfil.fcm_token as string
      if (!tokenFcm) continue

      try {
        await supabaseClient.functions.invoke("enviar-notificacao", {
          body: {
            tokenFcm: tokenFcm,
            titulo: `Nova versão disponível 🎉`,
            corpo: `Versão ${versao} já está disponível para download!`,
            dados: {
              tipo: "atualizacao",
              versao: versao,
              apk_url: apk_url,
              changelog: changelog ?? "",
            },
          },
        })
        notificados++
      } catch (e) {
        erros.push(`Erro ao notificar usuário ${perfil.id}: ${e}`)
      }
    }

    return new Response(
      JSON.stringify({
        message: "Notificações enviadas",
        usuarios_notificados: notificados,
        total_usuarios: profiles.length,
        erros: erros.length > 0 ? erros : undefined,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    )
  } catch (e) {
    return new Response(
      JSON.stringify({ error: "Erro interno: " + e.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})