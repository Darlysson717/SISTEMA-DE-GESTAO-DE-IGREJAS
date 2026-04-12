-- Remove imagens órfãs do bucket servicos_images
-- Órfã = arquivo no Storage não referenciado por nenhum registro em public.servicos.imagem_profissional
-- Execute no SQL Editor do Supabase
-- IMPORTANTE: exclusão direta em storage.objects é bloqueada pelo Supabase.
-- Use este SQL apenas para diagnóstico e execute a limpeza via Storage API:
-- dart run tool/clean_orphan_service_images.dart --apply

-- Pré-visualização das imagens órfãs
WITH referenced_images AS (
  SELECT DISTINCT
    split_part(
      CASE
        WHEN imagem_profissional LIKE '%/servicos_images/%' THEN split_part(imagem_profissional, '/servicos_images/', 2)
        ELSE imagem_profissional
      END,
      '?',
      1
    ) AS image_path
  FROM public.servicos
  WHERE imagem_profissional IS NOT NULL
    AND btrim(imagem_profissional) <> ''
), orphan_images AS (
  SELECT o.name
  FROM storage.objects o
  WHERE o.bucket_id = 'servicos_images'
    AND o.name <> '.emptyFolderPlaceholder'
    AND o.name NOT LIKE '%/.emptyFolderPlaceholder'
    AND NOT EXISTS (
      SELECT 1
      FROM referenced_images r
      WHERE r.image_path = o.name
    )
)
SELECT name AS orphan_image_path
FROM orphan_images
ORDER BY name;
