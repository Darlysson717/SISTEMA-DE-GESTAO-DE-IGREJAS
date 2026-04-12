-- DEBUG DETALHADO DO AGENDAMENTO

-- 1. Verificar se há professional_availabilities
SELECT
  pa.id,
  pa.professional_id,
  p.full_name,
  pa.day_of_week,
  CASE pa.day_of_week
    WHEN 0 THEN 'Domingo'
    WHEN 1 THEN 'Segunda'
    WHEN 2 THEN 'Terça'
    WHEN 3 THEN 'Quarta'
    WHEN 4 THEN 'Quinta'
    WHEN 5 THEN 'Sexta'
    WHEN 6 THEN 'Sábado'
  END as dia_semana,
  pa.start_time,
  pa.end_time,
  pa.created_at
FROM professional_availabilities pa
JOIN profiles p ON pa.professional_id = p.id
ORDER BY pa.professional_id, pa.day_of_week, pa.start_time;

-- 2. Verificar serviços aprovados
SELECT
  s.id,
  s.user_id,
  p.full_name,
  s.nome,
  s.status,
  s.dias_disponiveis,
  s.horarios,
  s.created_at
FROM servicos s
JOIN profiles p ON s.user_id = p.id
WHERE s.status = 'aprovado'
ORDER BY s.created_at DESC;

-- 3. Simular validação manual
-- Pegar dados de exemplo
SELECT 'Exemplo de availability:' as info,
  professional_id, day_of_week, start_time, end_time
FROM professional_availabilities
LIMIT 1;

-- 4. Testar se o trigger de criação está funcionando
-- Verificar logs do trigger (se houver)
SELECT
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trg_create_availabilities_on_service_approval';

-- 5. Verificar se há conflitos de constraint
SELECT
  professional_id,
  day_of_week,
  start_time,
  end_time,
  COUNT(*) as count
FROM professional_availabilities
GROUP BY professional_id, day_of_week, start_time, end_time
HAVING COUNT(*) > 1;