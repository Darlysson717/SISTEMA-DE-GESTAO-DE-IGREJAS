-- SCRIPT PARA RESTAURAR POLÍTICAS DE SEGURANÇA CORRETAS
-- Execute este script APÓS testar o upload com as políticas temporárias

-- REMOVER POLÍTICAS TEMPORÁRIAS
DROP POLICY IF EXISTS "Allow all uploads to service images" ON storage.objects;
DROP POLICY IF EXISTS "Allow all views of service images" ON storage.objects;

-- CRIAR POLÍTICAS DEFINITIVAS E SEGURAS
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

-- Bucket público não precisa de policy SELECT em storage.objects.

-- VERIFICAÇÃO
SELECT 'Políticas de segurança restauradas com sucesso!' as status;