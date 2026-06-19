-- Fluxo de solicitação para primeira publicação de eventos
-- Execute no SQL Editor do Supabase

-- 1) Tabela de solicitações de publicação de eventos
create table if not exists public.event_publish_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  requester_name text not null,
  event_name text not null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_event_publish_requests_user
on public.event_publish_requests(user_id, created_at desc);

create index if not exists idx_event_publish_requests_status
on public.event_publish_requests(status, created_at asc);

create unique index if not exists idx_unique_pending_event_publish_request
on public.event_publish_requests(user_id)
where status = 'pending';

drop trigger if exists trg_event_publish_requests_updated_at on public.event_publish_requests;
create trigger trg_event_publish_requests_updated_at
before update on public.event_publish_requests
for each row execute function public.handle_updated_at();

alter table public.event_publish_requests enable row level security;

drop policy if exists "Users can read own event publish requests" on public.event_publish_requests;
drop policy if exists "Users can insert own event publish requests" on public.event_publish_requests;
drop policy if exists "Users can update own pending event publish requests" on public.event_publish_requests;
drop policy if exists "Admins can read all event publish requests" on public.event_publish_requests;
drop policy if exists "Admins can update event publish requests" on public.event_publish_requests;

create policy "Users can read own event publish requests"
on public.event_publish_requests
for select
using (auth.uid() = user_id);

create policy "Users can insert own event publish requests"
on public.event_publish_requests
for insert
with check (
  auth.uid() = user_id
  and status = 'pending'
  and reviewed_by is null
  and reviewed_at is null
);

create policy "Users can update own pending event publish requests"
on public.event_publish_requests
for update
using (
  auth.uid() = user_id
  and status = 'pending'
)
with check (
  auth.uid() = user_id
  and status = 'pending'
);

create policy "Admins can read all event publish requests"
on public.event_publish_requests
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

create policy "Admins can update event publish requests"
on public.event_publish_requests
for update
using (
  lower(coalesce(auth.jwt()->>'email', '')) = 'darlison.pires.corporativo@gmail.com'
  or exists (
    select 1
    from public.app_admins a
    where a.user_id = auth.uid()
      and a.is_active = true
  )
)
with check (
  lower(coalesce(auth.jwt()->>'email', '')) = 'darlison.pires.corporativo@gmail.com'
  or exists (
    select 1
    from public.app_admins a
    where a.user_id = auth.uid()
      and a.is_active = true
  )
);

-- 2) Tabela de permissões de publicação de eventos
create table if not exists public.event_publish_permissions (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  is_active boolean not null default true,
  granted_by uuid references public.profiles(id) on delete set null,
  granted_at timestamptz not null default now(),
  revoked_by uuid references public.profiles(id) on delete set null,
  revoked_at timestamptz
);

alter table public.event_publish_permissions enable row level security;

drop policy if exists "Users can read own event publish permission" on public.event_publish_permissions;
drop policy if exists "Admins can read all event publish permissions" on public.event_publish_permissions;
drop policy if exists "Admins can insert event publish permissions" on public.event_publish_permissions;
drop policy if exists "Admins can update event publish permissions" on public.event_publish_permissions;

create policy "Users can read own event publish permission"
on public.event_publish_permissions
for select
using (auth.uid() = user_id);

create policy "Admins can read all event publish permissions"
on public.event_publish_permissions
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

create policy "Admins can insert event publish permissions"
on public.event_publish_permissions
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

create policy "Admins can update event publish permissions"
on public.event_publish_permissions
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
    where p.id = event_publish_permissions.user_id
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
    where p.id = event_publish_permissions.user_id
      and lower(coalesce(p.email, '')) = 'darlison.pires.corporativo@gmail.com'
  )
);

-- Backfill: usuários já aprovados para publicação de eventos
insert into public.event_publish_permissions (user_id, is_active, granted_at)
select distinct r.user_id, true, now()
from public.event_publish_requests r
where r.status = 'approved'
on conflict (user_id) do update
set
  is_active = true,
  revoked_by = null,
  revoked_at = null;

-- Backfill: usuários que já possuem evento publicado
insert into public.event_publish_permissions (user_id, is_active, granted_at)
select distinct e.user_id, true, now()
from public.eventos e
on conflict (user_id) do update
set
  is_active = true,
  revoked_by = null,
  revoked_at = null;

select 'Setup de permissão de publicação de eventos aplicado com sucesso.' as status;