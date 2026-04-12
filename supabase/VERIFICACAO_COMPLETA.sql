-- VERIFICAÇÃO COMPLETA E CRIAÇÃO DE AVAILABILITIES

-- 1. Verificar serviços existentes
SELECT
  id,
  nome,
  categoria,
  status,
  user_id,
  array_length(dias_disponiveis, 1) as dias_count,
  array_length(horarios, 1) as horarios_count
FROM servicos
ORDER BY created_at DESC;

-- 2. Aprovar serviços pendentes (descomente se quiser)
-- UPDATE servicos SET status = 'aprovado' WHERE status = 'pendente';

-- 3. Status após aprovação
SELECT
  COUNT(*) as total_servicos,
  COUNT(CASE WHEN status = 'aprovado' THEN 1 END) as aprovados,
  COUNT(CASE WHEN status = 'pendente' THEN 1 END) as pendentes
FROM servicos;

-- 4. Criar availabilities para serviços aprovados
-- (Execute CREATE_MISSING_AVAILABILITIES.sql depois)

-- 5. Verificação final
-- (Execute STATUS_GERAL.sql e LISTA_AVAILABILITIES.sql)