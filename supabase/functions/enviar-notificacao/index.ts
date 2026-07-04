import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Converte uma chave privada PEM (PKCS#8) para DER (bytes)
function pemToDer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s+/g, '')
  const binary = atob(base64)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i)
  }
  return bytes.buffer
}

function base64UrlEncode(bytes: Uint8Array): string {
  let binary = ''
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i])
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

// Função para gerar JWT a partir da Service Account.
// Usa WebCrypto (crypto.subtle), a API disponível no runtime Deno das
// Edge Functions — `crypto.createSign` é API do Node e não existe aqui.
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

  // Secrets costumam armazenar a chave com '\n' literais no lugar de quebras
  const pem = privateKey.replace(/\\n/g, '\n')
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToDer(pem),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  )

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsignedToken)
  )
  const encodedSignature = base64UrlEncode(new Uint8Array(signature))

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
        webpush: {
          // Clique na notificação web abre o PWA (Android/iOS ignoram)
          fcm_options: {
            link: 'https://darlysson717.github.io/SISTEMA-DE-GESTAO-DE-IGREJAS/',
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