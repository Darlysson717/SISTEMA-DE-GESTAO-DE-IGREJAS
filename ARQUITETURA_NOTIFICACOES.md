# Arquitetura de Notificações Push - DESIADET

## 🎯 Visão Geral

Esta arquitetura implementa notificações push **100% automáticas** usando:
- **Flutter**: Apenas cria/edita/cancela eventos e serviços
- **Supabase**: Armazena dados e executa triggers
- **PostgreSQL Triggers**: Detectam alterações automaticamente
- **Edge Functions**: Enviam notificações via FCM
- **Firebase Cloud Messaging**: Entrega aos dispositivos

---

## 📐 Diagrama de Arquitetura

```
┌─────────────┐
│   Flutter   │  (App)
│   (Front)   │
└──────┬──────┘
       │
       │ INSERT/UPDATE/DELETE
       ▼
┌─────────────┐
│   Supabase  │  (Banco de Dados)
│  (Backend)  │
└──────┬──────┘
       │
       │ TRIGGER detecta alteração
       ▼
┌─────────────┐
│ PostgreSQL  │  (Triggers)
│   Trigger   │
└──────┬──────┘
       │
       │ Chama Edge Function
       ▼
┌─────────────┐
│    Edge     │  (Supabase Functions)
│  Function   │
└──────┬──────┘
       │
       │ Envia via API FCM
       ▼
┌─────────────┐
│     FCM     │  (Firebase)
│  (Push)     │
└──────┬──────┘
       │
       │ Entrega ao dispositivo
       ▼
┌─────────────┐
│    App      │  (Notificação recebida)
│  (Flutter)  │
└─────────────┘
```

---

## 🚀 Vantagens Desta Arquitetura

### 1. **Código Flutter Minimalista**
- Flutter apenas cria/edita/cancela dados
- Não precisa chamar funções de notificação
- Código mais limpo e fácil de manter

### 2. **Notificações Automáticas**
- Trigger dispara automaticamente
- Funciona mesmo se alterar dados pelo Supabase Dashboard
- Não depende do código Flutter

### 3. **Centralizado no Backend**
- Toda lógica de notificação no banco de dados
- Fácil de modificar sem alterar o app
- Um único lugar para gerenciar

### 4. **Confiabilidade**
- Triggers são executados no banco (sempre funcionam)
- Edge Functions são serverless (escalável)
- FCM garante entrega

### 5. **Manutenibilidade**
- Fácil adicionar novas notificações
- Fácil modificar mensagens
- Fácil adicionar novos triggers

---

## 📋 Estrutura de Arquivos

```
supabase/
├── functions/
│   └── enviar-notificacao/
│       ├── index.ts          # Edge Function
│       ├── config.toml       # Configuração
│       └── README.md         # Documentação
├── TRIGGERS_NOTIFICACOES.sql # Triggers PostgreSQL
└── SETUP_NOTIFICACOES.sql    # Setup completo

lib/src/nucleo/notificacoes/
└── servico_notificacoes.dart # Serviço Flutter (recebe)

NOTIFICACOES_PUSH_SETUP.md    # Guia completo
ARQUITETURA_NOTIFICACOES.md   # Este arquivo
```

---

## 🔧 Implementação Passo a Passo

### Passo 1: Configurar Firebase (Feito ✅)
- google-services.json ✅
- firebase_messaging ✅
- flutter_local_notifications ✅

### Passo 2: Criar Edge Function (Feito ✅)
```bash
supabase functions deploy enviar-notificacao
```

Arquivo: `supabase/functions/enviar-notificacao/index.ts`

### Passo 3: Criar Triggers (Feito ✅)
Execute no Supabase SQL Editor:
```sql
-- Arquivo: supabase/TRIGGERS_NOTIFICACOES.sql
-- Lembre-se de substituir:
-- - SEU_PROJECT_ID
-- - SEU_SERVICE_ROLE_KEY
```

### Passo 4: Configurar Flutter (Feito ✅)
- Serviço de notificações ✅
- Registro de token FCM ✅
- Integração com login/logout ✅

---

## 📊 Fluxo de Notificações

### 1. Novo Agendamento

```sql
-- Flutter insere agendamento
INSERT INTO agendamentos (nome_paciente, profissional_id, ...)
VALUES ('João', 'prof-123', ...);

-- Trigger detecta INSERT
-- Busca token FCM do profissional
-- Chama Edge Function
-- Edge Function envia via FCM
-- Profissional recebe notificação
```

