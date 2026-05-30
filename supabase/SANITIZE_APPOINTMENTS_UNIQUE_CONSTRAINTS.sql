-- Remove constraints/índices antigos que podem causar falso conflito de agendamento
-- e garante a regra correta: mesmo serviço + mesma data + mesmo horário (somente ativos).

alter table public.appointments enable row level security;

do $$
declare
  rec record;
begin
  for rec in
    select c.conname
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'appointments'
      and c.contype = 'u'
      and (
        pg_get_constraintdef(c.oid) ilike '%(service_id, user_id, scheduled_date)%'
        or pg_get_constraintdef(c.oid) ilike '%(user_id, scheduled_date, scheduled_time)%'
        or pg_get_constraintdef(c.oid) ilike '%(service_id, scheduled_date, scheduled_time)%'
      )
  loop
    execute format('alter table public.appointments drop constraint if exists %I', rec.conname);
  end loop;
end
$$;

drop index if exists public.appointments_one_per_service_per_day;
drop index if exists public.appointments_one_per_service_per_datetime;
drop index if exists public.appointments_unique_active_slot;

create unique index if not exists appointments_unique_active_slot
on public.appointments(service_id, scheduled_date, scheduled_time)
where status in ('agendado');

select 'Saneamento de constraints de agendamento concluído com sucesso.' as status;
