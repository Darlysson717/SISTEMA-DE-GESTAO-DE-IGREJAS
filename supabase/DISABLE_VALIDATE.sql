-- DESABILITAR VALIDAÇÃO TEMPORARIAMENTE PARA TESTAR
create or replace function public.validate_appointment_inside_availability()
returns trigger as $$
begin
  -- Validação desabilitada temporariamente para debug
  return new;
end;
$$ language plpgsql;