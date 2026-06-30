import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Função para gerar JWT a partir da Service Account
async function generateJWT(clientEmail: string, privateKey: string): Promise<string> {
  const header = {
    alg: 'RS256',
    typ: 'JWT'
  }

  const now = Math.floor(Date.now() / 1000)
  const payload = {
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600 // 1 hora
  }

  // Codificar header e payload em base64
  const encodedHeader = btoa(JSON.stringify(header)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
  const encodedPayload = btoa(JSON.stringify(payload)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

  const unsignedToken = `${encodedHeader}.${encodedPayload}`

  // Assinar com a private key (RSA-SHA256)
  const crypto = globalThis.crypto || require('crypto')
  const sign = crypto.createSign('RSA-SHA256')
  sign.update(unsignedToken)
  const signature = sign.sign(privateKey, 'base64')
  const encodedSignature = signature.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

  return `${unsignedToken}.${encodedSignature}`
}

// Função para trocar JWT por Access Token
async function getAccessToken(clientEmail: string, privateKey: string): Promise<string> {
  const jwt = await generateJWT(clientEmail, privateKey)

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt
    })
  })

  if (!response.ok) {
    const error = await response.text()
    console.error('Erro ao obter access token:', error)
    throw new Error('Falha na autenticação OAuth')
  }

  const data = await response.json()
  return data.access_token
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Apenas POST
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Obter dados do corpo da requisição
    const { tokenFcm, titulo, corpo, dados } = await req.json()

    // Validações
    if (!tokenFcm || !titulo || !corpo) {
      return new Response(
        JSON.stringify({ error: 'tokenFcm, titulo e corpo são obrigatórios' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Ler Service Account das variáveis de ambiente (secrets)
    const clientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL')
    const privateKey = Deno.env.get('FIREBASE_PRIVATE_KEY')
    const projectId = Deno.env.get('PROJECT_ID') || 'app-iadet'

    if (!clientEmail || !privateKey) {
      console.error('Service Account não configurada')
      return new Response(
        JSON.stringify({ error: 'Configuração do servidor incompleta' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Obter Access Token via OAuth 2.0
    let accessToken: string
    try {
      accessToken = await getAccessToken(clientEmail, privateKey)
    } catch (error) {
      console.error('Erro na autenticação:', error)
      return new Response(
        JSON.stringify({ error: 'Erro na autenticação Firebase' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // URL da API FCM HTTP v1
    const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

    // Construir mensagem
    const mensagem: any = {
      message: {
        token: tokenFcm,
        notification: {
          title: titulo,
          body: corpo,
        },
        android: {
          priority: 'high',
          notification: {
            channel_id: 'high_importance_channel',
            priority: 'high',
            visibility: 'public',
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: titulo,
                body: corpo,
              },
              sound: 'default',
              badge: 1,
            },
          },
        },
      },
    }

    // Adicionar dados customizados se fornecidos
    if (dados && typeof dados === 'object') {
      mensagem.message.data = dados
    }

    // Enviar notificação
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(mensagem),
    })

    const result = await response.json()

    if (!response.ok) {
      console.error('Erro ao enviar notificação:', result)
      return new Response(
        JSON.stringify({ 
          error: 'Erro ao enviar notificação',
          details: result 
        }),
        { status: response.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Sucesso
    console.log('Notificação enviada com sucesso:', result)
    
    return new Response(
      JSON.stringify({ 
        success: true,
        messageId: result.name,
        message: 'Notificação enviada com sucesso'
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Erro na Edge Function:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Erro interno do servidor',
        details: error.message 
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})