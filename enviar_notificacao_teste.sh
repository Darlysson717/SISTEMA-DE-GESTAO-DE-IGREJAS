#!/bin/bash
# Script para enviar notificação de teste via Firebase Cloud Messaging
# Uso: ./enviar_notificacao_teste.sh <TOKEN_FCM>

TOKEN_FCM="$1"

if [ -z "$TOKEN_FCM" ]; then
    echo "❌ Erro: Token FCM não fornecido"
    echo ""
    echo "Uso: ./enviar_notificacao_teste.sh <TOKEN_FCM>"
    echo ""
    echo "Para obter o token FCM:"
    echo "1. Execute: flutter run"
    echo "2. Faça login no app"
    echo "3. Verifique os logs no terminal"
    echo "4. Ou execute no Supabase:"
    echo "   SELECT fcm_token FROM public.profiles WHERE fcm_token IS NOT NULL;"
    exit 1
fi

echo "📱 Enviando notificação de teste..."
echo "   Token: ${TOKEN_FCM:0:20}..."
echo ""

# Projeto Firebase
PROJECT_ID="app-iadet"

# URL da API FCM
URL="https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send"

# API Key (do google-services.json)
API_KEY="AIzaSyCeHQKj_SjVwQr92S_GVXuskcTVPMZ2YBA"

# Corpo da mensagem
read -r -d '' PAYLOAD << EOM
{
  "message": {
    "token": "${TOKEN_FCM}",
    "notification": {
      "title": "TESTE",
      "body": "Notificação de teste - chegou rápido?"
    },
    "android": {
      "priority": "high",
      "notification": {
        "channel_id": "high_importance_channel",
        "priority": "high",
        "visibility": "public",
        "sound": "default"
      }
    },
    "apns": {
      "payload": {
        "aps": {
          "alert": {
            "title": "TESTE",
            "body": "Notificação de teste - chegou rápido?"
          },
          "sound": "default",
          "badge": 1
        }
      }
    }
  }
}
EOM

# Enviar requisição
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  "$URL")

# Separar status code do body
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

# Verificar resultado
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Notificação enviada com SUCESSO!"
    echo ""
    echo "📋 Detalhes:"
    echo "$BODY" | grep -o '"name": "[^"]*"' | cut -d'"' -f4
    echo ""
    echo "⏱️  A notificação deve chegar em até 10 segundos."
    echo ""
    echo "📱 Verifique no celular:"
    echo "   - Se o app está FECHADO (não minimizado)"
    echo "   - Se as notificações estão habilitadas"
    echo "   - Se o som está ativado"
else
    echo "❌ Erro ao enviar notificação (HTTP $HTTP_CODE)"
    echo ""
    echo "Resposta:"
    echo "$BODY"
fi