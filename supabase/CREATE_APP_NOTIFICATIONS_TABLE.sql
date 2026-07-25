-- ============================================
-- TABELA DE NOTIFICAÇÕES IN-APP
-- ============================================
-- Armazena notificações para exibição dentro do app
-- Cada notificação é vinculada a um usuário específico
-- ============================================

CREATE TABLE IF NOT EXISTS app_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  titulo TEXT NOT NULL,
  corpo TEXT NOT NULL,
  tipo TEXT, -- ex: 'agendamento', 'evento', 'sistema'
  dados TEXT, -- JSON com dados adicionais
  lida BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índice para buscar notificações de um usuário ordenadas por data
CREATE INDEX IF NOT EXISTS idx_app_notifications_user_id_created_at
  ON app_notifications(user_id, created_at DESC);

-- Índice para contar notificações não lidas de um usuário
CREATE INDEX IF NOT EXISTS idx_app_notifications_user_id_lida
  ON app_notifications(user_id, lida)
  WHERE lida = false;

-- Permissões: usuários só podem ver/alterar suas próprias notificações
ALTER TABLE app_notifications ENABLE ROW LEVEL SECURITY;

-- Política: usuário pode ver apenas suas próprias notificações
CREATE POLICY "Usuários veem suas próprias notificações"
  ON app_notifications
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Política: usuário pode atualizar apenas suas próprias notificações
CREATE POLICY "Usuários atualizam suas próprias notificações"
  ON app_notifications
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

-- Política: usuário pode deletar apenas suas próprias notificações
CREATE POLICY "Usuários deletam suas próprias notificações"
  ON app_notifications
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Política: sistema pode inserir notificações para qualquer usuário
CREATE POLICY "Sistema pode inserir notificações"
  ON app_notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (true);