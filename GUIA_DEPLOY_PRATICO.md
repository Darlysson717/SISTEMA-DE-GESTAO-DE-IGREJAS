# Guia Prático: Deploy da Edge Function

## 🎯 Objetivo

Implantar a Edge Function `enviar-notificacao` no Supabase para enviar notificações push IMEDIATAS.

---

## 📋 Pré-requisitos (Você Já Tem!)

- ✅ Firebase configurado
- ✅ Service Account criada
- ✅ CLI do Supabase instalada
- ✅ Projeto linkado

---

## 🚀 Passo a Passo na Prática

### 1. Configurar Secrets (Uma Vez)

```bash
# Abra o terminal na pasta do projeto
cd "c:\Users\darly\Desktop\app iadet"

# Configure os secrets
supabase secrets set FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@app-iadet.iam.gserviceaccount.com

# Para a private_key, copie TODO o conteúdo do JSON (incluindo BEGIN/END)
# Cuidado com as quebras de linha! Use \n
supabase secrets set FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nSUA_CHAVE_AQUI\n-----END PRIVATE KEY-----\n"

# Configure o project_id
supabase secrets set PROJECT_ID=app-iadet
```

**Dica:** Para copiar a private_key facilmente:
1. Abra o arquivo JSON da Service Account
2. Copie o valor de `private_key`
3. No Windows, use Notepad++ para substituir quebras de linha por `\n`

### 2. Verificar Secrets

```bash
supabase secrets list
```

**Saída esperada:**
```
Name                  Value
FIREBASE_CLIENT_EMAIL firebase-adminsdk-xxxxx@app-iadet.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
PROJECT_ID            app-iadet
```

**Nota:** Os valores não são exibidos por segurança, apenas os nomes.

### 3. Fazer Deploy

```bash
# Na pasta do projeto
supabase functions deploy enviar-notificacao
```

**O que acontece:**
```
Uploading function files...
Installing dependencies...
Compiling TypeScript...
Creating container...
Deploying to edge network...
Function deployed successfully!

URL: https://seu-project-id.supabase.co/functions/v1/enviar-notificacao
Status: ACTIVE
```

### 4. Verificar se Funcionou

```bash
# Ver lista de funções
supabase functions list
```

**Saída esperada:**
```
Name                  Status
enviar-notificacao    ACTIVE
```

```bash
# Ver logs
supabase functions logs enviar-notificacao
```

**Saída esperada:**
```
2024-01-15T10:30:00Z - Function initialized
2024-01-15T10:30:00Z - Ready to receive requests
```

### 5. Testar a Função

#### Opção A: Testar com curl (Linha de Comando)

```bash
curl -X POST \
  'https://SEU_PROJECT_ID.supabase.co/functions/v1/enviar-notificacao' \
  -H 'Content-Type: application/json' \
  -d '{
    "tokenFcm": "TOKEN_FCM_REAL_AQUI",
    "titulo": "Teste",
    "corpo": "Teste de notificação"
  }'
```

**Substitua:**
- `SEU_PROJECT_ID` → Seu Project ID
- `TOKEN_FCM_REAL_AQUI` → Um token FCM real de um usuário

**Resposta esperada:**
```json
{
  "success": true,
  "messageId": "projects/app-iadet/messages/abc123...",
  "message": "Notificação enviada com sucesso"
}
```

#### Opção B: Testar no Flutter

```dart
// Adicione temporariamente em algum botão
ElevatedButton(
  onPressed: () async {
    try {
      // Buscar token FCM de um profissional
      final profissional = await Supabase.instance.client
          .from('professional_profiles')
          .select('fcm_token')
          .eq('user_id', 'UUID_DO_PROFISSIONAL')
          .single();

      final tokenFcm = profissional['fcm_token'];

      if (tokenFcm != null) {
        // Chamar Edge Function
        final response = await Supabase.instance.client.functions.invoke(
          'enviar-notificacao',
          body: {
            'tokenFcm': tokenFcm,
            'titulo': 'Teste do App',
            'corpo': 'Notificação enviada do Flutter!',
          },
        );

        print('Resposta: ${response.data}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notificação enviada!')),
        );
      }
    } catch (e) {
      print('Erro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  },
  child: Text('Testar Notificação'),
)
```

---

## 🔍 Troubleshooting

### Erro: "Function not found"

**Causa:** Função não foi implantada ou nome está errado

