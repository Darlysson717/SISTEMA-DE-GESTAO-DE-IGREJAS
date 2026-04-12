-- Habilita gerenciamento de permissão de publicação de serviços
-- Execute no SQL Editor do Supabase

create table if not exists public.service_publish_permissions (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  is_active boolean not null default true,
  granted_by uuid references public.profiles(id) on delete set null,
  granted_at timestamptz not null default now(),
  revoked_by uuid references public.profiles(id) on delete set null,
  revoked_at timestamptz
);

alter table public.service_publish_permissions enable row level security;

drop policy if exists "Users can read own publish permission" on public.service_publish_permissions;
drop policy if exists "Admins can read all publish permissions" on public.service_publish_permissions;
drop policy if exists "Admins can insert publish permissions" on public.service_publish_permissions;
drop policy if exists "Admins can update publish permissions" on public.service_publish_permissions;

create policy "Users can read own publish permission"
on public.service_publish_permissions
for select
using (auth.uid() = user_id);

create policy "Admins can read all publish permissions"
on public.service_publish_permissions
for select
using (
  lower(coalesce(auth.jwt()->>'email', '')) = 'darlison.pires.corporativo@gmail.com'
  or exists (
    select 1
    from public.app_admins a
    where a.user_id = auth.uid()
      and a.is_active = true
  )
);

create policy "Admins can insert publish permissions"
on public.service_publish_permissions
for insert
with check (
  lower(coalesce(auth.jwt()->>'email', '')) = 'darlison.pires.corporativo@gmail.com'
  or exists (
    select 1
    from public.app_admins a
    where a.user_id = auth.uid()
      and a.is_active = true
  )
);

create policy "Admins can update publish permissions"
on public.service_publish_permissions
for update
using (
  (
    lower(coalesce(auth.jwt()->>'email', '')) = 'darlison.pires.corporativo@gmail.com'
    or exists (
      select 1
      from public.app_admins a
      where a.user_id = auth.uid()
        and a.is_active = true
    )
  )
  and not exists (
    select 1
    from public.profiles p
    where p.id = service_publish_permissions.user_id
      and lower(coalesce(p.email, '')) = 'darlison.pires.corporativo@gmail.com'
  )
)
with check (
  (
    lower(coalesce(auth.jwt()->>'email', '')) = 'darlison.pires.corporativo@gmail.com'
    or exists (
      select 1
      from public.app_admins a
      where a.user_id = auth.uid()
        and a.is_active = true
    )
  )
  and not exists (
    select 1
    from public.profiles p
    where p.id = service_publish_permissions.user_id
      and lower(coalesce(p.email, '')) = 'darlison.pires.corporativo@gmail.com'
  )
);

-- Backfill: usuários já aprovados para publicação
insert into public.service_publish_permissions (user_id, is_active, granted_at)
select distinct r.user_id, true, now()
from public.service_publish_requests r
where r.status = 'approved'
on conflict (user_id) do update
set
  is_active = true,
  revoked_by = null,
  revoked_at = null;

-- Backfill: usuários que já possuem serviço publicado
insert into public.service_publish_permissions (user_id, is_active, granted_at)
select distinct s.user_id, true, now()
from public.servicos s
on conflict (user_id) do update
set
  is_active = true,
  revoked_by = null,
  revoked_at = null;

select 'Gestão de permissão de publicação habilitada com sucesso.' as status;
