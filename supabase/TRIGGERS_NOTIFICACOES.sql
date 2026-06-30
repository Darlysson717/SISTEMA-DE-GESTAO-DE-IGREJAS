-- ============================================
-- TRIGGERS PARA NOTIFICAÇÕES AUTOMÁTICAS
-- ============================================
-- NOTA: Os triggers que faziam chamadas HTTP foram removidos
-- porque a extensão 'net' não está disponível no Supabase.
-- 
-- As notificações agora são enviadas diretamente do Flutter
-- usando a Edge Function 'enviar-notificacao'.
-- ============================================

-- ============================================
-- TRIGGERS REMOVIDOS
-- ============================================
-- Os triggers abaixo foram removidos porque dependiam
-- da extensão 'net' que não está disponível:
--
-- - trigger_novo_agendamento
-- - trigger_cancelamento_agendamento
--
-- Alternativa: Chamar Edge Function diretamente do Flutter
-- ============================================

-- ============================================
-- COMO USAR AGORA
-- ============================================

/*
1. FLUTTER CHAMA EDGE FUNCTION DIRETAMENTE

   Quando criar/editar/cancelar agendamentos, o Flutter
   chama a Edge Function diretamente:
   
   await Supabase.instance.client.functions.invoke(
     'enviar-notificacao',
     body: {
       'tokenFcm': tokenFcm,
       'titulo': 'Novo Agendamento',
       'corpo': '...',
     },
   );

2. VANTAGENS DESTA ABORDAGEM

   - Não depende de extensões do PostgreSQL
   - Mais simples e direto
   - Controle total no Flutter
   - Fácil de debugar
   - Não precisa de triggers complexos

3. EXEMPLO DE USO NO FLUTTER

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

4. ARQUITETURA FINAL

   Flutter (cria agendamento)
     ↓
   Supabase (salva no banco)
     ↓
   Flutter (chama Edge Function)
     ↓
   Edge Function (envia notificação)
     ↓
   FCM (entrega ao dispositivo)

5. VANTAGENS

   ✅ Código mais simples
   ✅ Sem dependência de extensões PostgreSQL
   ✅ Controle total no Flutter
   ✅ Fácil de testar e debugar
   ✅ Mais flexível
*/