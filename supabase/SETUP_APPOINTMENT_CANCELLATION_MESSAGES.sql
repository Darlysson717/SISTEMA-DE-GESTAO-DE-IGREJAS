-- Mensagens de cancelamento para o usuário afetado
-- Mantém histórico leve de aviso mesmo removendo o agendamento da tabela principal.

create table if not exists public.appointment_cancellation_messages (
  id uuid primary key default gen_random_uuid(),
  recipient_user_id uuid not null references public.profiles(id) on delete cascade,
  message text not null,
  scheduled_at timestamptz,
  professional_name text,
  specialty text,
  location text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.appointment_cancellation_messages
add column if not exists scheduled_at timestamptz;

alter table public.appointment_cancellation_messages
add column if not exists professional_name text;

alter table public.appointment_cancellation_messages
add column if not exists specialty text;

alter table public.appointment_cancellation_messages
add column if not exists location text;

alter table public.appointment_cancellation_messages enable row level security;

drop policy if exists "Users read own cancellation messages" on public.appointment_cancellation_messages;
drop policy if exists "Authenticated can insert cancellation messages" on public.appointment_cancellation_messages;
drop policy if exists "Users update own cancellation messages" on public.appointment_cancellation_messages;

create policy "Users read own cancellation messages"
on public.appointment_cancellation_messages
for select
using (auth.uid() = recipient_user_id);

create policy "Authenticated can insert cancellation messages"
on public.appointment_cancellation_messages
for insert
with check (auth.uid() is not null);

create policy "Users update own cancellation messages"
on public.appointment_cancellation_messages
for update
using (auth.uid() = recipient_user_id)
with check (auth.uid() = recipient_user_id);

create index if not exists idx_appointment_cancellation_messages_recipient
on public.appointment_cancellation_messages(recipient_user_id, is_read, created_at desc);

select 'Mensagens de cancelamento habilitadas com sucesso.' as status;
