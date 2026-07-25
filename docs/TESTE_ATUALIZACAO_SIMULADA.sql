-- ============================================
-- TESTE DE ATUALIZAÇÃO SIMULADA
-- ============================================
-- Execute este script no Supabase SQL Editor para testar o sistema de atualizações
-- 
-- Cenário: Simular uma nova versão 1.4.0+2 para testar a funcionalidade
-- Versão atual do app: 1.3.0+1
-- ============================================

-- PASSO 1: Verificar versões atuais
SELECT 
  version, 
  build_number, 
  apk_download_url, 
  is_mandatory, 
  is_active, 
  released_at 
FROM app_versions 
ORDER BY released_at DESC;

-- ============================================
-- PASSO 2: Cadastrar nova versão de TESTE
-- ============================================
-- IMPORTANTE: Ajuste os valores conforme sua necessidade
-- Para teste real, substitua a URL pelo link do seu APK no GitHub

INSERT INTO app_versions (
  version,
  build_number,
  apk_download_url,
  apk_file_name,
  changelog,
  is_mandatory,
  is_active
) VALUES (
  '1.4.0',  -- Nova versão (MAIOR que 1.3.0)
  2,        -- Build number (MAIOR que 1)
  'https://github.com/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS/releases/download/v1.4.0/app-release.apk',
  'app-release.apk',
  '### Nova versão 1.4.0

**Novas funcionalidades:**
- Botão manual de verificação de atualizações na tela de perfil
- Sistema de atualização automática via Supabase
- Feedback visual durante verificação de atualizações

**Melhorias:**
- Interface do perfil atualizada
- Melhor experiência do usuário durante atualizações
- Mensagens mais claras sobre o status da versão

**Correções:**
- Pequenos ajustes de layout',
  false,  -- false = atualização opcional (usuário pode escolher não atualizar)
  true    -- true = versão ativa (esta é a versão mais recente)
);

-- ============================================
-- PASSO 3: Verificar se a versão foi cadastrada
-- ============================================
SELECT 
  version, 
  build_number, 
  is_mandatory, 
  is_active, 
  released_at 
FROM app_versions 
ORDER BY released_at DESC;

-- ============================================
-- PASSO 4: Testar a query que o app executa
-- ============================================
-- Esta é a query exata que o app usa para buscar a versão mais recente
SELECT 
  version,
  build_number,
  apk_download_url,
  apk_file_name,
  changelog,
  is_mandatory,
  is_active,
  released_at
FROM app_versions
WHERE is_active = true
ORDER BY released_at DESC
LIMIT 1;

-- ============================================
-- PASSO 5: (OPCIONAL) Desativar versões antigas
-- ============================================
-- Se quiser manter apenas a versão mais recente ativa:
UPDATE app_versions 
SET is_active = false 
WHERE version = '1.3.0' AND build_number = 1;

-- ============================================
-- PASSO 6: (OPCIONAL) Marcar como atualização obrigatória
-- ============================================
-- Se quiser que a atualização seja obrigatória (usuário não pode usar o app sem atualizar):
UPDATE app_versions 
SET is_mandatory = true 
WHERE version = '1.4.0' AND build_number = 2;

-- ============================================
-- PASSO 7: Verificar resultado final
-- ============================================
SELECT 
  version, 
  build_number, 
  is_mandatory, 
  is_active, 
  released_at 
FROM app_versions 
ORDER BY released_at DESC;

-- ============================================
-- COMO TESTAR NO APP
-- ============================================
-- 1. Execute este script no Supabase SQL Editor
-- 2. Abra o app (versão 1.3.0+1)
-- 3. O app irá:
--    - Consultar o Supabase
--    - Encontrar a versão 1.4.0+2 (maior que 1.3.0+1)
--    - Mostrar o overlay de atualização automaticamente
--    - OU você pode clicar em "Verificar Atualizações" na tela de perfil
-- 4. Clique em "Baixar v1.4.0+2" para testar o download
-- ============================================

-- ============================================
-- LIMPEZA (APÓS TESTE)
-- ============================================
-- Para remover a versão de teste após concluir:
-- DELETE FROM app_versions WHERE version = '1.4.0' AND build_number = 2;
-- ============================================