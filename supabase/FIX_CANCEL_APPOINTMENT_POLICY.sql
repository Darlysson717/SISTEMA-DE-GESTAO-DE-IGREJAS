-- Corrige cancelamento de agendamentos via RLS (compatível com esquemas diferentes)
-- Funciona tanto para colunas user_id quanto community_user_id.
-- Também permite cancelamento pelo profissional dono do serviço.

alter table public.appointments enable row level security;

drop policy if exists "Community updates own scheduled appointments" on public.appointments;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'appointments'
      and column_name = 'community_user_id'
  ) then
    execute $policy$
      create policy "Community updates own scheduled appointments"
      on public.appointments
      for update
      using (
        (
          auth.uid() = community_user_id
          and status in ('scheduled', 'confirmed')
        )
        or exists (
          select 1
          from public.servicos s
          where s.id = appointments.service_id
            and s.user_id = auth.uid()
        )
      )
      with check (
        (
          auth.uid() = community_user_id
          and status in ('scheduled', 'confirmed', 'cancelled')
        )
        or exists (
          select 1
          from public.servicos s
          where s.id = appointments.service_id
            and s.user_id = auth.uid()
        )
      )
    $policy$;
  elsif exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'appointments'
      and column_name = 'user_id'
  ) then
    execute $policy$
      create policy "Community updates own scheduled appointments"
      on public.appointments
      for update
      using (
        (
          auth.uid() = user_id
          and status in ('scheduled', 'confirmed')
        )
        or exists (
          select 1
          from public.servicos s
          where s.id = appointments.service_id
            and s.user_id = auth.uid()
        )
      )
      with check (
        (
          auth.uid() = user_id
          and status in ('scheduled', 'confirmed', 'cancelled')
        )
        or exists (
          select 1
          from public.servicos s
          where s.id = appointments.service_id
            and s.user_id = auth.uid()
        )
      )
    $policy$;
  else
    raise exception 'Nenhuma coluna de usuário esperada foi encontrada em public.appointments (user_id ou community_user_id).';
  end if;
end
$$;

select 'Política de cancelamento de agendamento corrigida com sucesso.' as status;
