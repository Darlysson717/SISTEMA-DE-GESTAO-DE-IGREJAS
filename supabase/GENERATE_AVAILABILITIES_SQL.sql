-- GERAR INSERTS AUTOMÁTICOS PARA AVAILABILITIES
-- Execute este script para ver os comandos INSERT que precisam ser executados

SELECT
  '-- Serviço: ' || s.nome || ' (ID: ' || s.id || ')' as comentario,
  STRING_AGG(
    'INSERT INTO professional_availabilities (professional_id, day_of_week, start_time, end_time) VALUES (' ||
    '''' || s.user_id || ''', ' ||
    CASE LOWER(TRIM(d.day_name))
      WHEN 'domingo' THEN '0'
      WHEN 'segunda' THEN '1'
      WHEN 'terça' THEN '2'
      WHEN 'quarta' THEN '3'
      WHEN 'quinta' THEN '4'
      WHEN 'sexta' THEN '5'
      WHEN 'sábado' THEN '6'
    END || ', ' ||
    '''' || SPLIT_PART(TRIM(h.time_range), '-', 1) || ':00' || ''', ' ||
    '''' || SPLIT_PART(TRIM(h.time_range), '-', 2) || ':00' || '''' ||
    ') ON CONFLICT (professional_id, day_of_week, start_time, end_time) DO NOTHING;',
    E'\n'
  ) as insert_statements
FROM servicos s
CROSS JOIN LATERAL unnest(s.dias_disponiveis) AS d(day_name)
CROSS JOIN LATERAL unnest(s.horarios) AS h(time_range)
WHERE s.status = 'aprovado'
  AND array_length(s.dias_disponiveis, 1) > 0
  AND array_length(s.horarios, 1) > 0
  AND LOWER(TRIM(d.day_name)) IN ('domingo', 'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado')
  AND TRIM(h.time_range) LIKE '%-%'
GROUP BY s.id, s.nome, s.user_id
ORDER BY s.created_at DESC;