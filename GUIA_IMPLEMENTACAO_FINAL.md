# Guia de Implementação Final - Notificações Push DESIADET

## 🎯 Objetivo

Implementar notificações push **100% automáticas** usando a arquitetura:
- **Flutter**: Apenas CRUD (criar/editar/cancelar)
- **Supabase Triggers**: Detectam alterações
- **Edge Functions**: Enviam notificações IMEDIATAS
- **FCM**: Entrega aos dispositivos

---

## 📋 Checklist Completo

### Fase 1: Configuração Inicial (Feito ✅)
- [x] Firebase configurado (google-services.json)
- [x] Dependências Flutter instaladas
- [x] Serviço de notificações criado
- [x] Token FCM sendo salvo no Supabase

### Fase 2: Edge Function (Pronto para Implantar)
- [ ] Instalar CLI do Supabase
- [ ] Fazer login
- [ ] Link com projeto
- [ ] Implantar função

### Fase 3: Triggers PostgreSQL (Pronto para Executar)
- [ ] Habilitar extensão net
- [ ] Executar TRIGGERS_NOTIFICACOES.sql
- [ ] Substituir PROJECT_ID e SERVICE_ROLE_KEY
- [ ] Testar triggers

### Fase 4: Testes (Pendente)
- [ ] Testar novo agendamento
- [ ] Testar cancelamento
- [ ] Testar novo evento
- [ ] Testar novo serviço

---

## 🚀 Implementação Passo a Passo

### PASSO 1: Instalar CLI do Supabase

```bash
npm install -g supabase
```

**Verificar instalação:**
```bash
supabase --version
```

---

### PASSO 2: Fazer Login

```bash
supabase login
```

Isso abrirá o navegador para autenticação.

---

### PASSO 3: Obter Credenciais do Supabase

1. Acesse: https://app.supabase.com/
2. Selecione seu projeto
3. Vá em **Settings** → **General**
4. Copie o **Reference ID** (PROJECT_ID)

Exemplo: `abcdefghijklmnopqrstuv`

5. Vá em **Settings** → **API**
6. Copie a **Service Role Key** (NÃO a Anon Key!)

Exemplo: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

---

### PASSO 4: Implantar Edge Function

```bash
# Navegue até a pasta do projeto
cd "c:\Users\darly\Desktop\app iadet"

# Link com seu projeto
supabase link --project_ref SEU_PROJECT_ID_AQUI

# Implante a função
supabase functions deploy enviar-notificacao
```

**Exemplo:**
```bash
supabase link --project_ref abcdefghijklmnopqrstuv
supabase functions deploy enviar-notificacao
```

**Verificar se foi implantada:**
```bash
supabase functions list
```

Você deve ver:
```
Name                  Status
enviar-notificacao    ACTIVE
```

---

### PASSO 5: Configurar Triggers no Supabase

1. Acesse: https://app.supabase.com/
2. Selecione seu projeto
3. Vá em **SQL Editor**
4. Clique em **New Query**
5. Cole o conteúdo do arquivo `supabase/TRIGGERS_NOTIFICACOES.sql`
6. **IMPORTANTE**: Substitua os placeholders:
   - `SEU_PROJECT_ID` → Seu Project ID
   - `SEU_SERVICE_ROLE_KEY` → Sua Service Role Key
7. Clique em **Run**

**Exemplo de substituição:**
```sql
-- Antes
url := 'https://SEU_PROJECT_ID.supabase.co/functions/v1/enviar-notificacao'

-- Depois
url := 'https://abcdefghijklmnopqrstuv.supabase.co/functions/v1/enviar-notificacao'
```

---

### PASSO 6: Habilitar Extensão net

Execute no SQL Editor:

```sql
-- Habilitar extensão para requisições HTTP
CREATE EXTENSION IF NOT EXISTS net WITH SCHEMA public;
```

---

### PASSO 7: Verificar se os Triggers Foram Criados

```sql
-- Listar todos os triggers
SELECT 
  trigger_name,
  event_manipulation,
  action_timing,
  event_object_table
FROM information_schema.triggers
WHERE trigger_schema = 'public';
```

Você deve ver:
```
trigger_novo_agendamento
trigger_cancelamento_agendamento
trigger_novo_evento
trigger_novo_servico
```

---

### PASSO 8: Testar a Edge Function

Execute no SQL Editor:

```sql
-- 1. Buscar um token FCM válido
SELECT id, email, fcm_token 
FROM public.profiles 
WHERE fcm_token IS NOT NULL 
LIMIT 1;

-- 2. Testar a Edge Function (substitua com dados reais)
SELECT net.http_post(
  url := 'https://SEU_PROJECT_ID.supabase.co/functions/v1/enviar-notificacao',
  headers := jsonb_build_object(
    'Content-Type', 'application/json',
    'Authorization', 'Bearer SEU_SERVICE_ROLE_KEY'
  ),
  body := jsonb_build_object(
    'tokenFcm', 'TOKEN_FCM_AQUI',
    'titulo', 'Teste',
    'corpo', 'Teste de notificação'
  )
);
```

**Verificar logs:**
- Vá em **Functions** → **Logs**
- Você deve ver a requisição

---

### PASSO 9: Testar Trigger de Novo Agendamento

```sql
-- 1. Verificar se o profissional tem token FCM
SELECT id, full_name, fcm_token 
FROM public.profiles 
WHERE tipo = 'profissional' 
LIMIT 1;

-- 2. Criar um agendamento de teste
INSERT INTO agendamentos (
  nome_paciente,
  profissional_id,
  data_agendamento,
  horario,
  status,
  created_at
) VALUES (
  'Teste Automático',
  'ID_DO_PROFISSIONAL_AQUI',
  CURRENT_DATE + INTERVAL '1 day',
  '14:00',
  'confirmado',
  NOW()
);

-- 3. Verificar logs
-- Vá em: Database → Logs → Edge Function Logs
-- Você deve ver a chamada da função
```

**Resultado esperado:**
- Profissional recebe notificação em até 10 segundos
- Log mostra: "Notificação enviada com sucesso"

---

### PASSO 10: Testar Trigger de Cancelamento

```sql
-- 1. Pegar um agendamento existente
SELECT id, status FROM agendamentos LIMIT 1;

-- 2. Cancelar o agendamento
UPDATE agendamentos 
SET 
  status = 'cancelado',
  updated_at = NOW()
WHERE id = 'ID_DO_AGENDAMENTO_AQUI'
  AND status != 'cancelado';

-- 3. Verificar se a notificação foi enviada
```

**Resultado esperado:**
- Profissional recebe notificação de cancelamento

---

### PASSO 11: Testar Trigger de Novo Evento

```sql
-- 1. Criar um evento de teste
INSERT INTO eventos (
  titulo,
  descricao,
  data_inicio,
  data_fim,
  local,
  ativo
) VALUES (
  'Evento Teste',
  'Descrição do evento teste',
  '2024-12-31',
  '2024-12-31',
  'Igreja Principal',
  true
);

-- 2. Todos os usuários com token FCM devem receber notificação
```

**Resultado esperado:**
- Todos os usuários recebem notificação

---

### PASSO 12: Testar Trigger de Novo Serviço

```sql
-- 1. Criar um serviço de teste
INSERT INTO servicos (
  nome,
  descricao,
  duracao_minutos,
  ativo
) VALUES (
  'Serviço Teste',
  'Descrição do serviço teste',
  60,
  true
);

-- 2. Todos os usuários com token FCM devem receber notificação
```

**Resultado esperado:**
- Todos os usuários recebem notificação

---

## 🎯 Resultado Final

Depois de implementar tudo:

### Flutter (Código Limpo)
```dart
Future<void> criarAgendamento(Agendamento agendamento) async {
  // Apenas salva no banco
  await Supabase.instance.client
      .from('agendamentos')
      .insert(agendamento.toMap());
  
  // Trigger cuida do resto automaticamente!
}
```

### Comportamento Automático
1. ✅ Usuário cria agendamento no app
2. ✅ Dados salvos no Supabase
3. ✅ Trigger detecta INSERT
4. ✅ Edge Function é chamada
5. ✅ Notificação enviada via FCM
6. ✅ Profissional recebe em até 10 segundos

---

## 📊 Monitoramento

### Ver Logs dos Triggers

```sql
-- Logs do banco de dados
SELECT * FROM pg_stat_activity WHERE state = 'active';
```

### Ver Logs da Edge Function

```bash
# Via CLI
supabase functions logs enviar-notificacao

# Ou pelo Dashboard
# Functions → enviar-notificacao → Logs
```

### Ver Tokens FCM Ativos

```sql
SELECT 
  id, 
  email, 
  full_name,
  LENGTH(fcm_token) as token_length,
  fcm_token IS NOT NULL as has_token
FROM public.profiles
ORDER BY created_at DESC;
```

---

## 🐛 Troubleshooting Comum

### Problema 1: Trigger não dispara

**Sintoma:** Notificação não é enviada após criar agendamento

**Verificar:**
```sql
-- 1. Trigger existe?
SELECT * FROM information_schema.triggers 
WHERE trigger_name = 'trigger_novo_agendamento';

-- 2. Extensão net está habilitada?
SELECT * FROM pg_extension WHERE extname = 'net';

-- 3. Logs do banco
SELECT * FROM pg_stat_activity;
```

**Solução:**
```sql
-- Recriar trigger
DROP TRIGGER IF EXISTS trigger_novo_agendamento ON public.agendamentos;

-- Executar novamente o arquivo TRIGGERS_NOTIFICACOES.sql
```

### Problema 2: Edge Function retorna erro 401

**Sintoma:** Logs mostram "401 Unauthorized"

**Verificar:**
- Service Role Key está correta?
- URL da função está correta?

**Solução:**
```bash
# Reimplantar função
supabase functions deploy enviar-notificacao

# Verificar logs
supabase functions logs enviar-notificacao
```

### Problema 3: Notificação não chega

**Sintoma:** Tudo funciona mas notificação não aparece

**Verificar:**
```sql
-- 1. Token FCM é válido?
SELECT fcm_token FROM profiles WHERE id = '...';

-- 2. Token foi atualizado recentemente?
SELECT updated_at FROM profiles WHERE id = '...';

-- 3. App tem permissão?
-- Verificar nas configurações do Android
```

**Solução:**
```sql
-- Limpar token e pedir para fazer login novamente
UPDATE public.profiles SET fcm_token = NULL WHERE id = '...';
```

---

## ✅ Checklist Final de Verificação

- [ ] CLI do Supabase instalada
- [ ] Login realizado
- [ ] Projeto linkado
- [ ] Edge Function implantada
- [ ] Extensão net habilitada
- [ ] Triggers criados (4 triggers)
- [ ] Teste de novo agendamento ✅
- [ ] Teste de cancelamento ✅
- [ ] Teste de novo evento ✅
- [ ] Teste de novo serviço ✅
- [ ] Notificações chegando em até 10s ✅
- [ ] Logs funcionando ✅

---

## 🎉 Conclusão

Depois de seguir este guia, você terá:

✅ **Notificações 100% automáticas**  
✅ **Código Flutter limpo** (apenas CRUD)  
✅ **Entrega imediata** (até 10 segundos)  
✅ **Escalável** (Edge Functions serverless)  
✅ **Confiável** (Triggers no banco)  
✅ **Fácil manutenção** (tudo centralizado)

**Boa implementação!** 🚀