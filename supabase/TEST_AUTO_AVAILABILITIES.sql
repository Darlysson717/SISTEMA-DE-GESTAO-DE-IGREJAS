-- TESTAR A CRIAÇÃO AUTOMÁTICA DE DISPONIBILIDADES
-- Primeiro, ver serviços pendentes
SELECT id, nome, status, dias_disponiveis, horarios, user_id
FROM servicos
WHERE status = 'pendente'
ORDER BY created_at DESC
LIMIT 5;

-- Aprovar um serviço (substitua o ID pelo real)
-- UPDATE servicos SET status = 'aprovado' WHERE id = 'SEU_SERVICE_ID_AQUI';

-- Verificar se as disponibilidades foram criadas
-- SELECT * FROM professional_availabilities WHERE professional_id = 'SEU_USER_ID_AQUI';