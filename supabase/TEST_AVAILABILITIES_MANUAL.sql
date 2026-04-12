-- TESTE MANUAL DE CRIAÇÃO DE AVAILABILITIES

-- Primeiro, pegar um user_id de um serviço aprovado
SELECT DISTINCT s.user_id, p.full_name, s.nome as service_name
FROM servicos s
JOIN profiles p ON s.user_id = p.id
WHERE s.status = 'aprovado'
LIMIT 1;

-- Agora, criar uma availability manualmente para testar
-- (Substitua 'USER_ID_AQUI' pelo ID real retornado acima)
-- INSERT INTO professional_availabilities (
--   professional_id,
--   day_of_week,
--   start_time,
--   end_time
-- ) VALUES (
--   'USER_ID_AQUI',
--   1, -- segunda-feira
--   '08:00:00'::TIME,
--   '12:00:00'::TIME
-- );

-- Verificar se foi criada
-- SELECT * FROM professional_availabilities WHERE professional_id = 'USER_ID_AQUI';

-- Testar a validação manual
-- (Substitua os valores pelos reais)
-- SELECT
--   CASE WHEN local_start::time >= pa.start_time AND local_end::time <= pa.end_time
--        THEN 'VALIDO'
--        ELSE 'INVALIDO'
--   END as validation_result,
--   pa.professional_id,
--   pa.day_of_week,
--   pa.start_time,
--   pa.end_time
-- FROM professional_availabilities pa
-- WHERE pa.professional_id = 'USER_ID_AQUI'
--   AND pa.day_of_week = 1; -- segunda-feira