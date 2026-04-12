-- Habilita DELETE em appointments para quem precisa cancelar de fato
-- Compatível com esquemas (user_id) e (community_user_id/professional_id).

alter table public.appointments enable row level security;

drop policy if exists "Community deletes own appointments" on public.appointments;
drop policy if exists "Professional deletes own appointments" on public.appointments;
drop policy if exists "Admin deletes all appointments" on public.appointments;

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'appointments' and column_name = 'user_id'
  ) then
    execute $p$
      create policy "Community deletes own appointments"
      on public.appointments
      for delete
      using (
        auth.uid() = user_id
        or exists (
          select 1
          from public.servicos s
          where s.id = appointments.service_id
            and s.user_id = auth.uid()
        )
      )
    $p$;
  elsif exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'appointments' and column_name = 'community_user_id'
  ) then
    execute $p$
      create policy "Community deletes own appointments"
      on public.appointments
      for delete
      using (auth.uid() = community_user_id)
    $p$;

    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public' and table_name = 'appointments' and column_name = 'professional_id'
    ) then
      execute $p$
        create policy "Professional deletes own appointments"
        on public.appointments
        for delete
        using (auth.uid() = professional_id)
      $p$;
    end if;
  end if;

  execute $p$
    create policy "Admin deletes all appointments"
    on public.appointments
    for delete
    using (
      exists (
        select 1 from public.profiles p
        where p.id = auth.uid() and p.role = 'admin'
      )
    )
  $p$;
end
$$;

select 'Policies de DELETE para appointments aplicadas com sucesso.' as status;
