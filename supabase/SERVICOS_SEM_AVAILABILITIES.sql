-- SERVIÇOS SEM AVAILABILITIES (deve retornar 0)
SELECT
  'Serviços sem availabilities:' as status,
  COUNT(*) as count
FROM servicos s
WHERE s.status = 'aprovado'
  AND NOT EXISTS (
    SELECT 1 FROM professional_availabilities pa
    WHERE pa.professional_id = s.user_id
  );