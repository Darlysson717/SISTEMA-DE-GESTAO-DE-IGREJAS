-- Tabela de configurações do aplicativo
-- Usada para armazenar configurações globais como versão mínima obrigatória
CREATE TABLE IF NOT EXISTS app_config (
  id BIGINT PRIMARY KEY DEFAULT 1,
  min_version TEXT NOT NULL DEFAULT '1.0.0',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT single_row CHECK (id = 1)
);

-- Insere a configuração padrão se não existir
INSERT INTO app_config (id, min_version)
VALUES (1, '1.0.0')
ON CONFLICT (id) DO NOTHING;

-- Função para atualizar a versão mínima
CREATE OR REPLACE FUNCTION atualizar_versao_minima(nova_versao TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE app_config
  SET min_version = nova_versao, updated_at = NOW()
  WHERE id = 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Política de segurança: qualquer usuário autenticado pode ler
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Qualquer um pode ler configurações"
  ON app_config
  FOR SELECT
  USING (true);

CREATE POLICY "Apenas admin pode alterar configurações"
  ON app_config
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );
