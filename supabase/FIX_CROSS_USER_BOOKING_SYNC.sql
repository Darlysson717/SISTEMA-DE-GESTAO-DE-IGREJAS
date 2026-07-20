-- ============================================================
-- CORREÇÃO: Sincronização de bloqueio de horários entre usuários
-- ============================================================
-- Problema: A RPC get_service_booked_times busca por status='agendado'
-- mas o SETUP_SIMPLES.sql usa status em inglês ('confirmed').
-- Além disso, a RPC precisa ser security definer para ignorar RLS.
-- ============================================================

-- 1. Recriar a RPC com os status corretos do schema atual
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
    and a.status in ('confirmed', 'agendado')
  order by 1;
$$;

-- 2. Garantir permissão de execução
revoke all on function public.get_service_booked_times(uuid, date) from public;
grant execute on function public.get_service_booked_times(uuid, date) to authenticated;
grant execute on function public.get_service_booked_times(uuid, date) to anon;

-- 3. Criar índice único para evitar duplicatas (funciona para ambos os schemas)
create unique index if not exists appointments_unique_active_slot
on public.appointments(service_id, scheduled_date, scheduled_time)
where status in ('confirmed', 'agendado');

-- 4. Garantir que a política RLS permite que profissionais vejam agendamentos dos seus serviços
drop policy if exists "Service providers can view appointments for their services" on public.appointments;
create policy "Service providers can view appointments for their services"
on public.appointments
for select
using (
  exists (
    select 1 from public.servicos s
    where s.id = service_id and s.user_id = auth.uid()
  )
);

select 'Correção de sincronização aplicada com sucesso.' as status;