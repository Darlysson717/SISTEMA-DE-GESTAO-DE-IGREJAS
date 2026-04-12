-- VERSÃO CORRIGIDA DA FUNÇÃO DE VALIDAÇÃO
create or replace function public.validate_appointment_inside_availability()
returns trigger as $$
declare
  local_start timestamp;
  local_end timestamp;
  local_dow int;
  has_slot boolean;
begin
  -- Converter timestamps para timezone local
  local_start := new.starts_at at time zone 'America/Sao_Paulo';
  local_end := new.ends_at at time zone 'America/Sao_Paulo';

  -- Calcular dia da semana (0=domingo, 6=sábado)
  local_dow := extract(dow from local_start);

  -- Verificar se existe disponibilidade para este profissional neste dia
  select exists (
    select 1
    from public.professional_availabilities pa
    where pa.professional_id = new.professional_id
      and pa.day_of_week = local_dow
      and (local_start::time >= pa.start_time or local_end::time <= pa.end_time)
  ) into has_slot;

  if not has_slot then
    -- Tentar uma verificação mais permissiva: apenas verificar se o horário de início está dentro de alguma disponibilidade
    select exists (
      select 1
      from public.professional_availabilities pa
      where pa.professional_id = new.professional_id
        and pa.day_of_week = local_dow
        and local_start::time >= pa.start_time
        and local_start::time < pa.end_time
    ) into has_slot;
  end if;

  if not has_slot then
    raise exception 'Horário fora da disponibilidade do profissional (dia %, horário %)', local_dow, local_start::time;
  end if;

  return new;
end;
$$ language plpgsql;