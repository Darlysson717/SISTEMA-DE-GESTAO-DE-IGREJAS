-- FUNÇÃO PARA CRIAR DISPONIBILIDADES AUTOMATICAMENTE QUANDO SERVIÇO É APROVADO
create or replace function public.create_professional_availabilities_on_service_approval()
returns trigger as $$
declare
  day_str text;
  day_int int;
  horario_str text;
  start_time_str text;
  end_time_str text;
begin
  -- Só processa se o status mudou para 'aprovado'
  if new.status = 'aprovado' and (old.status is null or old.status != 'aprovado') then
    -- Para cada dia disponível
    foreach day_str in array new.dias_disponiveis loop
      -- Converter dia da semana string para int
      case lower(trim(day_str))
        when 'domingo' then day_int := 0;
        when 'segunda' then day_int := 1;
        when 'terça' then day_int := 2;
        when 'quarta' then day_int := 3;
        when 'quinta' then day_int := 4;
        when 'sexta' then day_int := 5;
        when 'sábado' then day_int := 6;
        else continue; -- Pula dias inválidos
      end case;

      -- Para cada horário disponível
      foreach horario_str in array new.horarios loop
        -- Parse do horário (formato: "08:00-12:00")
        if horario_str like '%-%' then
          start_time_str := split_part(trim(horario_str), '-', 1) || ':00';
          end_time_str := split_part(trim(horario_str), '-', 2) || ':00';

          -- Inserir disponibilidade (evita duplicatas)
          insert into public.professional_availabilities (
            professional_id,
            day_of_week,
            start_time,
            end_time
          ) values (
            new.user_id,
            day_int,
            start_time_str::time,
            end_time_str::time
          ) on conflict do nothing; -- Evita duplicatas se já existir
        end if;
      end loop;
    end loop;
  end if;

  return new;
end;
$$ language plpgsql;

-- TRIGGER PARA EXECUTAR A FUNÇÃO QUANDO SERVIÇO É APROVADO
drop trigger if exists trg_create_availabilities_on_service_approval on public.servicos;
create trigger trg_create_availabilities_on_service_approval
after insert or update of status
on public.servicos
for each row
execute function public.create_professional_availabilities_on_service_approval();