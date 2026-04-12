-- TESTAR FUNCIONAMENTO APÓS SIMPLIFICAÇÃO

-- 1. Verificar serviços aprovados
SELECT id, nome, categoria, status, user_id
FROM servicos
WHERE status = 'aprovado'
ORDER BY created_at DESC
LIMIT 5;

-- 2. Verificar se há professional_availabilities
SELECT pa.professional_id, p.full_name, pa.day_of_week, pa.start_time, pa.end_time
FROM professional_availabilities pa
JOIN profiles p ON pa.professional_id = p.id
ORDER BY pa.professional_id, pa.day_of_week;

-- 3. Testar criação de agendamento (simular)
-- Primeiro, pegar IDs de teste
SELECT 'User ID disponível:' as info, id, email FROM profiles LIMIT 1;
SELECT 'Serviço aprovado disponível:' as info, id, nome, user_id FROM servicos WHERE status = 'aprovado' LIMIT 1;

-- 4. Verificar se as políticas RLS estão funcionando
-- (estas consultas devem funcionar se o usuário estiver autenticado)
SELECT id, email FROM profiles WHERE id = auth.uid();
SELECT id, nome FROM servicos WHERE user_id = auth.uid();

-- 5. Verificar trigger de criação automática
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers
WHERE trigger_name = 'trg_create_availabilities_on_service_approval';