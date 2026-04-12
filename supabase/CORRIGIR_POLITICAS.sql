-- SCRIPT SIMPLES PARA CORRIGIR POLÍTICAS DUPLICADAS
-- Execute este script no SQL Editor do Supabase

-- REMOVER POLÍTICAS DUPLICADAS
DROP POLICY IF EXISTS "Users can upload their own service images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view service images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own service images" ON storage.objects;

-- RECRIAR POLÍTICAS
CREATE POLICY "Users can upload their own service images"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'servicos_images'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Anyone can view service images"
ON storage.objects
FOR SELECT
USING (bucket_id = 'servicos_images');

CREATE POLICY "Users can delete their own service images"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'servicos_images'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- CONFIRMAÇÃO
SELECT 'Políticas corrigidas com sucesso!' as status;