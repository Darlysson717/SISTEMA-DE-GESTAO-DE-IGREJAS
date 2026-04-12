-- DEBUG: VERIFICAR COMO A FUNÇÃO INTERPRETA HORÁRIOS

-- Verificar o timestamp UTC e conversão para SP
SELECT
  '2026-03-03 14:30:00+00'::TIMESTAMPTZ as utc_timestamp,
  '2026-03-03 14:30:00+00'::TIMESTAMPTZ at time zone 'America/Sao_Paulo' as sp_timestamp,
  extract(dow from '2026-03-03 14:30:00+00'::TIMESTAMPTZ at time zone 'America/Sao_Paulo') as dow_sp;

-- Verificar se existe availability para esse dia/horário
SELECT
  pa.day_of_week,
  pa.start_time,
  pa.end_time,
  CASE pa.day_of_week
    WHEN 0 THEN 'Domingo'
    WHEN 1 THEN 'Segunda'
    WHEN 2 THEN 'Terça'
    WHEN 3 THEN 'Quarta'
    WHEN 4 THEN 'Quinta'
    WHEN 5 THEN 'Sexta'
    WHEN 6 THEN 'Sábado'
  END as dia_semana
FROM professional_availabilities pa
WHERE pa.professional_id = '97ac3170-9795-4874-8e62-9143104e41ea'
  AND pa.day_of_week = 1; -- Segunda-feira

-- Verificar se o horário 11:30-12:00 SP está dentro de 11:12-12:12
SELECT
  '11:30:00'::time as requested_start,
  '12:00:00'::time as requested_end,
  '11:12:00'::time as available_start,
  '12:12:00'::time as available_end,
  '11:30:00'::time >= '11:12:00'::time as start_ok,
  '12:00:00'::time <= '12:12:00'::time as end_ok;