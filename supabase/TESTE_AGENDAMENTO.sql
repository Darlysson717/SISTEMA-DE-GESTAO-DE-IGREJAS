-- TESTE DE AGENDAMENTO CORRIGIDO
-- Considerando conversão para São Paulo (-3 horas)

-- Horário desejado em São Paulo: 11:30-12:00 em uma segunda-feira
-- Para que seja 11:30-12:00 em SP, preciso inserir 14:30-15:00 UTC

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
  'teste',
  '2026-03-03 14:30:00+00'::TIMESTAMPTZ, -- 11:30 em SP (dentro de 11:12-12:12)
  '2026-03-03 15:00:00+00'::TIMESTAMPTZ, -- 12:00 em SP
  '97ac3170-9795-4874-8e62-9143104e41ea'
);

-- Verificar se foi criado
SELECT * FROM appointments WHERE specialty = 'teste';