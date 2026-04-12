-- SOLUÇÃO COMPLETA PARA O ERRO DE AGENDAMENTO

-- PASSO 1: Corrigir as Foreign Keys (execute primeiro)
-- Execute FIX_AVAILABILITIES_FK.sql

-- PASSO 2: Criar availabilities para serviços já aprovados
-- Execute CREATE_MISSING_AVAILABILITIES.sql

-- PASSO 3: Verificar se funcionou
-- Execute este script

-- Status atual do sistema
SELECT
  (SELECT COUNT(*) FROM profiles) as total_users,
  (SELECT COUNT(*) FROM servicos WHERE status = 'aprovado') as approved_services,
  (SELECT COUNT(*) FROM professional_availabilities) as total_availabilities,
  (SELECT COUNT(*) FROM appointments) as total_appointments;

-- Verificar se todos os serviços aprovados têm availabilities
SELECT
  'Serviços sem availabilities:' as status,
  COUNT(*) as count
FROM servicos s
WHERE s.status = 'aprovado'
  AND NOT EXISTS (
    SELECT 1 FROM professional_availabilities pa
    WHERE pa.professional_id = s.user_id
  );

-- Verificar se há availabilities órfãs (sem serviço aprovado correspondente)
SELECT
  'Availabilities órfãs:' as status,
  COUNT(*) as count
FROM professional_availabilities pa
WHERE NOT EXISTS (
  SELECT 1 FROM servicos s
  WHERE s.user_id = pa.professional_id AND s.status = 'aprovado'
);

-- Mostrar availabilities criadas por profissional
SELECT
  pa.professional_id,
  p.full_name,
  COUNT(pa.id) as availabilities_count,
  STRING_AGG(
    CASE pa.day_of_week
      WHEN 0 THEN 'Dom'
      WHEN 1 THEN 'Seg'
      WHEN 2 THEN 'Ter'
      WHEN 3 THEN 'Qua'
      WHEN 4 THEN 'Qui'
      WHEN 5 THEN 'Sex'
      WHEN 6 THEN 'Sab'
    END || ' ' || pa.start_time::TEXT || '-' || pa.end_time::TEXT,
    ', '
  ) as horarios
FROM professional_availabilities pa
JOIN profiles p ON pa.professional_id = p.id
GROUP BY pa.professional_id, p.full_name
ORDER BY p.full_name;

-- Teste: verificar se podemos inserir um agendamento (não executar, apenas verificar)
-- Este é um exemplo de como seria um agendamento válido:
-- INSERT INTO appointments (
--   community_user_id,
--   professional_id,
--   specialty,
--   starts_at,
--   ends_at,
--   created_by
-- ) VALUES (
--   'USER_ID_COMUNIDADE',
--   'USER_ID_PROFISSIONAL',
--   'categoria',
--   '2024-01-15 10:00:00+00'::TIMESTAMPTZ,
--   '2024-01-15 11:00:00+00'::TIMESTAMPTZ,
--   'USER_ID_COMUNIDADE'
-- );

-- SE AINDA FALHAR, verifique:
-- 1. Se o dia da semana está correto (0=domingo, 6=sábado)
-- 2. Se o horário está dentro da availability criada
-- 3. Se há conflitos de agendamento (appointments_no_overlap)
-- 4. Se o professional_id existe na tabela profiles