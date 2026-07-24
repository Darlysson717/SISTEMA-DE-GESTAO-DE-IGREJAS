-- Tabela para gerenciar versões do app
CREATE TABLE IF NOT EXISTS app_versions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  version TEXT NOT NULL,           -- Ex: "1.0.0"
  build_number INTEGER NOT NULL,   -- Ex: 1
  version_full TEXT GENERATED ALWAYS AS (version || '+' || build_number) STORED,
  apk_download_url TEXT NOT NULL,  -- URL para download (pode ser externa)
  apk_file_name TEXT,
  changelog TEXT,
  is_mandatory BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  released_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice para buscar rapidamente a versão mais recente
CREATE INDEX IF NOT EXISTS idx_app_versions_active ON app_versions(is_active, released_at DESC);

-- Comentários
COMMENT ON TABLE app_versions IS 'Armazena informações de versões do aplicativo para atualizações';
COMMENT ON COLUMN app_versions.version IS 'Versão semântica (ex: 1.0.0)';
COMMENT ON COLUMN app_versions.build_number IS 'Número do build (ex: 1, 2, 3)';
COMMENT ON COLUMN app_versions.apk_download_url IS 'URL direta para download do APK (pode ser Google Drive, Dropbox, Firebase Storage, etc.)';
COMMENT ON COLUMN app_versions.changelog IS 'Lista de mudanças da versão';
COMMENT ON COLUMN app_versions.is_mandatory IS 'Se true, força atualização obrigatória';
COMMENT ON COLUMN app_versions.is_active IS 'Se false, a versão não é mais exibida';

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_app_versions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Dropar trigger se já existir (para evitar erro)
DROP TRIGGER IF EXISTS trigger_update_app_versions_updated_at ON app_versions;

CREATE TRIGGER trigger_update_app_versions_updated_at
  BEFORE UPDATE ON app_versions
  FOR EACH ROW
  EXECUTE FUNCTION update_app_versions_updated_at();

-- Política RLS (opcional, mas recomendado)
ALTER TABLE app_versions ENABLE ROW LEVEL SECURITY;

-- Dropar políticas se já existirem (para evitar erro)
DROP POLICY IF EXISTS "Permitir leitura pública de app_versions" ON app_versions;
DROP POLICY IF EXISTS "Permitir modificação para admins" ON app_versions;

-- Permitir leitura pública (qualquer pessoa pode verificar atualizações)
CREATE POLICY "Permitir leitura pública de app_versions"
  ON app_versions
  FOR SELECT
  USING (is_active = true);

-- Permitir inserção/atualização apenas para admins (via service_role)
CREATE POLICY "Permitir modificação para admins"
  ON app_versions
  FOR ALL
  USING (false)  -- Negar acesso via cliente
  WITH CHECK (false);

-- Inserir uma versão de exemplo
INSERT INTO app_versions (
  version,
  build_number,
  apk_download_url,
  apk_file_name,
  changelog,
  is_mandatory,
  is_active
) VALUES (
  '1.0.0',
  1,
  'https://github.com/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS/releases/download/v1.0.0/app-v1.0.0.apk',
  'app-v1.0.0.apk',
  '### Nova versão 1.0.0
- Correção de bugs no calendário
- Melhorias na interface
- Performance otimizada',
  false,
  true
) ON CONFLICT DO NOTHING;