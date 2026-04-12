-- TESTAR AGENDAMENTO APÓS CRIAR AVAILABILITIES

-- 1. Verificar serviços aprovados e suas availabilities
SELECT
  s.id as service_id,
  s.nome as service_name,
  s.user_id as professional_id,
  p.full_name as professional_name,
  s.dias_disponiveis,
  s.horarios,
  COUNT(pa.id) as availabilities_count
FROM servicos s
JOIN profiles p ON s.user_id = p.id
LEFT JOIN professional_availabilities pa ON pa.professional_id = s.user_id
WHERE s.status = 'aprovado'
GROUP BY s.id, s.nome, s.user_id, p.full_name, s.dias_disponiveis, s.horarios
ORDER BY s.created_at DESC;

-- 2. Verificar se há conflitos de horário (mesmo profissional, mesmo dia/hora)
SELECT
  professional_id,
  day_of_week,
  start_time,
  end_time,
  COUNT(*) as overlapping_count
FROM professional_availabilities
GROUP BY professional_id, day_of_week, start_time, end_time
HAVING COUNT(*) > 1;

-- 3. Testar validação de agendamento (simular)
-- Pegar dados para teste
SELECT 'Serviços disponíveis:' as info, id, nome, user_id FROM servicos WHERE status = 'aprovado' LIMIT 1;
SELECT 'Availabilities criadas:' as info, professional_id, day_of_week, start_time, end_time FROM professional_availabilities LIMIT 5;

-- 4. Verificar se o trigger está ativo
SELECT
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trg_create_availabilities_on_service_approval';