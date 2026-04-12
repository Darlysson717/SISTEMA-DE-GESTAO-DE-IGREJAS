-- VERSÃO SIMPLIFICADA - CRIAR AVAILABILITIES MANUALMENTE
-- Execute este script APÓS FIX_AVAILABILITIES_FK.sql
-- Esta versão cria uma availability por vez para facilitar o debug

-- Exemplo: Para um serviço específico, substitua os valores abaixo:
-- Substitua 'SERVICE_USER_ID' pelo user_id do serviço
-- Substitua os dias e horários conforme necessário

-- Domingo 08:00-12:00
INSERT INTO professional_availabilities (professional_id, day_of_week, start_time, end_time)
VALUES ('SERVICE_USER_ID', 0, '08:00:00', '12:00:00')
ON CONFLICT (professional_id, day_of_week, start_time, end_time) DO NOTHING;

-- Segunda 08:00-12:00
INSERT INTO professional_availabilities (professional_id, day_of_week, start_time, end_time)
VALUES ('SERVICE_USER_ID', 1, '08:00:00', '12:00:00')
ON CONFLICT (professional_id, day_of_week, start_time, end_time) DO NOTHING;

-- Terça 08:00-12:00
INSERT INTO professional_availabilities (professional_id, day_of_week, start_time, end_time)
VALUES ('SERVICE_USER_ID', 2, '08:00:00', '12:00:00')
ON CONFLICT (professional_id, day_of_week, start_time, end_time) DO NOTHING;

-- E assim por diante para os outros dias...

-- Para verificar se funcionou:
SELECT * FROM professional_availabilities WHERE professional_id = 'SERVICE_USER_ID';