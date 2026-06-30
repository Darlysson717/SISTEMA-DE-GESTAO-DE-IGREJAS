# Configurar Secrets na Edge Function

## 🔐 Por Que Usar Secrets?

**Segurança:** A `SERVICE_ROLE_KEY` e `FIREBASE_API_KEY` são informações sensíveis que **nunca** devem ser expostas no código ou no app Flutter.

**Solução:** Usar **Secrets** do Supabase que:
- São armazenados de forma criptografada
- Não aparecem no código fonte
- Não são expostos em logs
- São injetados como variáveis de ambiente

---

## 📋 Passo a Passo

### 1. Instalar CLI do Supabase

```bash
npm install -g supabase
```

### 2. Fazer Login

```bash
supabase login
```

### 3. Link com o Projeto

```bash
supabase link --project_ref SEU_PROJECT_ID
```

**Como encontrar o PROJECT_ID:**
- Acesse: https://app.supabase.com/
- Vá em **Settings** → **General**
- Copie o **Reference ID**

Exemplo: `abcdefghijklmnopqrstuv`

### 4. Configurar Secrets

```bash
# Secret 1: Service Role Key (do Supabase)
supabase secrets set SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Secret 2: Firebase API Key (do google-services.json)
supabase secrets set FIREBASE_API_KEY=AIzaSyCeHQKj_SjVwQr92S_GVXuskcTVPMZ2YBA
```

**Como obter as chaves:**

**Service Role Key:**
1. Acesse: https://app.supabase.com/
2. Vá em **Settings** → **API**
3. Copie a **Service Role Key** (NÃO a Anon Key!)

**Firebase API Key:**
1. Abra o arquivo `android/app/google-services.json`
2. Procure por `"current_key"`
3. Copie o valor

Exemplo:
```json
{
  "api_key": [
    {
      "current_key": "AIzaSyCeHQKj_SjVwQr92S_GVXuskcTVPMZ2YBA"
    }
  ]
}
```

### 5. Verificar Secrets Configurados

```bash
supabase secrets list
```

Você deve ver:
```
Name                  Value
SERVICE_ROLE_KEY      eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
FIREBASE_API_KEY      AIzaSyCeHQKj_SjVwQr92S_GVXuskcTVPMZ2YBA
```

**Nota:** O valor não é exibido por segurança, apenas o nome.

### 6. Implantar Edge Function

```bash
supabase functions deploy enviar-notificacao
```

---

## 🔍 Como Funciona

### Na Edge Function

```typescript
// Antes (inseguro):
const apiKey = 'AIzaSyCeHQKj_SjVwQr92S_GVXuskcTVPMZ2YBA'  // ❌ Exposto!

// Depois (seguro):
const apiKey = Deno.env.get('FIREBASE_API_KEY')  // ✅ Seguro!
```

### Variáveis Disponíveis

```typescript
// Secrets (variáveis de ambiente)
const serviceRoleKey = Deno.env.get('SERVICE_ROLE_KEY')  // Secreto
const firebaseApiKey = Deno.env.get('FIREBASE_API_KEY')  // Secreto

// Vars (variáveis públicas)
const projectId = Deno.env.get('PROJECT_ID')  // Público
```

---

## 🧪 Testar

### 1. Testar Localmente

```bash
# Definir secrets localmente
export SERVICE_ROLE_KEY="seu_service_role_key"
export FIREBASE_API_KEY="sua_firebase_api_key"

# Executar função localmente
supabase functions serve enviar-notificacao
```

### 2. Testar em Produção

```bash
# Via curl
curl -X POST \
  'https://SEU_PROJECT_ID.supabase.co/functions/v1/enviar-notificacao' \
  -H 'Authorization: Bearer SEU_SERVICE_ROLE_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "tokenFcm": "TOKEN_FCM",
    "titulo": "Teste",
    "corpo": "Teste de notificação"
  }'
```

---

## 📊 Atualizar Triggers

Depois de configurar os secrets, os triggers **não precisam mais** da Service Role Key hardcoded!

### Antes (inseguro):
```sql
PERFORM net.http_post(
  url := 'https://SEU_PROJECT_ID.supabase.co/functions/v1/enviar-notificacao',
  headers := jsonb_build_object(
    'Content-Type', 'application/json',
    'Authorization', 'Bearer SEU_SERVICE_ROLE_KEY'  -- ❌ Exposto
  ),
  ...
);
```

### Depois (seguro):
```sql
PERFORM net.http_post(
  url := 'https://SEU_PROJECT_ID.supabase.co/functions/v1/enviar-notificacao',
  headers := jsonb_build_object(
    'Content-Type', 'application/json'
    -- Não precisa mais de Authorization!
    -- A Edge Function usa secrets internamente
  ),
  ...
);
```

**Vantagem:** Os triggers não precisam mais saber a Service Role Key!

---

## ✅ Checklist de Segurança

- [ ] Service Role Key armazenada como Secret
- [ ] Firebase API Key armazenada como Secret
- [ ] Nenhuma chave hardcoded no código
- [ ] Nenhuma chave exposta no app Flutter
- [ ] Edge Function implantada com secrets
- [ ] Triggers atualizados (sem Authorization header)

---

## 🎯 Vantagens Desta Abordagem

1. **Segurança:** Chaves nunca expostas
2. **Centralizado:** Gerenciado pelo Supabase
3. **Flexível:** Fácil trocar chaves sem alterar código
4. **Auditável:** Logs de acesso aos secrets
5. **Privado:** Secrets não aparecem em logs ou código

---

## 📝 Comandos Úteis

```bash
# Listar secrets
supabase secrets list

# Adicionar secret
supabase secrets set NOME_DO_SECRET=valor

# Remover secret
supabase secrets unset NOME_DO_SECRET

# Ver logs da função
supabase functions logs enviar-notificacao

# Reimplantar função
supabase functions deploy enviar-notificacao
```

---

## 🚀 Próximos Passos

1. **Configurar secrets:**
   ```bash
   supabase secrets set SERVICE_ROLE_KEY=sua_chave
   supabase secrets set FIREBASE_API_KEY=sua_chave
   ```

2. **Atualizar triggers** (remover header Authorization):
   ```sql
   -- Remover a linha 'Authorization' dos headers
   -- A Edge Function agora usa secrets internamente
   ```

3. **Reimplantar função:**
   ```bash
   supabase functions deploy enviar-notificacao
   ```

4. **Testar:**
   ```sql
   INSERT INTO public.appointments (...) VALUES (...);
   ```

**Pronto! Sistema 100% seguro e funcional!** 🔐