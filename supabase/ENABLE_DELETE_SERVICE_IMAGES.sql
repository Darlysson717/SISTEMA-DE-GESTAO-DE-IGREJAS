-- Permite que o dono da imagem exclua arquivos no bucket servicos_images
-- Execute este script no SQL Editor do Supabase

DROP POLICY IF EXISTS "Users can delete their own service images" ON storage.objects;

CREATE POLICY "Users can delete their own service images"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'servicos_images'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

SELECT 'Policy de DELETE para imagens de serviços criada com sucesso.' AS status;
