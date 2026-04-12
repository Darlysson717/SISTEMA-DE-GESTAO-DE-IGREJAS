-- Fluxo de solicitação para primeira publicação de serviço
-- Execute no SQL Editor do Supabase

create table if not exists public.service_publish_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  requester_name text not null,
  service_name text not null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_service_publish_requests_user
on public.service_publish_requests(user_id, created_at desc);

create index if not exists idx_service_publish_requests_status
on public.service_publish_requests(status, created_at asc);

create unique index if not exists idx_unique_pending_service_publish_request
on public.service_publish_requests(user_id)
where status = 'pending';

drop trigger if exists trg_service_publish_requests_updated_at on public.service_publish_requests;
create trigger trg_service_publish_requests_updated_at
before update on public.service_publish_requests
for each row execute function public.handle_updated_at();

alter table public.service_publish_requests enable row level security;

drop policy if exists "Users can read own service publish requests" on public.service_publish_requests;
drop policy if exists "Users can insert own service publish requests" on public.service_publish_requests;
drop policy if exists "Users can update own pending service publish requests" on public.service_publish_requests;
drop policy if exists "Admins can read all service publish requests" on public.service_publish_requests;
drop policy if exists "Admins can update service publish requests" on public.service_publish_requests;

create policy "Users can read own service publish requests"
on public.service_publish_requests
for select
using (auth.uid() = user_id);

create policy "Users can insert own service publish requests"
on public.service_publish_requests
for insert
with check (
  auth.uid() = user_id
  and status = 'pending'
  and reviewed_by is null
  and reviewed_at is null
);

create policy "Users can update own pending service publish requests"
on public.service_publish_requests
for update
using (
  auth.uid() = user_id
  and status = 'pending'
)
with check (
  auth.uid() = user_id
  and status = 'pending'
);

create policy "Admins can read all service publish requests"
on public.service_publish_requests
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

create policy "Admins can update service publish requests"
on public.service_publish_requests
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

select 'Setup de solicitação de publicação aplicado com sucesso.' as status;