**Solução:**
```bash
# Verificar lista de funções
supabase functions list

# Se não aparecer, implantar novamente
supabase functions deploy enviar-notificacao
```

### Erro: "Service Account não configurada"

**Causa:** Secrets não foram configurados

**Solução:**
```bash
# Verificar secrets
supabase secrets list

# Se não aparecer, configurar novamente
supabase secrets set FIREBASE_CLIENT_EMAIL=...
supabase secrets set FIREBASE_PRIVATE_KEY=...
supabase secrets set PROJECT_ID=app-iadet
```

### Erro: "Falha na autenticação OAuth"

**Causa:** Service Account inválida ou mal configurada

**Solução:**
1. Verificar se a Service Account foi criada no Firebase
2. Verificar se o arquivo JSON está correto
3. Verificar se a private_key foi copiada corretamente (com `\n`)

### Erro: "Token FCM inválido"

**Causa:** Token FCM expirou ou é inválido

**Solução:**
```sql
-- No Supabase SQL Editor
-- Verificar token
SELECT id, email, fcm_token 
FROM public.profiles 
WHERE fcm_token IS NOT NULL;

-- Limpar token (usuário fará login novamente)
UPDATE public.profiles 
SET fcm_token = NULL 
WHERE id = 'UUID_DO_USUARIO';
```

### Erro: "Permission denied"

**Causa:** Service Account não tem permissão para FCM

**Solução:**
1. Acesse Firebase Console
2. Vá em Project Settings → Service Accounts
3. Verifique se a conta tem permissão de "Firebase Cloud Messaging API Admin"

---

## ✅ Checklist de Verificação

- [ ] Secrets configurados (3 secrets)
- [ ] Deploy executado com sucesso
- [ ] Status da função: `ACTIVE`
- [ ] Teste com curl funcionando
- [ ] Notificação chegando no dispositivo
- [ ] Logs sem erros

---

## 📊 Monitoramento

### Ver Logs em Tempo Real

```bash
supabase functions logs enviar-notificacao --follow
```

### Ver Estatísticas

```bash
# Número de invocações
supabase functions logs enviar-notificacao | grep "Notificação enviada" | wc -l

# Erros
supabase functions logs enviar-notificacao | grep "Erro"
```

### Dashboard do Supabase

1. Acesse: https://app.supabase.com/
2. Vá em **Functions**
3. Selecione `enviar-notificacao`
4. Veja:
   - Logs
   - Invocações
   - Erros
   - Performance

---

## 🎯 Próximos Passos

Depois que o deploy funcionar:

1. **Integrar no Flutter:**
   - Chamar Edge Function quando criar agendamento
   - Chamar quando cancelar agendamento
   - Chamar quando criar evento/serviço

2. **Testar no App:**
   - Criar agendamento de teste
   - Verificar se profissional recebe notificação
   - Verificar se chega em até 10 segundos

3. **Monitorar:**
   - Verificar logs regularmente
   - Verificar taxa de sucesso
   - Verificar performance

---

## 💡 Dicas

### 1. Teste Local Primeiro

```bash
# Executar função localmente
supabase functions serve enviar-notificacao

# Em outro terminal, teste
curl -X POST http://localhost:54321/functions/v1/enviar-notificacao \
  -H 'Content-Type: application/json' \
  -d '{"tokenFcm": "...", "titulo": "Teste", "corpo": "Teste"}'
```

### 2. Use Variáveis de Ambiente Locais

```bash
# .env.local
FIREBASE_CLIENT_EMAIL=...
FIREBASE_PRIVATE_KEY=...
PROJECT_ID=app-iadet

# Carregar automaticamente
supabase functions serve enviar-notificacao
```

### 3. Deploy Automático (CI/CD)

```yaml
# .github/workflows/deploy.yml
name: Deploy Edge Function
on:
  push:
    branches: [main]
    paths:
      - 'supabase/functions/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: supabase/setup-cli@v1
      - run: supabase functions deploy enviar-notificacao
```

---

## 🎉 Conclusão

**O deploy é simples:**
1. Configurar secrets (uma vez)
2. Executar `supabase functions deploy enviar-notificacao`
3. Verificar se status = `ACTIVE`
4. Testar

**Resultado:**
- ✅ Função disponível publicamente
- ✅ Notificações IMEDIATAS (até 10s)
- ✅ Segura (Service Account)
- ✅ Escalável

**Pronto para usar!** 🚀