-- SCRIPT PARA DIAGNOSTICAR PROBLEMA DE PERFIL
-- Execute este script no SQL Editor do Supabase

-- 1. VERIFICAR SE EXISTEM PERFIS
SELECT id, email, full_name, role, created_at FROM profiles LIMIT 10;

-- 2. VERIFICAR USUÁRIOS AUTENTICADOS RECENTES
SELECT id, email, created_at, last_sign_in_at FROM auth.users
ORDER BY created_at DESC LIMIT 5;

-- 3. SE O USUÁRIO NÃO TIVER PERFIL, CRIE MANUALMENTE:
-- (Substitua 'USER_ID_AQUI' pelo ID real do usuário)
-- INSERT INTO profiles (id, email, full_name, role)
-- VALUES ('USER_ID_AQUI', 'user@email.com', 'Nome Completo', 'community');

-- 4. VERIFICAR SERVIÇOS EXISTENTES
SELECT id, user_id, nome, status, created_at FROM servicos LIMIT 5;

-- 5. VERIFICAÇÃO GERAL
SELECT
  'Perfis: ' || (SELECT COUNT(*) FROM profiles)::text as perfis,
  'Serviços: ' || (SELECT COUNT(*) FROM servicos)::text as servicos,
  'Usuários auth: ' || (SELECT COUNT(*) FROM auth.users)::text as usuarios_auth;