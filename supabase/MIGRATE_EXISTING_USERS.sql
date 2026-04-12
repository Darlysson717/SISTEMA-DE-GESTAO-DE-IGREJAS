-- ATUALIZAR USUÁRIOS EXISTENTES APÓS SIMPLIFICAÇÃO
-- Este script deve ser executado APÓS o SIMPLIFY_USERS_SYSTEM.sql

-- 1. Verificar usuários existentes antes da mudança
SELECT id, email, full_name, role FROM profiles LIMIT 10;

-- 2. Como removemos a coluna role, não há mais necessidade de atualizar
-- Todos os novos usuários terão role = 'community' por padrão

-- 3. Verificar se as políticas estão funcionando
-- Tentar fazer uma consulta simples
SELECT COUNT(*) FROM profiles;
SELECT COUNT(*) FROM servicos WHERE status = 'aprovado';

-- 4. Testar criação de disponibilidade automática
-- Aprove um serviço existente para testar
-- UPDATE servicos SET status = 'aprovado' WHERE id = 'SEU_SERVICE_ID' AND status = 'pendente';

-- 5. Verificar se as availabilities foram criadas
-- SELECT * FROM professional_availabilities ORDER BY created_at DESC LIMIT 5;