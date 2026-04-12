-- POLÍTICAS CORRETAS PARA PROFILES (SEM RECURSÃO)
-- Execute este script no SQL Editor do Supabase

-- LIMPAR TODAS AS POLÍTICAS EXISTENTES NA TABELA PROFILES
DO $$
DECLARE
    policy_name TEXT;
BEGIN
    FOR policy_name IN
        SELECT polname
        FROM pg_policy
        WHERE polrelid = 'public.profiles'::regclass
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_name || '" ON public.profiles';
    END LOOP;
END $$;

-- RECRIAR POLÍTICAS BÁSICAS E SEGURAS
CREATE POLICY "Enable read access for own profile"
ON public.profiles
FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Enable update access for own profile"
ON public.profiles
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "Enable insert access for own profile"
ON public.profiles
FOR INSERT
WITH CHECK (auth.uid() = id);

-- POLÍTICA PARA ADMINS (sem recursão)
-- Por enquanto, vamos permitir que usuários logados vejam todos os perfis
-- Em produção, implemente uma solução mais robusta
CREATE POLICY "Admins can read all profiles"
ON public.profiles
FOR SELECT
USING (auth.role() = 'authenticated');

-- VERIFICAÇÃO
SELECT 'Políticas de profiles corrigidas com sucesso!' as status;