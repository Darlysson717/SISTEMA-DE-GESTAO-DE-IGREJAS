-- =====================================================
-- MIGRACAO: adicionar WhatsApp para voluntarios
-- =====================================================

alter table public.event_registrations
  add column if not exists volunteer_whatsapp text;

-- Remove constraint antiga, se existir com nome default variavel.
do $$
begin
  if exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    where t.relname = 'event_registrations'
      and c.contype = 'c'
      and c.conname = 'event_registrations_interesse_check'
  ) then
    alter table public.event_registrations
      drop constraint event_registrations_interesse_check;
  end if;
end $$;

-- Garante check completo: valores validos + WhatsApp obrigatorio para voluntario.
alter table public.event_registrations
  drop constraint if exists event_registrations_interest_whatsapp_check;

alter table public.event_registrations
  add constraint event_registrations_interest_whatsapp_check
  check (
    interesse in ('participante', 'voluntario')
    and (interesse <> 'voluntario' or volunteer_whatsapp is not null)
  );
