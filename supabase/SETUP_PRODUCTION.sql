-- SETUP COMPLETO PARA PRODUÇÃO - CENTRO SOCIAL APP
-- Execute este script no SQL Editor do Supabase para recriar todas as tabelas essenciais

-- Extensões necessárias
create extension if not exists "pgcrypto";
create extension if not exists "btree_gist";

-- Função para updated_at
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Tabela profiles (usuários)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  role text not null default 'community' check (role in ('admin', 'volunteer', 'community')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.handle_updated_at();

alter table public.profiles enable row level security;

drop policy if exists "Users can read own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;
drop policy if exists "Admins can read all profiles" on public.profiles;

create policy "Users can read own profile"
on public.profiles
for select
using (auth.uid() = id);

create policy "Users can update own profile"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "Users can insert own profile"
on public.profiles
for insert
with check (auth.uid() = id);

create policy "Admins can read all profiles"
on public.profiles
for select
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
);

-- Tabela servicos (serviços oferecidos por qualquer usuário)
create table if not exists public.servicos (
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
create table if not exists public.servicos (
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

-- Bucket para imagens dos serviços
insert into storage.buckets (id, name, public)
values ('servicos_images', 'servicos_images', true)
on conflict (id) do nothing;

-- Políticas para o bucket
drop policy if exists "Users can upload their own service images" on storage.objects;
drop policy if exists "Anyone can view service images" on storage.objects;

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

-- Mensagem de sucesso
select 'Setup simplificado realizado com sucesso! Qualquer usuário pode criar serviços.' as status;