-- DIAGNÓSTICO RÁPIDO - ANTES DE EXECUTAR OS FIXES

-- Verificar estrutura da tabela servicos
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'servicos'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verificar se existem serviços aprovados
SELECT
  COUNT(*) as total_servicos,
  COUNT(CASE WHEN status = 'aprovado' THEN 1 END) as servicos_aprovados,
  COUNT(CASE WHEN status = 'pendente' THEN 1 END) as servicos_pendentes
FROM servicos;

-- Verificar foreign keys da tabela professional_availabilities
SELECT
  tc.table_name,
  tc.constraint_name,
  tc.constraint_type,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'professional_availabilities'
  AND tc.constraint_type = 'FOREIGN KEY';

-- Verificar se há dados nas availabilities
SELECT COUNT(*) as total_availabilities FROM professional_availabilities;

-- Verificar se há algum serviço aprovado sem availabilities
SELECT
  s.id,
  s.nome,
  s.categoria,
  p.full_name,
  s.dias_disponiveis,
  s.horarios
FROM servicos s
JOIN profiles p ON s.user_id = p.id
WHERE s.status = 'aprovado'
  AND NOT EXISTS (
    SELECT 1 FROM professional_availabilities pa
    WHERE pa.professional_id = s.user_id
  )
ORDER BY s.created_at DESC
LIMIT 5;