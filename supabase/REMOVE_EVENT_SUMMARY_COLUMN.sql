-- Remove a coluna resumo_curto da tabela public."EVENTOS"
-- Execute no SQL Editor do Supabase em ambientes ja provisionados

alter table public."eventos"
  drop column if exists resumo_curto;

select 'Coluna resumo_curto removida com sucesso.' as status;
