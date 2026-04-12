-- TESTE: Validação de um agendamento por dia
-- Este script testa se a validação impede múltiplos agendamentos no mesmo dia

-- Primeiro, vamos inserir um agendamento de teste
INSERT INTO appointments (
  community_user_id,
  professional_id,
  specialty,
  starts_at,
  ends_at,
  created_by
) VALUES (
  '97ac3170-9795-4874-8e62-9143104e41ea',
  '97ac3170-9795-4874-8e62-9143104e41ea',
  'teste-validacao',
  '2026-03-05 14:00:00+00'::TIMESTAMPTZ, -- 11:00 em SP
  '2026-03-05 15:00:00+00'::TIMESTAMPTZ, -- 12:00 em SP
  '97ac3170-9795-4874-8e62-9143104e41ea'
);

-- Agora tentar inserir um segundo agendamento no mesmo dia (deve falhar)
INSERT INTO appointments (
  community_user_id,
  professional_id,
  specialty,
  starts_at,
  ends_at,
  created_by
) VALUES (
  '97ac3170-9795-4874-8e62-9143104e41ea',
  '97ac3170-9795-4874-8e62-9143104e41ea',
  'teste-validacao-2',
  '2026-03-05 16:00:00+00'::TIMESTAMPTZ, -- 13:00 em SP (mesmo dia)
  '2026-03-05 17:00:00+00'::TIMESTAMPTZ, -- 14:00 em SP
  '97ac3170-9795-4874-8e62-9143104e41ea'
);

-- Verificar agendamentos criados
SELECT specialty, starts_at, status FROM appointments WHERE specialty LIKE 'teste-validacao%';