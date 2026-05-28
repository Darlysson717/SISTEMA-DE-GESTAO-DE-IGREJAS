-- Migration: Add status and audit for appointments
-- Adds status column if missing, cancelled metadata, an events table, and a trigger to log status changes

BEGIN;

-- 1) Ensure extension for gen_random_uuid() exists (pgcrypto)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2) Add status column (values used by the app: 'agendado', 'concluido', 'cancelado', 'faltou')
ALTER TABLE public.appointments
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'agendado';

-- 3) Add cancelled metadata columns
ALTER TABLE public.appointments
  ADD COLUMN IF NOT EXISTS cancelled_at timestamptz,
  ADD COLUMN IF NOT EXISTS cancelled_by uuid;

-- 4) Backfill any NULL statuses (defensive)
UPDATE public.appointments
SET status = 'agendado'
WHERE status IS NULL;

-- 5) Create an index to speed status queries
CREATE INDEX IF NOT EXISTS appointments_status_idx ON public.appointments (status);

-- Note: audit table and trigger intentionally omitted per project preference.
-- This migration only adds status and cancelled metadata to the existing appointments table
-- so cancelled appointments are retained instead of being deleted.

COMMIT;
