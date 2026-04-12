-- VERSÃO SIMPLIFICADA - CRIAR AVAILABILITIES COM LOOP
-- Execute este script se a versão complexa não funcionar
-- Esta versão processa um serviço por vez

-- Primeiro, vamos ver quais serviços aprovados existem
SELECT
  s.id,
  s.nome,
  s.user_id,
  p.full_name,
  s.dias_disponiveis,
  s.horarios
FROM servicos s
JOIN profiles p ON s.user_id = p.id
WHERE s.status = 'aprovado'
ORDER BY s.created_at DESC;

-- Para cada serviço, execute os INSERTs manualmente
-- Substitua 'SERVICE_USER_ID' pelo user_id real do serviço
-- Exemplo para um serviço que trabalha segunda, quarta e sexta das 08:00-12:00:

-- INSERT INTO professional_availabilities (professional_id, day_of_week, start_time, end_time)
-- VALUES ('SERVICE_USER_ID', 1, '08:00:00', '12:00:00'); -- Segunda

-- INSERT INTO professional_availabilities (professional_id, day_of_week, start_time, end_time)
-- VALUES ('SERVICE_USER_ID', 3, '08:00:00', '12:00:00'); -- Quarta

-- INSERT INTO professional_availabilities (professional_id, day_of_week, start_time, end_time)
-- VALUES ('SERVICE_USER_ID', 5, '08:00:00', '12:00:00'); -- Sexta

-- Verificar se funcionou
-- SELECT * FROM professional_availabilities WHERE professional_id = 'SERVICE_USER_ID';