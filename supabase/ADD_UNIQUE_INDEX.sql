-- ADICIONAR ÍNDICE ÚNICO PARA SUPORTAR ON CONFLICT
-- Execute este script ANTES de usar ON CONFLICT em outros scripts

-- Criar índice único nas colunas que queremos usar com ON CONFLICT
CREATE UNIQUE INDEX IF NOT EXISTS idx_professional_availabilities_unique
ON professional_availabilities (professional_id, day_of_week, start_time, end_time);

-- Verificar se o índice foi criado
SELECT
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'professional_availabilities'
  AND indexname = 'idx_professional_availabilities_unique';