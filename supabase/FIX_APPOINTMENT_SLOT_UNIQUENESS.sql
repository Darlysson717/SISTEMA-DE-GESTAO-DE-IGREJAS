-- Corrige unicidade para bloquear apenas mesmo serviço+dia+horário
-- (e não o dia inteiro), liberando o slot quando removido/cancelado.

alter table public.appointments enable row level security;

alter table public.appointments
drop constraint if exists appointments_one_per_service_per_day;

alter table public.appointments
drop constraint if exists appointments_one_per_service_per_datetime;

drop index if exists public.appointments_one_per_service_per_day;
drop index if exists public.appointments_one_per_service_per_datetime;
drop index if exists public.appointments_unique_active_slot;

create unique index if not exists appointments_unique_active_slot
on public.appointments(service_id, scheduled_date, scheduled_time)
where status in ('scheduled', 'confirmed');

select 'Unicidade de slot de agendamento corrigida com sucesso.' as status;
