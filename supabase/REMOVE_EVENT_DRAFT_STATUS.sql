-- Remove suporte a rascunho em public.eventos
-- Execute no SQL Editor do Supabase em ambientes ja provisionados

-- 1) Converte rascunhos existentes para publicados
update public.eventos
set
  status = 'publicado',
  publicado_em = coalesce(publicado_em, now())
where status = 'rascunho';

-- 2) Ajusta valor padrao de status
alter table public.eventos
alter column status set default 'publicado';

-- 3) Recria check constraint de status sem rascunho
alter table public.eventos
drop constraint if exists eventos_status_check;

alter table public.eventos
add constraint eventos_status_check
check (status in ('agendado', 'publicado', 'cancelado'));

select 'Status rascunho removido com sucesso.' as status;
