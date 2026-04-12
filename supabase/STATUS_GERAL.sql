-- STATUS GERAL DO SISTEMA
SELECT
  (SELECT COUNT(*) FROM profiles) as total_users,
  (SELECT COUNT(*) FROM servicos WHERE status = 'aprovado') as approved_services,
  (SELECT COUNT(*) FROM professional_availabilities) as total_availabilities,
  (SELECT COUNT(*) FROM appointments) as total_appointments;