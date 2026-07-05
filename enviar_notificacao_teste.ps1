# Script para enviar notificacao de teste via Edge Function do Supabase
# Uso: .\enviar_notificacao_teste.ps1 -TokenFcm "SEU_TOKEN_AQUI" -SupabaseUrl "https://SEU_PROJECT_ID.supabase.co" -SupabaseAnonKey "SUA_ANON_KEY"

param(
    [Parameter(Mandatory=$true)]
    [string]$TokenFcm
    ,
    [Parameter(Mandatory=$true)]
    [string]$SupabaseUrl,
    [Parameter(Mandatory=$true)]
    [string]$SupabaseAnonKey
)

Write-Host "Enviando notificacao de teste via Edge Function..."
Write-Host "   Token: $($TokenFcm.Substring(0, [Math]::Min(20, $TokenFcm.Length)))..."
Write-Host ""

# URL da Edge Function
$URL = "$SupabaseUrl/functions/v1/enviar-notificacao"

# Corpo da mensagem
$PAYLOAD = @{
    tokenFcm = $TokenFcm
    titulo = "TESTE"
    corpo = "Notificacao de teste via Supabase"
    dados = @{
        tipo = "teste"
    }
} | ConvertTo-Json -Depth 10

try {
    $HEADERS = @{
        "Authorization" = "Bearer $SupabaseAnonKey"
        "apikey" = $SupabaseAnonKey
        "Content-Type" = "application/json"
    }

    $RESPONSE = Invoke-RestMethod -Uri $URL -Method Post -Headers $HEADERS -Body $PAYLOAD -ErrorAction Stop
    
    Write-Host "SUCESSO! Notificacao enviada pela Edge Function."
    Write-Host ""
    Write-Host "Detalhes:"
    Write-Host "   Message ID: $($RESPONSE.messageId)"
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
    $response = $_.Exception.Response
    if ($response -ne $null) {
        $stream = $response.GetResponseStream()
        if ($stream -ne $null) {
            $reader = New-Object System.IO.StreamReader($stream)
            $body = $reader.ReadToEnd()
            if ($body) {
                Write-Host "Resposta do servidor:"
                Write-Host $body
                Write-Host ""
            }
        }
    }

    Write-Host "Detalhes do erro:"
    Write-Host $_.Exception.Message
}