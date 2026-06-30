# Configurar Service Account para Firebase

## 🔐 Por Que Service Account?

A **API HTTP v1** do Firebase Cloud Messaging requer autenticação via **OAuth 2.0** (Access Token), não API Key.

**Diferença:**
- ❌ **API Key** (google-services.json): Para apps Android/iOS
- ✅ **Service Account**: Para acesso via API/Backend

---

## 📋 Passo a Passo

### 1. Criar Service Account no Firebase

1. Acesse: https://console.firebase.google.com/
2. Selecione o projeto: **app-iadet**
3. Vá em **Project Settings** (ícone de engrenagem)
4. Aba **Service Accounts**
5. Clique em **Generate new private key**
6. Confirme clicando em **Generate key**

Um arquivo JSON será baixado.

### 2. Extrair Informações do JSON

Abra o arquivo JSON baixado e extraia:

```json
{
  "type": "service_account",
  "project_id": "app-iadet",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@app-iadet.iam.gserviceaccount.com",
  "client_id": "123456789",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

Você precisará de:
- `client_email`
- `private_key`

### 3. Configurar Secrets

```bash
# Secret 1: Client Email
supabase secrets set FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@app-iadet.iam.gserviceaccount.com

# Secret 2: Private Key (cuidado com as quebras de linha!)
supabase secrets set FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

**Importante:** A private_key deve ter as quebras de linha como `\n` no secret.

### 4. Atualizar Edge Function

A Edge Function agora usará a Service Account para gerar um Access Token automaticamente.

---

## 🔧 Como Funciona

### Fluxo de Autenticação

```
1. Edge Function lê Secrets (client_email + private_key)
   ↓
2. Gera JWT (JSON Web Token) usando a private_key
   ↓
3. Troca JWT por Access Token (OAuth 2.0)
   ↓
4. Usa Access Token para chamar API FCM
```

### Código da Edge Function

```typescript
// 1. Ler secrets
const clientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL')
const privateKey = Deno.env.get('FIREBASE_PRIVATE_KEY')

// 2. Gerar JWT
const jwt = await generateJWT(clientEmail, privateKey)

// 3. Obter access token
const accessToken = await exchangeJWTForAccessToken(jwt)

// 4. Usar na API FCM
const response = await fetch(url, {
  headers: {
    'Authorization': `Bearer ${accessToken}`,
    'Content-Type': 'application/json'
  }
})
```

---

## ✅ Vantagens do Service Account

1. **Segurança:** Credenciais próprias para backend
2. **Controle:** Permissões específicas do Firebase
3. **Rastreabilidade:** Logs de uso no Firebase Console
4. **Padrão:** Método recomendado pelo Google
5. **Escalável:** Funciona para qualquer volume

---

## 🧪 Testar

### 1. Testar Localmente

```bash
# Definir secrets
export FIREBASE_CLIENT_EMAIL="firebase-adminsdk-xxxxx@app-iadet.iam.gserviceaccount.com"
export FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# Executar função
supabase functions serve enviar-notificacao
```

### 2. Testar via Curl

```bash
curl -X POST \
  'https://SEU_PROJECT_ID.supabase.co/functions/v1/enviar-notificacao' \
  -H 'Content-Type: application/json' \
  -d '{
    "tokenFcm": "TOKEN_FCM",
    "titulo": "Teste",
    "corpo": "Teste de notificação"
  }'
```

**Nota:** Não precisa mais de Authorization header!

---

## 📝 Checklist

- [ ] Service Account criada no Firebase
- [ ] Arquivo JSON baixado
- [ ] client_email extraído
- [ ] private_key extraída
- [ ] Secrets configurados no Supabase
- [ ] Edge Function atualizada
- [ ] Teste realizado com sucesso

---

## 🚀 Próximos Passos

1. **Criar Service Account** no Firebase Console
2. **Configurar secrets:**
   ```bash
   supabase secrets set FIREBASE_CLIENT_EMAIL=...
   supabase secrets set FIREBASE_PRIVATE_KEY=...
   ```
3. **Atualizar código** da Edge Function para usar Service Account
4. **Reimplantar:**
   ```bash
   supabase functions deploy enviar-notificacao
   ```

**Pronto! Autenticação correta e segura!** 🔐