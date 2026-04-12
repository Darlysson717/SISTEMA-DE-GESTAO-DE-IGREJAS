-- Correção para limpeza de órfãs sem acesso direto ao schema storage no PostgREST
-- Execute no SQL Editor do Supabase

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

select 'Fix RPC de órfãs aplicado com sucesso.' as status;
