-- DIAGNÓSTICO PASSO A PASSO - Execute uma query por vez

-- 1. STATUS GERAL DO SISTEMA
SELECT
  (SELECT COUNT(*) FROM profiles) as total_users,
  (SELECT COUNT(*) FROM servicos WHERE status = 'aprovado') as approved_services,
  (SELECT COUNT(*) FROM professional_availabilities) as total_availabilities,
  (SELECT COUNT(*) FROM appointments) as total_appointments;

-- 2. SERVIÇOS SEM AVAILABILITIES (deve ser 0)
SELECT
  'Serviços sem availabilities:' as status,
  COUNT(*) as count
FROM servicos s
WHERE s.status = 'aprovado'
  AND NOT EXISTS (
    SELECT 1 FROM professional_availabilities pa
    WHERE pa.professional_id = s.user_id
  );

-- 3. AVAILABILITIES ÓRFÃS (você já viu que é 0)
SELECT
  'Availabilities órfãs:' as status,
  COUNT(*) as count
FROM professional_availabilities pa
WHERE NOT EXISTS (
  SELECT 1 FROM servicos s
  WHERE s.user_id = pa.professional_id AND s.status = 'aprovado'
);

-- 4. LISTA DE AVAILABILITIES POR PROFISSIONAL
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