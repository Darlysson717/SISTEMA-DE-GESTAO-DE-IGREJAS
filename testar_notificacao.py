#!/usr/bin/env python3
"""
Script para enviar notificação de teste via Firebase Cloud Messaging API.
Uso: python testar_notificacao.py <TOKEN_FCM>
"""

import sys
import requests
import json

# Configurações do Firebase
FIREBASE_PROJECT_ID = "app-iadet"
FIREBASE_API_KEY = "AIzaSyCeHQKj_SjVwQr92S_GVXuskcTVPMZ2YBA"  # API key do google-services.json

def enviar_notificacao(token_fcm):
    """Envia notificação de teste via FCM HTTP v1 API."""
    
    # URL da API FCM
    url = f"https://fcm.googleapis.com/v1/projects/{FIREBASE_PROJECT_ID}/messages:send"
    
    # Headers com autenticação
    headers = {
        "Authorization": f"Bearer {FIREBASE_API_KEY}",
        "Content-Type": "application/json"
    }
    
    # Corpo da mensagem - APENAS notification (sem data)
    mensagem = {
        "message": {
            "token": token_fcm,
            "notification": {
                "title": "TESTE",
                "body": "Teste de notificação"
            },
            "android": {
                "priority": "high",
                "notification": {
                    "channel_id": "high_importance_channel",
                    "priority": "high",
                    "visibility": "public"
                }
            }
        }
    }
    
    try:
        response = requests.post(url, headers=headers, json=mensagem)
        
        if response.status_code == 200:
            resultado = response.json()
            print("✅ Notificação enviada com sucesso!")
            print(f"   Message ID: {resultado.get('name', 'N/A')}")
            print("\n⏱️  A notificação deve chegar em até 10 segundos.")
            print("   Se não chegar, verifique:")
            print("   1. Se o app está fechado")
            print("   2. Se as permissões de notificação estão habilitadas")
            print("   3. Se o token FCM é válido")
        else:
            print(f"❌ Erro ao enviar notificação: {response.status_code}")
            print(f"   Resposta: {response.text}")
            
    except Exception as e:
        print(f"❌ Erro: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python testar_notificacao.py <TOKEN_FCM>")
        print("\nPara obter o token FCM:")
        print("1. Execute o app: flutter run")
        print("2. Faça login")
        print("3. Verifique os logs no terminal")
        print("4. Ou execute no Supabase:")
        print("   SELECT fcm_token FROM public.profiles WHERE fcm_token IS NOT NULL;")
        sys.exit(1)
    
    token = sys.argv[1]
    print(f"📱 Enviando notificação para token: {token[:20]}...")
    print()
    enviar_notificacao(token)