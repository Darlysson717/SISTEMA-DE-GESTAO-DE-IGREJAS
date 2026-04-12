-- Adiciona campo para armazenar a foto da conta Google no perfil

alter table public.profiles
add column if not exists avatar_url text;

select 'Campo avatar_url adicionado em profiles com sucesso.' as status;
