-- RPC para listar horários ocupados por serviço em um dia específico
-- Necessário para exibir indisponibilidade corretamente entre contas diferentes.

create or replace function public.get_service_booked_times(
  p_service_id uuid,
  p_scheduled_date date
)
returns table (scheduled_time text)
language sql
security definer
set search_path = public
as $$
  select distinct a.scheduled_time::text
  from public.appointments a
  where a.service_id = p_service_id
    and a.scheduled_date = p_scheduled_date
    and a.status in ('agendado')
  order by 1;
$$;

revoke all on function public.get_service_booked_times(uuid, date) from public;
grant execute on function public.get_service_booked_times(uuid, date) to authenticated;

select 'RPC de horários ocupados criada com sucesso.' as status;
