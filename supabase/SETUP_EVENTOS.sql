-- Setup completo para eventos
-- Execute no SQL Editor do Supabase

-- 1) Bucket para imagens de eventos
insert into storage.buckets (id, name, public)
values ('eventos_images', 'eventos_images', true)
on conflict (id) do nothing;

-- Politicas de storage para eventos
-- Estrutura esperada do path: <user_id>/<arquivo>
drop policy if exists "Users can upload their own event images" on storage.objects;
drop policy if exists "Anyone can view event images" on storage.objects;
drop policy if exists "Users can delete their own event images" on storage.objects;

create policy "Users can upload their own event images"
on storage.objects
for insert
with check (
  bucket_id = 'eventos_images'
  and auth.uid()::text = (storage.foldername(name))[1]
);

create policy "Anyone can view event images"
on storage.objects
for select
using (bucket_id = 'eventos_images');

create policy "Users can delete their own event images"
on storage.objects
for delete
using (
  bucket_id = 'eventos_images'
  and auth.uid()::text = (storage.foldername(name))[1]
);

-- 2) Tabela de eventos
create table if not exists public.eventos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,

  -- Informacoes principais
  nome text not null,
  categoria text not null,
  publico_alvo text[] not null default '{}',

  -- Data e horario
  data_inicio date not null,
  data_fim date not null,
  hora_inicio time,
  hora_fim time,
  dia_inteiro boolean not null default false,
  repeticao text not null default 'sem_repeticao'
    check (repeticao in ('sem_repeticao', 'semanal', 'mensal')),

  -- Local
  tipo_local text not null default 'presencial'
    check (tipo_local in ('presencial', 'online', 'hibrido')),
  endereco text,
  link_transmissao text,

  -- Conteudo
  descricao text not null,

  -- Midia
  imagem_capa_url text,
  galeria_imagens_urls text[] not null default '{}',

  -- Inscricao e vagas
  evento_pago boolean not null default false,
  limite_vagas integer,
  requer_inscricao boolean not null default false,
  link_inscricao text,

  -- Voluntariado
  permitir_voluntarios boolean not null default false,
  quantidade_voluntarios integer,
  atividades_voluntarios text,

  -- Acessibilidade e contato
  acessibilidade text,
  contato_nome text not null,
  contato_telefone text not null,
  contato_email text,

  -- Publicacao
  agendar_publicacao boolean not null default false,
  publicado_em timestamptz,
  status text not null default 'publicado'
    check (status in ('agendado', 'publicado', 'cancelado')),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- Regras de consistencia
  check (data_inicio <= data_fim),
  check (dia_inteiro = true or hora_inicio is null or hora_fim is null or hora_inicio < hora_fim),
  check (limite_vagas is null or limite_vagas > 0),
  check (quantidade_voluntarios is null or quantidade_voluntarios >= 0),
  check (agendar_publicacao = false or publicado_em is not null)
);

-- Trigger de updated_at (usa funcao global ja existente no projeto)
drop trigger if exists trg_eventos_updated_at on public.eventos;
create trigger trg_eventos_updated_at
before update on public.eventos
for each row execute function public.handle_updated_at();

-- Indices
create index if not exists idx_eventos_user_created
on public.eventos (user_id, created_at desc);

create index if not exists idx_eventos_status_publicado_em
on public.eventos (status, publicado_em asc);

create index if not exists idx_eventos_data_inicio
on public.eventos (data_inicio asc);

-- 3) RLS
alter table public.eventos enable row level security;

drop policy if exists "Users can read own events" on public.eventos;
drop policy if exists "Users can insert own events" on public.eventos;
drop policy if exists "Users can update own events" on public.eventos;
drop policy if exists "Users can delete own events" on public.eventos;
drop policy if exists "Anyone can read published events" on public.eventos;
drop policy if exists "Admins can read all events" on public.eventos;
drop policy if exists "Admins can manage all events" on public.eventos;

create policy "Users can read own events"
on public.eventos
for select
using (auth.uid() = user_id);

create policy "Users can insert own events"
on public.eventos
for insert
with check (auth.uid() = user_id);

create policy "Users can update own events"
on public.eventos
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own events"
on public.eventos
for delete
using (auth.uid() = user_id);

create policy "Anyone can read published events"
on public.eventos
for select
using (
  status = 'publicado'
  and (publicado_em is null or publicado_em <= now())
);

create policy "Admins can read all events"
on public.eventos
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

create policy "Admins can manage all events"
on public.eventos
for all
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

select 'Setup de eventos aplicado com sucesso.' as status;
