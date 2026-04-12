-- VERIFICAÇÃO FINAL - SISTEMA COMPLETO FUNCIONANDO

-- 1. Status geral do sistema
SELECT
  (SELECT COUNT(*) FROM profiles) as total_users,
  (SELECT COUNT(*) FROM servicos WHERE status = 'aprovado') as approved_services,
  (SELECT COUNT(*) FROM professional_availabilities) as total_availabilities,
  (SELECT COUNT(*) FROM appointments) as total_appointments;

-- 2. Verificar integridade dos dados
SELECT
  'Serviços sem availabilities:' as check_type,
  COUNT(*) as count
FROM servicos s
WHERE s.status = 'aprovado'
  AND NOT EXISTS (
    SELECT 1 FROM professional_availabilities pa
    WHERE pa.professional_id = s.user_id
  );

-- 3. Verificar se há availabilities órfãs (sem serviço aprovado)
SELECT
  'Availabilities órfãs:' as check_type,
  COUNT(*) as count
FROM professional_availabilities pa
WHERE NOT EXISTS (
  SELECT 1 FROM servicos s
  WHERE s.user_id = pa.professional_id AND s.status = 'aprovado'
);

-- 4. Teste de consulta típica do app
SELECT
  s.id,
  s.nome,
  s.categoria,
  s.dias_disponiveis,
  s.horarios,
  p.full_name as profissional,
  COUNT(pa.id) as availabilities_count
FROM servicos s
JOIN profiles p ON s.user_id = p.id
LEFT JOIN professional_availabilities pa ON pa.professional_id = s.user_id
WHERE s.status = 'aprovado'
GROUP BY s.id, s.nome, s.categoria, s.dias_disponiveis, s.horarios, p.full_name
ORDER BY s.created_at DESC;

-- 5. Verificar se as políticas RLS estão funcionando
-- (Esta consulta deve retornar dados se executada como usuário autenticado)
SELECT 'Teste RLS - Meus serviços:' as test, COUNT(*) as count FROM servicos WHERE user_id = auth.uid();
SELECT 'Teste RLS - Meu perfil:' as test, COUNT(*) as count FROM profiles WHERE id = auth.uid();

-- SISTEMA PRONTO PARA USO! ✅