# Checklist de Configuração de Notificações

## ✅ Passo 1: Criar Tabela de Notificações In-App

Execute no Supabase SQL Editor:

```sql
-- Executar arquivo: CREATE_APP_NOTIFICATIONS_TABLE.sql
\i supabase/CREATE_APP_NOTIFICATIONS_TABLE.sql
```

Ou copie o conteúdo do arquivo e execute diretamente.

## ✅ Passo 2: Adicionar Coluna fcm_token na Tabela Profiles

Execute no Supabase SQL Editor:

```sql
-- Executar arquivo: ADD_FCM_TOKEN_COLUMN.sql
\i supabase/ADD_FCM_TOKEN_COLUMN.sql
```

Ou copie o conteúdo do arquivo e execute diretamente.

## ✅ Passo 3: Deploy da Edge Function

A Edge Function `enviar-notificacao` precisa estar deployada no Supabase.

Execute no terminal (na raiz do projeto):

```bash
# Deploy da função
supabase functions deploy enviar-notificacao
```

## ✅ Passo 4: Verificar Configurações do Firebase

1. Verifique se o arquivo `android/app/google-services.json` existe
2. Verifique se o arquivo `web/firebase-messaging-sw.js` existe
3. Verifique se a chave VAPID está configurada em `lib/src/nucleo/configuracao/configuracao_app.dart`

## ✅ Passo 5: Testar

1. Faça login no app
2. Verifique se o token FCM está sendo salvo:
   ```sql
   SELECT id, email, fcm_token FROM profiles WHERE fcm_token IS NOT NULL;
   ```
3. Faça um agendamento de teste
4. Verifique se a notificação chegou

## 🔍 Troubleshooting

### Notificação não chega no PWA:

1. **Verifique se o PWA está instalado**: Notificações push só funcionam em PWAs instalados
2. **Verifique permissões do navegador**: O navegador precisa ter permissão para notificações
3. **Verifique se o token FCM foi salvo**:
   ```sql
   SELECT id, email, fcm_token FROM profiles WHERE id = 'SEU_USER_ID';
   ```

### Notificação in-app não aparece:

1. **Verifique se a tabela foi criada**:
   ```sql
   SELECT * FROM app_notifications LIMIT 1;
   ```

2. **Verifique se há notificações**:
   ```sql
   SELECT * FROM app_notifications WHERE user_id = 'SEU_USER_ID' ORDER BY created_at DESC;
   ```

### Logs de Debug:

No Flutter, execute em modo debug e verifique os logs:
- `🔑 Token FCM obtido: ...`
- `✅ Token FCM salvo no Supabase`
- `✅ Notificação sincronizada enviada para ...`

## 📋 Ordem de Execução

1. ✅ Executar `CREATE_APP_NOTIFICATIONS_TABLE.sql`
2. ✅ Executar `ADD_FCM_TOKEN_COLUMN.sql`
3. ✅ Deploy da Edge Function: `supabase functions deploy enviar-notificacao`
4. ✅ Testar no app

## 🚨 Importante

- A tabela `app_notifications` é OBRIGATÓRIA para notificações in-app
- A coluna `fcm_token` é OBRIGATÓRIA para push notifications
- A Edge Function é OBRIGATÓRIA para enviar push notifications