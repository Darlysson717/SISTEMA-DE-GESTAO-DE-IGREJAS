# Integrar Edge Function no Flutter

## 🎯 Situação Atual

- ✅ Edge Function ATIVA e funcionando
- ✅ Secrets configurados
- ✅ Apenas falta chamar a função no Flutter

---

## 📋 O que Fazer

### 1. Adicionar Código ao Criar Agendamento

Encontre onde você cria agendamentos no Flutter e adicione:

```dart
Future<void> criarAgendamento(Agendamento agendamento) async {
  try {
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

    // 3. Enviar notificação (NOVO!)
    final tokenFcm = profissional['fcm_token'];
    if (tokenFcm != null) {
      await Supabase.instance.client.functions.invoke(
        'enviar-notificacao',
        body: {
          'tokenFcm': tokenFcm,
          'titulo': 'Novo Agendamento',
          'corpo': 'Você tem um novo agendamento',
          'dados': {
            'tipo': 'novo_agendamento',
            'appointment_id': agendamento.id,
          },
        },
      );
    }

    // 4. Mostrar mensagem de sucesso
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Agendamento criado com sucesso!')),
    );

  } catch (e) {
    // Tratar erro
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro: $e')),
    );
  }
}
```

---

### 2. Adicionar Código ao Cancelar Agendamento

```dart
Future<void> cancelarAgendamento(String appointmentId, String professionalId) async {
  try {
    // 1. Atualizar status no banco
    await Supabase.instance.client
        .from('appointments')
        .update({'status': 'cancelled'})
        .eq('id', appointmentId);

    // 2. Buscar token FCM do profissional
    final profissional = await Supabase.instance.client
        .from('professional_profiles')
        .select('fcm_token')
        .eq('user_id', professionalId)
        .single();

    // 3. Enviar notificação (NOVO!)
    final tokenFcm = profissional['fcm_token'];
    if (tokenFcm != null) {
      await Supabase.instance.client.functions.invoke(
        'enviar-notificacao',
        body: {
          'tokenFcm': tokenFcm,
          'titulo': 'Agendamento Cancelado',
          'corpo': 'Um agendamento foi cancelado',
          'dados': {
            'tipo': 'cancelamento_agendamento',
            'appointment_id': appointmentId,
          },
        },
      );
    }

    // 4. Mostrar mensagem
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Agendamento cancelado!')),
    );

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro: $e')),
    );
  }
}
```

---

### 3. Adicionar Código ao Criar Evento (se existir)

```dart
Future<void> criarEvento(Evento evento) async {
  try {
    // 1. Salvar no banco
    await Supabase.instance.client
        .from('events')
        .insert(evento.toMap());

    // 2. Buscar TODOS os usuários com token FCM
    final usuarios = await Supabase.instance.client
        .from('profiles')
        .select('fcm_token')
        .not('fcm_token', 'is', null);

    // 3. Enviar notificação para cada usuário
    for (var usuario in usuarios) {
      final tokenFcm = usuario['fcm_token'];
      if (tokenFcm != null) {
        await Supabase.instance.client.functions.invoke(
          'enviar-notificacao',
          body: {
            'tokenFcm': tokenFcm,
            'titulo': 'Novo Evento',
            'corpo': evento.titulo,
            'dados': {
              'tipo': 'novo_evento',
              'evento_id': evento.id,
            },
          },
        );
      }
    }

  } catch (e) {
    print('Erro: $e');
  }
}
```

---

### 4. Adicionar Código ao Criar Serviço (se existir)

```dart
Future<void> criarServico(Servico servico) async {
  try {
    // 1. Salvar no banco
    await Supabase.instance.client
        .from('services')
        .insert(servico.toMap());

    // 2. Buscar TODOS os usuários com token FCM
    final usuarios = await Supabase.instance.client
        .from('profiles')
        .select('fcm_token')
        .not('fcm_token', 'is', null);

    // 3. Enviar notificação para cada usuário
    for (var usuario in usuarios) {
      final tokenFcm = usuario['fcm_token'];
      if (tokenFcm != null) {
        await Supabase.instance.client.functions.invoke(
          'enviar-notificacao',
          body: {
            'tokenFcm': tokenFcm,
            'titulo': 'Novo Serviço',
            'corpo': servico.nome,
            'dados': {
              'tipo': 'novo_servico',
              'servico_id': servico.id,
            },
          },
        );
      }
    }

  } catch (e) {
    print('Erro: $e');
  }
}
```

---

## 🧪 Testar

### 1. Executar o App
```bash
flutter run
```

### 2. Criar um Agendamento de Teste
- Abra o app
- Crie um novo agendamento
- Verifique se o profissional recebe a notificação

### 3. Verificar Logs (se não funcionar)
```bash
# Terminal 1: Logs da Edge Function
supabase functions logs enviar-notificacao --follow

# Terminal 2: Executar o app
flutter run
```

---

## ✅ Resultado Esperado

Quando você criar um agendamento:
1. ✅ Agendamento salvo no Supabase
2. ✅ Edge Function é chamada
3. ✅ Notificação enviada via FCM
4. ✅ Profissional recebe em até 10 segundos

---

## 🎯 Pronto!

Agora você tem:
- ✅ Notificações IMEDIATAS
- ✅ Sistema 100% automático
- ✅ Código limpo e simples

**Boa implementação!** 🚀