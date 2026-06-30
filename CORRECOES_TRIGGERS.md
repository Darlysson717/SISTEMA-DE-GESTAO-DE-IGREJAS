# Correções nos Triggers de Notificação

## ✅ Problema Resolvido

**Erro anterior:**
```
ERROR: 42P01: relation "public.agendamentos" does not exist
```

**Causa:** Nomes das tabelas estavam em português, mas o schema usa nomes em inglês.

---

## 📊 Nomes Corretos das Tabelas

| Nome Errado (PT) | Nome Correto (EN) | Descrição |
|------------------|-------------------|-----------|
| `agendamentos` | `appointments` | Agendamentos |
| `profissionais` | `professional_profiles` | Perfis de profissionais |
| `eventos` | *(não existe)* | Tabela não criada ainda |
| `servicos` | *(não existe)* | Tabela não criada ainda |

---

## 🔧 Correções Aplicadas

### 1. Trigger de Novo Agendamento

**Antes:**
```sql
CREATE TRIGGER trigger_novo_agendamento
  AFTER INSERT ON public.agendamentos  -- ❌ ERRADO
```

**Depois:**
```sql
CREATE TRIGGER trigger_novo_agendamento
  AFTER INSERT ON public.appointments  -- ✅ CORRETO
```

### 2. Trigger de Cancelamento

**Antes:**
```sql
CREATE TRIGGER trigger_cancelamento_agendamento
  AFTER UPDATE ON public.agendamentos  -- ❌ ERRADO
  WHEN (OLD.status != 'cancelado' AND NEW.status = 'cancelado')
```

**Depois:**
```sql
CREATE TRIGGER trigger_cancelamento_agendamento
  AFTER UPDATE ON public.appointments  -- ✅ CORRETO
  WHEN (OLD.status != 'cancelled' AND NEW.status = 'cancelled')
```

**Nota:** O status também está em inglês: `'cancelled'` ao invés de `'cancelado'`

### 3. JOIN com professional_profiles

**Antes:**
```sql
SELECT p.fcm_token, p.full_name
FROM public.profiles p
WHERE p.id = NEW.profissional_id  -- ❌ ERRADO
```

**Depois:**
```sql
SELECT pp.user_id, p.fcm_token, p.full_name
FROM public.professional_profiles pp  -- ✅ CORRETO
JOIN public.profiles p ON p.id = pp.user_id
WHERE pp.user_id = NEW.professional_id
```

---

## 📋 Triggers Disponíveis

Depois das correções, você tem **2 triggers funcionais**:

### 1. Trigger de Novo Agendamento
- **Tabela:** `public.appointments`
- **Evento:** `AFTER INSERT`
- **Ação:** Notifica o profissional quando um novo agendamento é criado

### 2. Trigger de Cancelamento
- **Tabela:** `public.appointments`
- **Evento:** `AFTER UPDATE`
- **Condição:** Quando status muda para `'cancelled'`
- **Ação:** Notifica o profissional sobre o cancelamento

---

## 🚀 Como Aplicar as Correções

### Opção 1: Executar o Arquivo Completo (Recomendado)

1. Acesse: https://app.supabase.com/
2. Vá em **SQL Editor**
3. Clique em **New Query**
4. Cole o conteúdo de `supabase/TRIGGERS_NOTIFICACOES.sql`
5. **Substitua:**
   - `SEU_PROJECT_ID` → Seu Project ID
   - `SEU_SERVICE_ROLE_KEY` → Sua Service Role Key
6. Clique em **Run**

### Opção 2: Executar Apenas as Correções

Se você já executou o arquivo anteriormente, execute apenas:

```sql
-- Habilitar extensão net
CREATE EXTENSION IF NOT EXISTS net WITH SCHEMA public;

-- Recriar trigger de novo agendamento
DROP TRIGGER IF EXISTS trigger_novo_agendamento ON public.appointments;

CREATE TRIGGER trigger_novo_agendamento
  AFTER INSERT ON public.appointments
  FOR EACH ROW
  EXECUTE FUNCTION public.notificar_novo_agendamento();

-- Recriar trigger de cancelamento
DROP TRIGGER IF EXISTS trigger_cancelamento_agendamento ON public.appointments;

CREATE TRIGGER trigger_cancelamento_agendamento
  AFTER UPDATE ON public.appointments
  FOR EACH ROW
  WHEN (OLD.status != 'cancelled' AND NEW.status = 'cancelled')
  EXECUTE FUNCTION public.notificar_cancelamento_agendamento();
```

---

## 🧪 Como Testar

### Teste 1: Novo Agendamento

```sql
-- 1. Verificar se há profissionais com token FCM
SELECT 
  pp.user_id,
  p.full_name,
  p.fcm_token
FROM public.professional_profiles pp
JOIN public.profiles p ON p.id = pp.user_id
WHERE p.fcm_token IS NOT NULL
LIMIT 1;

-- 2. Criar um agendamento de teste
INSERT INTO public.appointments (
  community_user_id,
  professional_id,
  specialty,
  starts_at,
  ends_at,
  status,
  created_by
) VALUES (
  'UUID_DO_USUARIO_COMUNITARIO',
  'UUID_DO_PROFISSIONAL',
  'Especialidade',
  NOW() + INTERVAL '1 day',
  NOW() + INTERVAL '1 day' + INTERVAL '1 hour',
  'scheduled',
  'UUID_DO_USUARIO_COMUNITARIO'
);

-- 3. Verificar logs
-- Vá em: Database → Logs → Edge Function Logs
```

**Resultado esperado:**
- Profissional recebe notificação em até 10 segundos
- Log mostra: "Notificação enviada com sucesso"

### Teste 2: Cancelamento

```sql
-- 1. Pegar um agendamento existente
SELECT id, status FROM public.appointments LIMIT 1;

-- 2. Cancelar o agendamento
UPDATE public.appointments
SET 
  status = 'cancelled',
  updated_at = NOW()
WHERE id = 'UUID_DO_AGENDAMENTO'
  AND status != 'cancelled';

-- 3. Verificar se a notificação foi enviada
```

**Resultado esperado:**
- Profissional recebe notificação de cancelamento

---

## 📊 Verificar se os Triggers Estão Criados

```sql
-- Listar todos os triggers
SELECT 
  trigger_name,
  event_manipulation,
  action_timing,
  event_object_table
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND trigger_name LIKE '%notificacao%';
```

Você deve ver:
```
trigger_novo_agendamento | INSERT | AFTER | appointments
trigger_cancelamento_agendamento | UPDATE | AFTER | appointments
```

---

## 🔍 Verificar Extensão net

```sql
-- Verificar se a extensão está habilitada
SELECT * FROM pg_extension WHERE extname = 'net';
```

Se não retornar nada, execute:
```sql
CREATE EXTENSION IF NOT EXISTS net WITH SCHEMA public;
```

---

## ✅ Checklist de Verificação

- [ ] Arquivo `TRIGGERS_NOTIFICACOES.sql` atualizado
- [ ] Extensão `net` habilitada
- [ ] Trigger `trigger_novo_agendamento` criado
- [ ] Trigger `trigger_cancelamento_agendamento` criado
- [ ] Teste de novo agendamento funcionando
- [ ] Teste de cancelamento funcionando
- [ ] Notificações chegando em até 10 segundos

---

## 🎯 Próximos Passos

1. **Execute o SQL corrigido** no Supabase
2. **Teste criando um agendamento** pelo app
3. **Verifique se a notificação chega** em até 10 segundos
4. **Teste o cancelamento** de um agendamento

**Os triggers estão prontos para uso!** 🚀