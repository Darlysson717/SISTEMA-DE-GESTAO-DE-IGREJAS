-- Adiciona colunas para registrar consentimento dos termos de uso
alter table public.profiles
add column if not exists consent_accepted boolean not null default false,
add column if not exists consent_accepted_at timestamptz,
add column if not exists consent_terms_version text;