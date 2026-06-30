# Script para enviar notificacao de teste via Firebase Cloud Messaging
# Uso: .\enviar_notificacao_teste.ps1 -TokenFcm "SEU_TOKEN_AQUI"

param(
    [Parameter(Mandatory=$true)]
    [string]$TokenFcm
)

Write-Host "Enviando notificacao de teste..."
Write-Host "   Token: $($TokenFcm.Substring(0, [Math]::Min(20, $TokenFcm.Length)))..."
Write-Host ""

# Projeto Firebase
$PROJECT_ID = "app-iadet"

# URL da API FCM
$URL = "https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send"

# API Key (do google-services.json)
$API_KEY = "AIzaSyCeHQKj_SjVwQr92S_GVXuskcTVPMZ2YBA"

# Corpo da mensagem
$PAYLOAD = @{
    message = @{
        token = $TokenFcm
        notification = @{
            title = "TESTE"
            body = "Notificacao de teste - chegou rapido?"
        }
        android = @{
            priority = "high"
            notification = @{
                channel_id = "high_importance_channel"
                priority = "high"
                visibility = "public"
                sound = "default"
            }
        }
        apns = @{
            payload = @{
                aps = @{
                    alert = @{
                        title = "TESTE"
                        body = "Notificacao de teste - chegou rapido?"
                    }
                    sound = "default"
                    badge = 1
                }
            }
        }
    }
} | ConvertTo-Json -Depth 10

try {
    $HEADERS = @{
        "Authorization" = "Bearer $API_KEY"
        "Content-Type" = "application/json"
    }

    $RESPONSE = Invoke-RestMethod -Uri $URL -Method Post -Headers $HEADERS -Body $PAYLOAD
    
    Write-Host "SUCESSO! Notificacao enviada."
    Write-Host ""
    Write-Host "Detalhes:"
    Write-Host "   Message ID: $($RESPONSE.name)"
    Write-Host ""
    Write-Host "A notificacao deve chegar em ate 10 segundos."
    Write-Host ""
    Write-Host "Verifique no celular:"
    Write-Host "   - Se o app esta FECHADO (nao minimizado)"
    Write-Host "   - Se as notificacoes estao habilitadas"
    Write-Host "   - Se o som esta ativado"
}
catch {
    Write-Host "ERRO ao enviar notificacao"
    Write-Host ""
    Write-Host "Detalhes do erro:"
    Write-Host $_.Exception.Message
}