**Notificação enviada:**
```
Título: "Novo Agendamento"
Corpo: "Você tem um novo agendamento de João"
```

### 2. Cancelamento de Agendamento

```sql
-- Flutter atualiza status
UPDATE agendamentos SET status = 'cancelado' WHERE id = 'ag-123';

-- Trigger detecta mudança: 'confirmado' → 'cancelado'
-- Busca token FCM do profissional
-- Chama Edge Function
-- Profissional recebe notificação
```

**Notificação enviada:**
```
Título: "Agendamento Cancelado"
Corpo: "O agendamento de João foi cancelado"
```

### 3. Novo Evento

```sql
-- Admin cria evento
INSERT INTO eventos (titulo, data_inicio, ...)
VALUES ('Culto de Celebração', '2024-12-25', ...);

-- Trigger detecta INSERT
-- Busca TODOS os usuários com token FCM
-- Chama Edge Function para cada usuário
-- Todos recebem notificação
```

**Notificação enviada:**
```
Título: "Novo Evento Disponível"
Corpo: "Confira o evento: Culto de Celebração"
```

### 4. Novo Serviço

```sql
-- Admin cria serviço
INSERT INTO servicos (nome, descricao, ...)
VALUES ('Consulta', 'Consulta médica', ...);

-- Trigger detecta INSERT
-- Busca TODOS os usuários com token FCM
-- Chama Edge Function para cada usuário
-- Todos recebem notificação
```

**Notificação enviada:**
```
Título: "Novo Serviço Disponível"
Corpo: "Confira o serviço: Consulta"
```

---

## 🔐 Segurança

### 1. Service Role Key

A Edge Function usa a **Service Role Key** do Supabase, que:
- Tem acesso total ao banco
- Ignora políticas RLS
- **NUNCA** deve ser exposta no app Flutter

### 2. Como Usar com Segurança

**Opção 1: Triggers no Banco (Recomendado)**
- Triggers usam Service Role Key internamente
- App Flutter não precisa saber a chave
- Mais seguro

**Opção 2: Chamar do Flutter**
- Use apenas para casos especiais
- Implemente verificação de JWT
- Valide permissões do usuário

### 3. Proteger Edge Function

```typescript
// Adicione verificação de JWT na Edge Function
const authHeader = req.headers.get('Authorization')
if (!authHeader) {
  return new Response(JSON.stringify({ error: 'Não autorizado' }), { status: 401 })
}

// Verificar se é Service Role Key
const token = authHeader.replace('Bearer ', '')
if (token !== process.env.SERVICE_ROLE_KEY) {
  return new Response(JSON.stringify({ error: 'Não autorizado' }), { status: 401 })
}
```

---

## 🧪 Como Testar

### Teste 1: Trigger de Novo Agendamento

```sql
-- 1. Verifique se o usuário tem token FCM
SELECT id, full_name, fcm_token 
FROM public.profiles 
WHERE id = 'prof-123';

-- 2. Crie um agendamento
INSERT INTO agendamentos (
  nome_paciente,
  profissional_id,
  data_agendamento,
  horario,
  status
) VALUES (
  'Maria Silva',
  'prof-123',
  '2024-12-25',
  '14:00',
  'confirmado'
);

-- 3. Verifique os logs do Supabase
-- Vá em: Database → Logs → Edge Function Logs
-- Você deve ver a chamada da Edge Function

-- 4. Verifique se o profissional recebeu a notificação
-- (app deve estar aberto ou em background)
```

### Teste 2: Trigger de Cancelamento

```sql
-- 1. Crie um agendamento
INSERT INTO agendamentos (...) VALUES (...);

-- 2. Cancele o agendamento
UPDATE agendamentos 
SET status = 'cancelado' 
WHERE id = 'ag-123';

-- 3. Verifique se a notificação foi enviada
```

### Teste 3: Trigger de Novo Evento

```sql
-- 1. Crie um evento
INSERT INTO eventos (titulo, data_inicio, ...)
VALUES ('Retiro Espiritual', '2024-12-31', ...);

-- 2. Todos os usuários com token FCM devem receber notificação
```

---

## 📝 Código Flutter (Minimalista)

