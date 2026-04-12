-- =====================================================
-- SETUP DE INSCRICOES DE EVENTOS (PARTICIPANTES/VOLUNTARIOS)
-- =====================================================

create table if not exists public.event_registrations (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.eventos(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  interesse text not null check (interesse in ('participante', 'voluntario')),
  volunteer_whatsapp text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (interesse <> 'voluntario' or volunteer_whatsapp is not null),
  unique (event_id, user_id)
);

create index if not exists idx_event_registrations_event_id
  on public.event_registrations(event_id);

create index if not exists idx_event_registrations_event_interest
  on public.event_registrations(event_id, interesse);

create or replace function public.set_event_registrations_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists trg_event_registrations_updated_at on public.event_registrations;
create trigger trg_event_registrations_updated_at
before update on public.event_registrations
for each row
execute function public.set_event_registrations_updated_at();

alter table public.event_registrations enable row level security;

-- O usuario pode ver as proprias inscricoes.
drop policy if exists "Users can view own registrations" on public.event_registrations;
create policy "Users can view own registrations"
on public.event_registrations
for select
using (auth.uid() = user_id);

-- O dono do evento pode ver todos os inscritos do proprio evento.
drop policy if exists "Owners can view registrations from own events" on public.event_registrations;
create policy "Owners can view registrations from own events"
on public.event_registrations
for select
using (
  exists (
    select 1
    from public.eventos e
    where e.id = event_id
      and e.user_id = auth.uid()
  )
);

-- Administradores tambem podem ver tudo (mesmo padrao ja usado no projeto).
drop policy if exists "Admins can view all registrations" on public.event_registrations;
create policy "Admins can view all registrations"
on public.event_registrations
for select
using (
  exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.email in (
        '<PRIVATE_EMAIL>',
        '<PRIVATE_EMAIL>'
      )
  )
);

-- O usuario autenticado pode inserir/atualizar/excluir apenas a propria inscricao.
drop policy if exists "Users can insert own registrations" on public.event_registrations;
create policy "Users can insert own registrations"
on public.event_registrations
for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can update own registrations" on public.event_registrations;
create policy "Users can update own registrations"
on public.event_registrations
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own registrations" on public.event_registrations;
create policy "Users can delete own registrations"
on public.event_registrations
for delete
using (auth.uid() = user_id);
