-- VERSÃO MODIFICADA DA FUNÇÃO PARA DEBUG
-- Temporariamente desabilitar a validação para testar
create or replace function public.validate_appointment_inside_availability()
returns trigger as $$
declare
  local_start timestamp;
  local_end timestamp;
  local_dow int;
  has_slot boolean;
begin
  -- Para debug, vamos logar as informações
  local_start := new.starts_at at time zone 'America/Sao_Paulo';
  local_end := new.ends_at at time zone 'America/Sao_Paulo';
  local_dow := extract(dow from local_start);

  raise notice 'DEBUG: Validating appointment for professional %, dow %, start %, end %',
    new.professional_id, local_dow, local_start::time, local_end::time;

  select exists (
    select 1
    from public.professional_availabilities pa
    where pa.professional_id = new.professional_id
      and pa.day_of_week = local_dow
      and local_start::time >= pa.start_time
      and local_end::time <= pa.end_time
  ) into has_slot;

  raise notice 'DEBUG: Has slot: %, availabilities found: %',
    has_slot,
    (select count(*) from public.professional_availabilities pa where pa.professional_id = new.professional_id and pa.day_of_week = local_dow);

  if not has_slot then
    raise exception 'Horário fora da disponibilidade do profissional (dow=%, start=%, end=%)', local_dow, local_start::time, local_end::time;
  end if;

  return new;
end;
$$ language plpgsql;