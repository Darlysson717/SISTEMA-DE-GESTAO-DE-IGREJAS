-- VERIFICAR SE OS SERVIÇOS FORAM PUBLICADOS
SELECT
  id,
  nome,
  categoria,
  nome_profissional,
  status,
  created_at,
  imagem_profissional
FROM servicos
ORDER BY created_at DESC
LIMIT 10;

-- VERIFICAR SERVIÇOS DO USUÁRIO ESPECÍFICO
SELECT
  id,
  nome,
  status,
  created_at
FROM servicos
WHERE user_id = '97ac3170-9795-4874-8e62-9143104e41ea'
ORDER BY created_at DESC;