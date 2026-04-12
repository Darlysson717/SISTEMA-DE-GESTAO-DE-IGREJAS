-- SCRIPT PARA DIAGNOSTICAR E CORRIGIR PROBLEMA DE RLS NO STORAGE
-- Execute este script no SQL Editor do Supabase

-- 1. VERIFICAR POLÍTICAS ATUAIS
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'objects' AND policyname LIKE '%service%';

-- 2. VERIFICAR SE O BUCKET EXISTE
SELECT id, name, public FROM storage.buckets WHERE id = 'servicos_images';

-- 3. REMOVER POLÍTICAS PROBLEMÁTICAS
DROP POLICY IF EXISTS "Users can upload their own service images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view service images" ON storage.objects;

-- 4. CRIAR POLÍTICAS MAIS PERMISSIVAS TEMPORARIAMENTE
-- (REMOVER ESTA POLÍTICA DEPOIS DE TESTAR E USAR A DEFINITIVA)
CREATE POLICY "Allow all uploads to service images"
ON storage.objects
FOR INSERT
WITH CHECK (bucket_id = 'servicos_images');

CREATE POLICY "Allow all views of service images"
ON storage.objects
FOR SELECT
USING (bucket_id = 'servicos_images');

-- 5. POLÍTICA DEFINITIVA (mais segura - descomente depois de testar)
-- CREATE POLICY "Users can upload their own service images"
-- ON storage.objects
-- FOR INSERT
-- WITH CHECK (
--   bucket_id = 'servicos_images'
--   AND auth.uid()::text = (storage.foldername(name))[1]
-- );

-- 6. VERIFICAÇÃO
SELECT 'Políticas temporárias criadas. Teste o upload e depois execute o próximo script.' as status;