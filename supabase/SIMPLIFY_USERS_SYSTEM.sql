-- SIMPLIFICAR SISTEMA DE USUÁRIOS - REMOVER ROLES
-- Todos os usuários serão tratados como 'community'

-- 1. Remover políticas que dependem da coluna role ANTES de remover a coluna
DROP POLICY IF EXISTS "Admin manages professionals" ON public.professional_profiles;
DROP POLICY IF EXISTS "Admin manages availabilities" ON public.professional_availabilities;
DROP POLICY IF EXISTS "Admin reads all appointments" ON public.appointments;
DROP POLICY IF EXISTS "Admin updates all appointments" ON public.appointments;
DROP POLICY IF EXISTS "Admins can read all services" ON public.servicos;
DROP POLICY IF EXISTS "Admins can update services" ON public.servicos;
DROP POLICY IF EXISTS "Admins can read all profiles" ON public.profiles;

-- 2. Agora remover a coluna role
ALTER TABLE public.profiles DROP COLUMN IF EXISTS role;

-- 3. Remover tabela professional_profiles (não necessária)
DROP TABLE IF EXISTS public.professional_profiles CASCADE;

-- 4. Simplificar políticas para profiles
DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;

CREATE POLICY "Users can manage own profile"
ON public.profiles
FOR ALL
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 5. Simplificar políticas para servicos
DROP POLICY IF EXISTS "Users can read approved services" ON public.servicos;
DROP POLICY IF EXISTS "Users can create services" ON public.servicos;
DROP POLICY IF EXISTS "Users can update own services" ON public.servicos;
DROP POLICY IF EXISTS "Users can delete own services" ON public.servicos;

CREATE POLICY "Users can manage own services"
ON public.servicos
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Anyone can read approved services"
ON public.servicos
FOR SELECT
USING (status = 'aprovado');

-- 6. Simplificar políticas para professional_availabilities
DROP POLICY IF EXISTS "Professionals manage own availabilities" ON public.professional_availabilities;
DROP POLICY IF EXISTS "Anyone can read availabilities" ON public.professional_availabilities;

CREATE POLICY "Users can manage own availabilities"
ON public.professional_availabilities
FOR ALL
USING (auth.uid() = professional_id)
WITH CHECK (auth.uid() = professional_id);

CREATE POLICY "Anyone can read availabilities"
ON public.professional_availabilities
FOR SELECT
USING (true);

-- 7. Simplificar políticas para appointments
DROP POLICY IF EXISTS "Users can manage own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Professionals can read own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Admin reads all appointments" ON public.appointments;

CREATE POLICY "Users can manage own appointments"
ON public.appointments
FOR ALL
USING (
  auth.uid() = community_user_id OR
  auth.uid() = professional_id
)
WITH CHECK (
  auth.uid() = community_user_id OR
  auth.uid() = professional_id
);

-- 8. Atualizar função de criação automática de availabilities
-- (remover referência a professional_profiles)
CREATE OR REPLACE FUNCTION public.create_professional_availabilities_on_service_approval()
RETURNS TRIGGER AS $$
DECLARE
  day_str TEXT;
  day_int INT;
  horario_str TEXT;
  start_time_str TEXT;
  end_time_str TEXT;
BEGIN
  -- Só processa se o status mudou para 'aprovado'
  IF NEW.status = 'aprovado' AND (OLD.status IS NULL OR OLD.status != 'aprovado') THEN
    -- Para cada dia disponível
    FOREACH day_str IN ARRAY NEW.dias_disponiveis LOOP
      -- Converter dia da semana string para int
      CASE LOWER(TRIM(day_str))
        WHEN 'domingo' THEN day_int := 0;
        WHEN 'segunda' THEN day_int := 1;
        WHEN 'terça' THEN day_int := 2;
        WHEN 'quarta' THEN day_int := 3;
        WHEN 'quinta' THEN day_int := 4;
        WHEN 'sexta' THEN day_int := 5;
        WHEN 'sábado' THEN day_int := 6;
        ELSE CONTINUE; -- Pula dias inválidos
      END CASE;

      -- Para cada horário disponível
      FOREACH horario_str IN ARRAY NEW.horarios LOOP
        -- Parse do horário (formato: "08:00-12:00")
        IF horario_str LIKE '%-%' THEN
          start_time_str := SPLIT_PART(TRIM(horario_str), '-', 1) || ':00';
          end_time_str := SPLIT_PART(TRIM(horario_str), '-', 2) || ':00';

          -- Inserir disponibilidade (evita duplicatas)
          INSERT INTO public.professional_availabilities (
            professional_id,
            day_of_week,
            start_time,
            end_time
          ) VALUES (
            NEW.user_id,
            day_int,
            start_time_str::TIME,
            end_time_str::TIME
          ) ON CONFLICT DO NOTHING; -- Evita duplicatas se já existir
        END IF;
      END LOOP;
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;