### Antes (Código Duplicado)

```dart
// ❌ ERRADO: Flutter precisa chamar notificação
Future<void> criarAgendamento(Agendamento agendamento) async {
  // 1. Salvar no banco
  await Supabase.instance.client
      .from('agendamentos')
      .insert(agendamento.toMap());
  
  // 2. Buscar token FCM
  final profissional = await Supabase.instance.client
      .from('profiles')
      .select('fcm_token')
      .eq('id', agendamento.profissionalId)
      .single();
  
  // 3. Enviar notificação
  await ServicoNotificacoes().enviarNotificacao(
    profissional['fcm_token'],
    'Novo Agendamento',
    '...',
  );
}
```

### Depois (Código Limpo)

```dart
// ✅ CORRETO: Apenas salva no banco
Future<void> criarAgendamento(Agendamento agendamento) async {
  await Supabase.instance.client
      .from('agendamentos')
      .insert(agendamento.toMap());
  
  // Trigger cuida do resto automaticamente!
}
```

---

## 🎯 Quando Usar Cada Abordagem

### Use Triggers + Edge Functions Quando:
- ✅ Notificações automáticas (novo agendamento, cancelamento)
- ✅ Notificações para múltiplos usuários (novo evento, serviço)
- ✅ Quer código Flutter limpo
- ✅ Quer centralizar lógica no backend

### Use Chamada Direta do Flutter Quando:
- ⚠️ Notificação customizada (dados específicos do contexto)
- ⚠️ Notificação condicional (depende de lógica complexa)
- ⚠️ Notificação de teste (desenvolvimento)

---

## 🐛 Troubleshooting

### Trigger não está disparando

**Verificar:**
1. Trigger foi criado: `SELECT * FROM information_schema.triggers;`
2. Extensão net está habilitada: `SELECT * FROM pg_extension WHERE extname = 'net';`
3. Logs do Supabase: Database → Logs

**Solução:**
```sql
-- Verificar se o trigger existe
SELECT tgname, tgrelid::regclass 
FROM pg_trigger 
WHERE tgname = 'trigger_novo_agendamento';

-- Recriar trigger se necessário
DROP TRIGGER IF EXISTS trigger_novo_agendamento ON public.agendamentos;
-- (execute o SQL do arquivo TRIGGERS_NOTIFICACOES.sql novamente)
```

### Edge Function não está sendo chamada

**Verificar:**
1. Função foi implantada: `supabase functions list`
2. URL está correta no trigger
3. Service Role Key está correta
4. Logs da Edge Function: Functions → Logs

**Solução:**
```bash
# Verificar funções implantadas
supabase functions list

# Ver logs
supabase functions logs enviar-notificacao

# Reimplantar se necessário
supabase functions deploy enviar-notificacao
```

### Notificação não chega

**Verificar:**
1. Token FCM é válido: `SELECT fcm_token FROM profiles WHERE id = '...';`
2. App tem permissão de notificações
3. Firebase está configurado corretamente
4. Logs da Edge Function (deve ter resposta do FCM)

**Solução:**
```sql
-- Verificar token
SELECT id, email, fcm_token 
FROM public.profiles 
WHERE fcm_token IS NOT NULL;

-- Limpar token e pedir para fazer login novamente
UPDATE public.profiles SET fcm_token = NULL WHERE id = '...';
```

---

## 📚 Recursos

- [Supabase Triggers](https://supabase.com/docs/guides/database/postgres/triggers)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [PostgreSQL net Extension](https://supabase.com/docs/guides/database/extensions/pgsodium)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)

---

## ✅ Checklist de Implementação

- [ ] Firebase configurado (google-services.json)
- [ ] Edge Function implantada
- [ ] Triggers criados no Supabase
- [ ] Extensão net habilitada
- [ ] Tokens FCM sendo salvos
- [ ] App recebe notificações
- [ ] Testado com app aberto
- [ ] Testado com app fechado
- [ ] Logs verificados

---

## 🎉 Conclusão

Esta arquitetura oferece:
- **Automação total**: Triggers disparam automaticamente
- **Código limpo**: Flutter apenas CRUD
- **Escalabilidade**: Edge Functions serverless
- **Confiabilidade**: FCM garante entrega
- **Manutenibilidade**: Fácil modificar e expandir

**É a arquitetura ideal para o DESIADET!** 🚀