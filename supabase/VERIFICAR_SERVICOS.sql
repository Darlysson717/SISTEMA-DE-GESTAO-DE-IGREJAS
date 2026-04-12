-- VERIFICAR TODOS OS SERVIÇOS E SEUS STATUS
SELECT
  id,
  nome,
  categoria,
  status,
  user_id,
  dias_disponiveis,
  horarios,
  created_at
FROM servicos
ORDER BY created_at DESC;