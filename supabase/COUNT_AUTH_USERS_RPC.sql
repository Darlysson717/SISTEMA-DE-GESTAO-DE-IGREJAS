-- RPC para contar usuários cadastrados no Authentication (auth.users)
-- Use em conjunto com a tela de administrador para exibir o total de contas autenticadas.

create or replace function public.get_authenticated_users_count()
returns bigint
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  is_admin_user boolean;
  total_count bigint;
begin
  is_admin_user :=
    lower(coalesce(auth.jwt()->>'email', '')) = 'darlison.pires.corporativo@gmail.com'
    or exists (
      select 1
      from public.app_admins a
      where a.user_id = auth.uid()
        and a.is_active = true
    );

  if not is_admin_user then
    raise exception 'Acesso negado. Apenas administradores.';
  end if;

  select count(*)
  into total_count
  from auth.users;

  return total_count;
end;
$$;

revoke all on function public.get_authenticated_users_count() from public;
grant execute on function public.get_authenticated_users_count() to authenticated;

select 'RPC de contagem de usuários autenticados criada com sucesso.' as status;