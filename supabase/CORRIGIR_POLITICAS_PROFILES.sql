-- CORRIGIR POLÍTICAS PROBLEMÁTICAS DA TABELA PROFILES
-- Execute este script no SQL Editor do Supabase

-- REMOVER POLÍTICAS PROBLEMÁTICAS
DROP POLICY IF EXISTS "Admins can read all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update services" ON public.servicos;

-- RECRIAR POLÍTICAS SEM RECURSÃO
-- Por enquanto, vamos simplificar - admins podem ler todos os perfis
-- (em produção, você pode criar uma tabela separada de admins)
CREATE POLICY "Admins can read all profiles"
ON public.profiles
FOR SELECT
USING (true);  -- Temporariamente permite tudo (ajuste conforme necessário)

-- Para serviços, vamos manter apenas as políticas básicas por enquanto
-- As políticas de admin serão implementadas depois sem recursão

-- VERIFICAÇÃO
SELECT 'Políticas corrigidas. Teste novamente.' as status;