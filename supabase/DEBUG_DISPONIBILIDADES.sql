-- VERIFICAR DISPONIBILIDADES DOS PROFISSIONAIS
SELECT
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
  pa.end_time
FROM professional_availabilities pa
JOIN profiles p ON pa.professional_id = p.id
ORDER BY pa.professional_id, pa.day_of_week;

-- VERIFICAR AGENDAMENTOS RECENTES
SELECT
  a.id,
  a.professional_id,
  p.full_name as profissional,
  a.starts_at,
  a.ends_at,
  a.status,
  EXTRACT(DOW FROM a.starts_at AT TIME ZONE 'America/Sao_Paulo') as dow_local,
  a.starts_at AT TIME ZONE 'America/Sao_Paulo' as start_local,
  a.ends_at AT TIME ZONE 'America/Sao_Paulo' as end_local
FROM appointments a
JOIN profiles p ON a.professional_id = p.id
ORDER BY a.created_at DESC
LIMIT 10;