#!/usr/bin/env python3
"""
Script para enviar notificação de teste via Edge Function do Supabase.
Uso: python testar_notificacao.py <TOKEN_FCM> <SUPABASE_URL> <SUPABASE_ANON_KEY>
"""

import sys
import json
from urllib import request, error

def enviar_notificacao(token_fcm, supabase_url, supabase_anon_key):
    """Envia notificação de teste via Edge Function do Supabase."""

    url = f"{supabase_url.rstrip('/')}/functions/v1/enviar-notificacao"

    headers = {
        "Authorization": f"Bearer {supabase_anon_key}",
        "apikey": supabase_anon_key,
        "Content-Type": "application/json"
    }

    mensagem = {
        "tokenFcm": token_fcm,
        "titulo": "TESTE",
        "corpo": "Teste de notificação via Supabase",
        "dados": {
            "tipo": "teste"
        }
    }
    
    try:
        data = json.dumps(mensagem).encode('utf-8')
        req = request.Request(url, data=data, headers=headers, method='POST')
        with request.urlopen(req) as response:
            response_body = response.read().decode('utf-8')
            resultado = json.loads(response_body)

        if resultado:
            print("✅ Notificação enviada com sucesso!")
            print(f"   Message ID: {resultado.get('messageId', 'N/A')}")
            print("\n⏱️  A notificação deve chegar em até 10 segundos.")
            print("   Se não chegar, verifique:")
            print("   1. Se o app está fechado")
            print("   2. Se as permissões de notificação estão habilitadas")
            print("   3. Se o token FCM é válido")
            return
    except Exception as e:
        if isinstance(e, error.HTTPError):
            print(f"❌ Erro ao enviar notificação: {e.code}")
            print(f"   Resposta: {e.read().decode('utf-8')}")
        else:
            print(f"❌ Erro: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Uso: python testar_notificacao.py <TOKEN_FCM> <SUPABASE_URL> <SUPABASE_ANON_KEY>")
        print("\nPara obter o token FCM:")
        print("1. Execute o app: flutter run")
        print("2. Faça login")
        print("3. Verifique os logs no terminal")
        print("4. Ou execute no Supabase:")
        print("   SELECT fcm_token FROM public.profiles WHERE fcm_token IS NOT NULL;")
        sys.exit(1)
    
    token = sys.argv[1]
    supabase_url = sys.argv[2]
    supabase_anon_key = sys.argv[3]
    print(f"📱 Enviando notificação para token: {token[:20]}...")
    print()
    enviar_notificacao(token, supabase_url, supabase_anon_key)