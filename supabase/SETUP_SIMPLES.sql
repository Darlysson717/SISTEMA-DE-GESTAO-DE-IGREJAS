-- SETUP SIMPLIFICADO - CENTRO SOCIAL APP
-- Qualquer usuário pode criar serviços diretamente
-- Execute este script no SQL Editor do Supabase

-- Extensões necessárias
create extension if not exists "pgcrypto";

-- Função para updated_at
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Tabela profiles (todos os usuários)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  role text not null default 'user' check (role in ('admin', 'user')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.handle_updated_at();

-- Desabilitar RLS para profiles (sistema simplificado)
alter table public.profiles disable row level security;

-- Tabela servicos (qualquer usuário pode criar serviços)
drop table if exists public.servicos cascade;
create table public.servicos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  nome text not null,
  categoria text not null,
  nome_profissional text not null,
  imagem_profissional text,
  descricao text not null,
  dias_disponiveis text[] not null,
  horarios text[] not null,
  duracao_atendimento int not null,
  tipo_atendimento text not null check (tipo_atendimento in ('presencial', 'online')),
  local text,
  telefone text not null,
  observacoes text,
  status text not null default 'ativo' check (status in ('ativo', 'inativo')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_servicos_updated_at on public.servicos;
create trigger trg_servicos_updated_at
before update on public.servicos
for each row execute function public.handle_updated_at();

alter table public.servicos enable row level security;

drop policy if exists "Users can manage own services" on public.servicos;
drop policy if exists "Anyone can read active services" on public.servicos;

create policy "Users can manage own services"
on public.servicos
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Anyone can read active services"
on public.servicos
for select
using (status = 'ativo');

-- Tabela appointments (agendamentos simplificados)
drop table if exists public.appointments cascade;
create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.servicos(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  scheduled_date date not null,
  scheduled_time time not null,
  notes text,
  status text not null default 'confirmed' check (status in ('confirmed', 'completed', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(service_id, user_id, scheduled_date), -- Um usuário só pode agendar o mesmo serviço uma vez por dia
  unique(user_id, scheduled_date, scheduled_time) -- Evita conflito de horário entre serviços no mesmo dia
);

drop trigger if exists trg_appointments_updated_at on public.appointments;
create trigger trg_appointments_updated_at
before update on public.appointments
for each row execute function public.handle_updated_at();

alter table public.appointments enable row level security;

drop policy if exists "Users can manage own appointments" on public.appointments;
drop policy if exists "Service providers can view appointments for their services" on public.appointments;

create policy "Users can manage own appointments"
on public.appointments
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Service providers can view appointments for their services"
on public.appointments
for select
using (
  exists (
    select 1 from public.servicos s
    where s.id = service_id and s.user_id = auth.uid()
  )
);

-- Bucket para imagens dos serviços
insert into storage.buckets (id, name, public)
values ('servicos_images', 'servicos_images', true)
on conflict (id) do nothing;

-- Políticas para o bucket
drop policy if exists "Users can upload their own service images" on storage.objects;
drop policy if exists "Anyone can view service images" on storage.objects;
drop policy if exists "Users can delete their own service images" on storage.objects;

create policy "Users can upload their own service images"
on storage.objects
for insert
with check (
  bucket_id = 'servicos_images'
  and auth.uid()::text = (storage.foldername(name))[1]
);

create policy "Anyone can view service images"
on storage.objects
for select
using (bucket_id = 'servicos_images');

create policy "Users can delete their own service images"
on storage.objects
for delete
using (
  bucket_id = 'servicos_images'
  and auth.uid()::text = (storage.foldername(name))[1]
);

-- Mensagem de sucesso
select 'Setup completo! Sistema com agendamentos simplificados.' as status;