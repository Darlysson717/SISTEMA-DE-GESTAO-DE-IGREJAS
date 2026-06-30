# Arquitetura Final - Notificações Push DESIADET

## 🎯 Arquitetura Simplificada

```
┌─────────────┐
│   Flutter   │  (App)
│   (Front)   │
└──────┬──────┘
       │
       │ 1. Cria/edita/cancela agendamento
       │ 2. Chama Edge Function
       ▼
┌─────────────┐
│   Supabase  │  (Backend)
│  Edge Func  │
└──────┬──────┘
       │
       │ 3. Envia notificação via FCM
       ▼
┌─────────────┐
│     FCM     │  (Firebase)
│  (Push)     │
└──────┬──────┘
       │
       │ 4. Entrega ao dispositivo
       ▼
┌─────────────┐
│    App      │  (Notificação recebida)
│  (Flutter)  │
└─────────────┘
```

---

## ✅ Por Que Esta Arquitetura?

### Problema com Triggers
- ❌ Extensão `net` não disponível no Supabase
- ❌ Triggers não podem fazer chamadas HTTP
- ❌ Complexidade desnecessária

### Solução: Flutter → Edge Function
- ✅ Mais simples
- ✅ Controle total no Flutter
- ✅ Fácil de testar e debugar
- ✅ Sem dependências de extensões PostgreSQL
- ✅ Mais flexível

---

## 📋 Como Funciona

### 1. Usuário cria agendamento no app

```dart
Future<void> criarAgendamento(Agendamento agendamento) async {
  // 1. Salvar no banco
  await Supabase.instance.client
      .from('appointments')
      .insert(agendamento.toMap());
  
  // 2. Buscar token FCM do profissional
  final profissional = await Supabase.instance.client
      .from('professional_profiles')
      .select('fcm_token')
      .eq('user_id', agendamento.professionalId)
      .single();
  
  // 3. Enviar notificação via Edge Function
  if (profissional['fcm_token'] != null) {
    await Supabase.instance.client.functions.invoke(
      'enviar-notificacao',
      body: {
        'tokenFcm': profissional['fcm_token'],
        'titulo': 'Novo Agendamento',
        'corpo': 'Você tem um novo agendamento',
        'dados': {
          'tipo': 'novo_agendamento',
          'appointment_id': agendamento.id,
        },
      },
    );
  }
}
```

### 2. Edge Function recebe e envia notificação

```typescript
// 1. Recebe requisição do Flutter
const { tokenFcm, titulo, corpo, dados } = await req.json()

// 2. Autentica com Service Account (OAuth 2.0)
const accessToken = await getAccessToken(clientEmail, privateKey)

// 3. Envia notificação via FCM
const response = await fetch(url, {
  headers: {
    'Authorization': `Bearer ${accessToken}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(mensagem)
})
```

### 3. FCM entrega ao dispositivo

- App em foreground: Notificação aparece na barra
- App em background: Notificação aparece na barra
- App fechado: Notificação aparece na barra

---

## 🚀 Vantagens Desta Arquitetura

### 1. Simplicidade
- Código direto e fácil de entender
- Sem triggers complexos
- Sem extensões PostgreSQL

### 2. Controle
- Flutter controla quando enviar notificações
- Fácil adicionar lógica customizada
- Fácil debugar

### 3. Flexibilidade
- Fácil modificar mensagens
- Fácil adicionar novos tipos de notificação
- Fácil testar

### 4. Manutenibilidade
- Código centralizado no Flutter
- Fácil de modificar
- Fácil de expandir

---

## 📊 Comparação: Antes vs Depois

### Antes (com Triggers)
```
Flutter → Supabase → Trigger → HTTP → Edge Function → FCM
```

**Problemas:**
- ❌ Extensão `net` não disponível
- ❌ Complexo
- ❌ Difícil de debugar
- ❌ Não funciona

### Depois (sem Triggers)
```
Flutter → Supabase → Edge Function → FCM
```

**Vantagens:**
- ✅ Funciona perfeitamente
- ✅ Simples
- ✅ Fácil de debugar
- ✅ Controlado pelo Flutter

---

## 🔧 Implementação

### 1. Edge Function (Backend)

**Arquivo:** `supabase/functions/enviar-notificacao/index.ts`

```typescript
// Autenticação com Service Account (OAuth 2.0)
const accessToken = await getAccessToken(clientEmail, privateKey)

// Enviar notificação
const response = await fetch(url, {
  headers: {
    'Authorization': `Bearer ${accessToken}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(mensagem)
})
```

### 2. Flutter (Frontend)

**Arquivo:** `lib/src/nucleo/notificacoes/servico_notificacoes.dart`

```dart
Future<void> enviarNotificacao(String tokenFcm, String titulo, String corpo) async {
  await Supabase.instance.client.functions.invoke(
    'enviar-notificacao',
    body: {
      'tokenFcm': tokenFcm,
      'titulo': titulo,
      'corpo': corpo,
    },
  );
}
```

### 3. Uso no App

```dart
// Quando criar agendamento
Future<void> criarAgendamento(Agendamento agendamento) async {
  // 1. Salvar no banco
  await Supabase.instance.client
      .from('appointments')
      .insert(agendamento.toMap());
  
  // 2. Buscar profissional
  final profissional = await Supabase.instance.client
      .from('professional_profiles')
      .select('fcm_token')
      .eq('user_id', agendamento.professionalId)
      .single();
  
  // 3. Enviar notificação
  if (profissional['fcm_token'] != null) {
    await ServicoNotificacoes().enviarNotificacao(
      profissional['fcm_token'],
      'Novo Agendamento',
      'Você tem um novo agendamento',
    );
  }
}
```

---

## 🔐 Segurança

### Service Account (OAuth 2.0)

```bash
# Configurar secrets
supabase secrets set FIREBASE_CLIENT_EMAIL=...
supabase secrets set FIREBASE_PRIVATE_KEY=...
supabase secrets set PROJECT_ID=app-iadet
```

**Vantagens:**
- ✅ Autenticação correta (OAuth 2.0)
- ✅ Secrets criptografados
- ✅ Sem chaves expostas
- ✅ Método recomendado pelo Google

---

## ✅ Checklist Final

- [x] Firebase configurado
- [x] Edge Function criada
- [x] Service Account configurada
- [x] Secrets configurados
- [x] Flutter pode chamar Edge Function
- [x] Notificações funcionando
- [x] Documentação completa

---

## 🎯 Conclusão

**Arquitetura final:**
- ✅ Simples e direta
- ✅ Sem dependências complexas
- ✅ Controle total no Flutter
- ✅ Fácil de manter
- ✅ Segura (Service Account + Secrets)

**Pronto para usar!** 🚀