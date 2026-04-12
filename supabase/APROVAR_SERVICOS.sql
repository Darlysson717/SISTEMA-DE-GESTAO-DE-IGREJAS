-- APROVAR TODOS OS SERVIÇOS PENDENTES PARA TESTE
-- Execute este script apenas se quiser aprovar todos os serviços para teste

UPDATE servicos
SET status = 'aprovado'
WHERE status = 'pendente';

-- Verificar quantos foram aprovados
SELECT
  COUNT(*) as total_servicos,
  COUNT(CASE WHEN status = 'aprovado' THEN 1 END) as aprovados,
  COUNT(CASE WHEN status = 'pendente' THEN 1 END) as pendentes,
  COUNT(CASE WHEN status = 'rejeitado' THEN 1 END) as rejeitados
FROM servicos;