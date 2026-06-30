# Edge Function: Enviar Notificação Push

Esta Edge Function do Supabase envia notificações push via Firebase Cloud Messaging de forma IMEDIATA (sem o atraso de 1-2 minutos do Firebase Console).

## 🚀 Vantagens

- ✅ **Entrega imediata** (até 10 segundos)
- ✅ **Sem atraso** do Firebase Console
- ✅ **Integrado com Supabase** (mesma plataforma)
- ✅ **Fácil de chamar** via HTTP POST
- ✅ **Gratuito** (até 500k invocações/mês no plano gratuito)

## 📋 Pré-requisitos

1. Projeto Supabase criado
2. Firebase configurado (google-services.json já adicionado)
3. Token FCM do usuário salvo no Supabase

## 🔧 Implantação

### 1. Instale a CLI do Supabase

```bash
npm install -g supabase
```

### 2. Faça login no Supabase

```bash
supabase login
```

### 3. Link com seu projeto

```bash
supabase link --project-ref SEU_PROJECT_ID
```

Para encontrar o PROJECT_ID:
- Acesse https://app.supabase.com/
- Vá em Settings → General
- Copie o "Reference ID"

### 4. Implante a função

```bash
supabase functions deploy enviar-notificacao
```

### 5. Teste a função

```bash
curl -X POST \
  'https://SEU_PROJECT_ID.supabase.co/functions/v1/enviar-notificacao' \
  -H 'Authorization: Bearer SEU_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "tokenFcm": "TOKEN_FCM_AQUI",
    "titulo": "TESTE",
    "corpo": "Notificação de teste"
  }'
```

## 📱 Como Usar no App Flutter

### Opção 1: Chamar diretamente do Flutter

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> enviarNotificacao(String tokenFcm, String titulo, String corpo) async {
  try {
    final response = await Supabase.instance.client.functions.invoke(
      'enviar-notificacao',
      body: {
        'tokenFcm': tokenFcm,
        'titulo': titulo,
        'corpo': corpo,
      },
    );

    if (response.status == 200) {
      print('Notificação enviada: ${response.data}');
    } else {
      print('Erro: ${response.data}');
    }
  } catch (e) {
    print('Erro ao enviar notificação: $e');
  }
}
```

### Opção 2: Chamar via HTTP direto

```dart
import 'package:http/http.dart' as http;

Future<void> enviarNotificacao(String tokenFcm, String titulo, String corpo) async {
  final url = Uri.parse('https://SEU_PROJECT_ID.supabase.co/functions/v1/enviar-notificacao');
  
  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer SEU_ANON_KEY',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'tokenFcm': tokenFcm,
      'titulo': titulo,
      'corpo': corpo,
    }),
  );

  if (response.statusCode == 200) {
    print('Notificação enviada!');
  } else {
    print('Erro: ${response.body}');
  }
}
```

## 🔐 Segurança

### Importante: Proteja a função!

A função está aberta (qualquer pessoa pode chamar). Para proteger:

1. **Adicione verificação de JWT** (recomendado):
```typescript
// Verificar se o usuário está autenticado
const authHeader = req.headers.get('Authorization')
if (!authHeader) {
  return new Response(JSON.stringify({ error: 'Não autorizado' }), { status: 401 })
}

// Verificar token JWT do Supabase
const token = authHeader.replace('Bearer ', '')
const { data: { user } } = await supabase.auth.getUser(token)

if (!user) {
  return new Response(JSON.stringify({ error: 'Não autorizado' }), { status: 401 })
}
```

2. **Ou use Service Role Key** (mais seguro):
- Use a Service Role Key no app (não a Anon Key)
- Apenas o backend tem acesso à Service Role Key

## 📊 Exemplo de Uso no App

```dart
// Quando criar um agendamento
Future<void> criarAgendamento(Agendamento agendamento) async {
  // 1. Salvar agendamento no Supabase
  await Supabase.instance.client
      .from('agendamentos')
      .insert(agendamento.toMap());

  // 2. Buscar token FCM do profissional
  final profissional = await Supabase.instance.client
      .from('profiles')
      .select('fcm_token')
      .eq('id', agendamento.profissionalId)
      .single();

  final tokenFcm = profissional['fcm_token'];

  // 3. Enviar notificação IMEDIATA
  if (tokenFcm != null) {
    await enviarNotificacao(
      tokenFcm,
      'Novo Agendamento',
      'Você tem um novo agendamento!',
    );
  }
}
```

## 🎯 Vantagens vs Firebase Console

| Recurso | Firebase Console | Edge Function |
|---------|-----------------|---------------|
| Velocidade | 1-2 minutos | Imediato (até 10s) |
| Custo | Gratuito | Gratuito (até 500k/mês) |
| Integração | Manual | Automática com Supabase |
| Controle | Limitado | Total |
| Logs | Limitado | Completo |

## 📝 Notas

- A função usa a API HTTP v1 do Firebase (a mais nova)
- Prioridade ALTA configurada
- Canal de notificação correto (`high_importance_channel`)
- Suporte para Android e iOS
- Dados customizados opcionais

## 🐛 Troubleshooting

### Erro 401 (Não autorizado)
- Verifique se a API Key está correta
- Verifique se o token FCM é válido

### Erro 404 (Not found)
- Verifique se a função foi implantada
- Verifique se a URL está correta

### Notificação não chega
- Verifique se o app tem permissão de notificações
- Verifique se o token FCM é válido
- Verifique os logs da Edge Function no Supabase Dashboard

## 📚 Recursos

- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Firebase Cloud Messaging HTTP v1](https://firebase.google.com/docs/cloud-messaging/send-message)
- [Documentação da API](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages)