-- Validação: um agendamento por servico no dia e sem conflito de horario

create or replace function public.validate_appointment_rules()
returns trigger as $$
declare
  conflict_count int;
  same_service_count int;
begin
  -- Impede mais de um agendamento do mesmo servico no mesmo dia
  select count(*)
  into same_service_count
  from public.appointments
  where user_id = new.user_id
    and service_id = new.service_id
    and scheduled_date = new.scheduled_date
    and status != 'cancelled'
    and id != coalesce(new.id, ''::uuid);

  if same_service_count > 0 then
    raise exception 'Você já possui um agendamento para este serviço neste dia.';
  end if;

  -- Impede conflito de horario no mesmo dia para o mesmo usuario
  select count(*)
  into conflict_count
  from public.appointments
  where user_id = new.user_id
    and scheduled_date = new.scheduled_date
    and scheduled_time = new.scheduled_time
    and status != 'cancelled'
    and id != coalesce(new.id, ''::uuid);

  if conflict_count > 0 then
    raise exception 'Você já possui um agendamento neste mesmo horário.';
  end if;

  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_validate_one_appointment_per_day on public.appointments;
drop trigger if exists trg_validate_appointment_rules on public.appointments;

create trigger trg_validate_appointment_rules
before insert or update of scheduled_date, scheduled_time, user_id, service_id, status
on public.appointments
for each row
when (new.status != 'cancelled')
execute function public.validate_appointment_rules();