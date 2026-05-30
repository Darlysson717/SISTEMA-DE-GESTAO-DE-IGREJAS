-- Setup do acesso ADMINISTRADOR
-- Super administrador fixo por e-mail:
-- darlison.pires.corporativo@gmail.com
--
-- Este script cria tabela de admins e permissões para:
-- 1) Super admin adicionar/remover administradores
-- 2) Admins apagarem imagens órfãs no bucket servicos_images via Storage API

create table if not exists public.app_admins (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  is_active boolean not null default true,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.app_admins enable row level security;

drop policy if exists "Super admin can read all app_admins" on public.app_admins;
drop policy if exists "Admins can read own app_admins row" on public.app_admins;
drop policy if exists "Super admin can insert app_admins" on public.app_admins;
drop policy if exists "Super admin can update app_admins" on public.app_admins;
drop policy if exists "Super admin can delete app_admins" on public.app_admins;

create policy "Super admin can read all app_admins"
on public.app_admins
for select
using (
  lower(coalesce(auth.jwt()->>'email', '')) = 'darlison.pires.corporativo@gmail.com'
);

create policy "Admins can read own app_admins row"
on public.app_admins
for select
using (auth.uid() = user_id);

create policy "Super admin can insert app_admins"
on public.app_admins
for insert
with check (
  lower(coalesce(auth.jwt()->>'email', '')) = 'darlison.pires.corporativo@gmail.com'
);

create policy "Super admin can update app_admins"
on public.app_admins
for update
using (
  lower(coalesce(auth.jwt()->>'email', '')) = 'darlison.pires.corporativo@gmail.com'
)
with check (
  lower(coalesce(auth.jwt()->>'email', '')) = 'darlison.pires.corporativo@gmail.com'
);

create policy "Super admin can delete app_admins"
on public.app_admins
for delete
using (
  lower(coalesce(auth.jwt()->>'email', '')) = 'darlison.pires.corporativo@gmail.com'
);

-- Permitir que administradores removam qualquer imagem do bucket de serviços
-- (necessário para limpar órfãs)
drop policy if exists "Admins can delete any service images" on storage.objects;

create policy "Admins can delete any service images"
on storage.objects
for delete
using (
  bucket_id = 'servicos_images'
  and (
    lower(coalesce(auth.jwt()->>'email', '')) = 'darlison.pires.corporativo@gmail.com'
    or exists (
      select 1
      from public.app_admins a
      where a.user_id = auth.uid()
        and a.is_active = true
    )
  )
);

-- Função RPC para listar imagens órfãs com segurança de administrador
create or replace function public.get_orphan_service_images()
returns jsonb
language plpgsql
security definer
set search_path = public, storage
as $$
declare
  is_admin_user boolean;
  result jsonb;
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

  with referenced_images as (
    select distinct
      split_part(
        case
          when s.imagem_profissional like '%/servicos_images/%' then split_part(s.imagem_profissional, '/servicos_images/', 2)
          else s.imagem_profissional
        end,
        '?',

        -- RPC para contar usuários cadastrados no Authentication (auth.users)
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
        1
      ) as image_path
    from public.servicos s
    where s.imagem_profissional is not null
      and btrim(s.imagem_profissional) <> ''
  ), storage_files as (
    select o.name
    from storage.objects o
    where o.bucket_id = 'servicos_images'
      and o.name <> '.emptyFolderPlaceholder'
      and o.name not like '%/.emptyFolderPlaceholder'
  ), orphan_files as (
    select f.name
    from storage_files f
    where not exists (
      select 1
      from referenced_images r
      where r.image_path = f.name
    )
  )
  select jsonb_build_object(
    'total_files', (select count(*) from storage_files),
    'orphan_paths', coalesce(
      (select jsonb_agg(ofs.name order by ofs.name) from orphan_files ofs),
      '[]'::jsonb
    )
  )
  into result;

  return result;
end;
$$;

revoke all on function public.get_orphan_service_images() from public;
grant execute on function public.get_orphan_service_images() to authenticated;

select 'Setup ADMINISTRADOR aplicado com sucesso.' as status;
