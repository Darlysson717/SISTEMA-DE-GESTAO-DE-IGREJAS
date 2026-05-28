-- Fix appointments status constraint to use Portuguese values
-- Run after the status migration if the database still has the old English constraint.

BEGIN;

-- Normalize existing rows before re-adding the constraint.
UPDATE public.appointments
SET status = CASE
  WHEN status IN ('scheduled', 'confirmed') THEN 'agendado'
  WHEN status = 'completed' THEN 'concluido'
  WHEN status = 'cancelled' THEN 'cancelado'
  WHEN status = 'noShow' THEN 'faltou'
  WHEN status IS NULL THEN 'agendado'
  ELSE status
END;

ALTER TABLE public.appointments
  DROP CONSTRAINT IF EXISTS appointments_status_check;

ALTER TABLE public.appointments
  ADD CONSTRAINT appointments_status_check
  CHECK (
    status IN ('agendado', 'concluido', 'cancelado', 'faltou')
  );

UPDATE public.appointments
SET status = 'agendado'
WHERE status IS NULL;

COMMIT;