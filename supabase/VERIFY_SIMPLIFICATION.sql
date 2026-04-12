-- VERIFICAR SE A SIMPLIFICAÇÃO FOI APLICADA CORRETAMENTE

-- 1. Verificar se a coluna role foi removida
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'profiles' AND column_name = 'role';

-- 2. Verificar se a tabela professional_profiles foi removida
SELECT table_name
FROM information_schema.tables
WHERE table_name = 'professional_profiles';

-- 3. Verificar políticas atuais das tabelas
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 4. Verificar se a função de criação automática existe
SELECT routine_name
FROM information_schema.routines
WHERE routine_name = 'create_professional_availabilities_on_service_approval';

-- 5. Verificar estrutura das tabelas principais
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('profiles', 'servicos', 'professional_availabilities', 'appointments')
ORDER BY table_name, ordinal_position;

-- 6. Testar consulta básica
SELECT COUNT(*) as total_users FROM profiles;
SELECT COUNT(*) as total_services FROM servicos;
SELECT COUNT(*) as total_availabilities FROM professional_availabilities;