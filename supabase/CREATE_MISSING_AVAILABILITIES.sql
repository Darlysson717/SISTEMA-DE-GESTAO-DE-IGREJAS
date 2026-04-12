-- CRIAR DISPONIBILIDADES PARA SERVIÇOS JÁ APROVADOS
-- Execute este script APÓS executar FIX_AVAILABILITIES_FK.sql
-- Versão corrigida para usar CROSS JOIN LATERAL com arrays

-- Limpar availabilities existentes para recriar (opcional)
-- DELETE FROM professional_availabilities;

-- Adicionar índice único se não existir (necessário para ON CONFLICT)
CREATE UNIQUE INDEX IF NOT EXISTS idx_professional_availabilities_unique
ON professional_availabilities (professional_id, day_of_week, start_time, end_time);

-- Inserir availabilities baseadas nos dias_disponiveis e horarios dos serviços aprovados
INSERT INTO public.professional_availabilities (
  professional_id,
  day_of_week,
  start_time,
  end_time
)
SELECT DISTINCT
  s.user_id as professional_id,
  CASE LOWER(TRIM(d.day_name))
    WHEN 'domingo' THEN 0
    WHEN 'segunda' THEN 1
    WHEN 'segunda-feira' THEN 1
    WHEN 'terça' THEN 2
    WHEN 'terça-feira' THEN 2
    WHEN 'quarta' THEN 3
    WHEN 'quarta-feira' THEN 3
    WHEN 'quinta' THEN 4
    WHEN 'quinta-feira' THEN 4
    WHEN 'sexta' THEN 5
    WHEN 'sexta-feira' THEN 5
    WHEN 'sábado' THEN 6
  END as day_of_week,
  (SPLIT_PART(TRIM(h.time_range), '-', 1) || ':00')::TIME as start_time,
  (SPLIT_PART(TRIM(h.time_range), '-', 2) || ':00')::TIME as end_time
FROM servicos s
CROSS JOIN LATERAL unnest(s.dias_disponiveis) AS d(day_name)
CROSS JOIN LATERAL unnest(s.horarios) AS h(time_range)
WHERE s.status = 'aprovado'
  AND array_length(s.dias_disponiveis, 1) > 0
  AND array_length(s.horarios, 1) > 0
  AND LOWER(TRIM(d.day_name)) IN ('domingo', 'segunda', 'segunda-feira', 'terça', 'terça-feira', 'quarta', 'quarta-feira', 'quinta', 'quinta-feira', 'sexta', 'sexta-feira', 'sábado')
  AND TRIM(h.time_range) LIKE '%-%'
ON CONFLICT (professional_id, day_of_week, start_time, end_time) DO NOTHING;

-- Verificar quantas foram criadas
SELECT COUNT(*) as availabilities_created FROM professional_availabilities;

-- Verificar detalhes das availabilities criadas
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
ORDER BY p.full_name, pa.day_of_week, pa.start_time;