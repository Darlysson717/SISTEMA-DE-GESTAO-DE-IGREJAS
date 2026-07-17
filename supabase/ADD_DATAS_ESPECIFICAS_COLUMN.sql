-- Adicionar coluna datas_especificas à tabela servicos
-- Permite que profissionais escolham datas específicas em vez de dias da semana fixos

alter table public.servicos
add column if not exists datas_especificas date[];

-- Atualizar a constraint de check para aceitar o novo campo
-- A coluna datas_especificas é opcional, então não precisa de check adicional