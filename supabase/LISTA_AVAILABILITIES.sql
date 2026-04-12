-- LISTA DE AVAILABILITIES POR PROFISSIONAL
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