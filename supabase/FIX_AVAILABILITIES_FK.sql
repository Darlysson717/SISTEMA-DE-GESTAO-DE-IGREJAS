-- CORREÇÃO: professional_availabilities deve referenciar profiles, não professional_profiles

-- 1. Remover a FK antiga
ALTER TABLE public.professional_availabilities
DROP CONSTRAINT IF EXISTS professional_availabilities_professional_id_fkey;

-- 2. Adicionar a FK correta para profiles
ALTER TABLE public.professional_availabilities
ADD CONSTRAINT professional_availabilities_professional_id_fkey
FOREIGN KEY (professional_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- 3. Também corrigir a FK na tabela appointments
ALTER TABLE public.appointments
DROP CONSTRAINT IF EXISTS appointments_professional_id_fkey;

ALTER TABLE public.appointments
ADD CONSTRAINT appointments_professional_id_fkey
FOREIGN KEY (professional_id) REFERENCES public.profiles(id) ON DELETE RESTRICT;

-- 4. Verificar se agora podemos inserir availabilities
-- Teste: tentar inserir uma availability de exemplo
-- INSERT INTO professional_availabilities (professional_id, day_of_week, start_time, end_time)
-- VALUES ('some-user-id', 1, '08:00:00'::TIME, '12:00:00'::TIME);