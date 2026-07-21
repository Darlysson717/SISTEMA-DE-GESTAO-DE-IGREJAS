-- Adiciona coluna de consentimento LGPD à tabela de perfis
alter table public.profiles
add column if not exists consent_accepted boolean not null default false;

-- Adiciona timestamp do consentimento
alter table public.profiles
add column if not exists consent_accepted_at timestamptz;

-- Adiciona versão dos termos que o usuário aceitou (para forçar reconsentimento após atualizações)
alter table public.profiles
add column if not exists consent_terms_version text;

-- Política existente "Users can update own profile" já cobre a atualização desses campos