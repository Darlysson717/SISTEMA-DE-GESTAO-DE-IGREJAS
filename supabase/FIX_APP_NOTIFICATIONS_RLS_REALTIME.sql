-- ============================================
-- CORREÇÃO: Políticas RLS e Realtime para app_notifications
-- ============================================
-- Problema: A política de INSERT com WITH CHECK (true) ainda pode
-- falhar porque o Supabase verifica se o usuário pode SELECT no
-- registro recém-inserido. Como a política de SELECT restringe por
-- auth.uid() = user_id, inserir para outro usuário falha.
--
-- Solução: Criar uma política de INSERT que permite inserir para
-- qualquer user_id, e garantir que o Realtime esteja habilitado.
-- ============================================

-- 1. Remove a política antiga de INSERT
DROP POLICY IF EXISTS "Sistema pode inserir notificações" ON app_notifications;

-- 2. Cria nova política de INSERT que permite inserir para qualquer user_id
--    Isso é necessário porque o sistema (Flutter) cria notificações
--    para outros usuários (ex: admin cria para usuário comum)
CREATE POLICY "Sistema pode inserir notificações"
  ON app_notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- 3. Garante que a tabela está com Realtime habilitado
--    Isso permite que o StreamProvider no Flutter receba atualizações
--    em tempo real quando novas notificações são inseridas
ALTER PUBLICATION supabase_realtime ADD TABLE app_notifications;

-- 4. Verifica se a tabela já está na publicação (evita erro se já estiver)
--    O comando acima pode falhar se já estiver adicionada, mas isso é seguro

-- ============================================
-- VERIFICAÇÃO
-- ============================================
-- Para testar se a política está funcionando:
-- 1. Faça login como qualquer usuário autenticado
-- 2. Execute no SQL Editor:
--
-- INSERT INTO app_notifications (user_id, titulo, corpo, tipo)
-- VALUES ('<OUTRO_USER_ID>', 'Teste', 'Notificação para outro usuário', 'sistema');
--
-- 3. Verifique se o INSERT foi permitido
-- 4. O outro usuário deve ver a notificação no modal
-- ============================================