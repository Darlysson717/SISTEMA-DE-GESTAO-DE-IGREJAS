-- INSTRUÇÕES PARA RESOLVER OS PROBLEMAS:
-- 1. Execute este script no SQL Editor do Supabase (https://supabase.com/dashboard/project/YOUR_PROJECT/sql)
-- 2. Vá para Storage no painel lateral e verifique se o bucket 'servicos_images' foi criado
-- 3. Certifique-se de que você está logado no app antes de tentar publicar um serviço

-- Criar bucket para imagens dos serviços
insert into storage.buckets (id, name, public)
values ('servicos_images', 'servicos_images', true)
on conflict (id) do nothing;

-- Políticas para o bucket
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

-- Criar tabela servicos (se não existir)
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
  status text not null default 'pendente' check (status in ('pendente', 'aprovado', 'rejeitado')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Trigger para updated_at
drop trigger if exists trg_servicos_updated_at on public.servicos;
create trigger trg_servicos_updated_at
before update on public.servicos
for each row execute function public.handle_updated_at();

-- RLS
alter table public.servicos enable row level security;

-- Políticas
create policy "Users can read own services"
on public.servicos
for select
using (auth.uid() = user_id);

create policy "Users can insert own services"
on public.servicos
for insert
with check (auth.uid() = user_id);

create policy "Admins can read all services"
on public.servicos
for select
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
);

create policy "Admins can update services"
on public.servicos
for update
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
);