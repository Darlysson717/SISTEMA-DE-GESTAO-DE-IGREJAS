-- SCRIPT PARA VERIFICAR E CORRIGIR CONFIGURAÇÃO DO SUPABASE
-- Execute este script no SQL Editor do Supabase

-- 1. VERIFICAR SE O BUCKET EXISTE
SELECT id, name, public FROM storage.buckets WHERE id = 'servicos_images';

-- 2. VERIFICAR POLÍTICAS DO BUCKET
SELECT schemaname, tablename, policyname FROM pg_policies
WHERE tablename = 'objects' AND policyname LIKE '%service%';

-- 3. VERIFICAR SE A TABELA SERVICOS EXISTE
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_name = 'servicos';

-- 4. SE ALGO ESTIVER FALTANDO, EXECUTE APENAS AS PARTES NECESSÁRIAS:

-- CRIAR BUCKET (só se não existir)
INSERT INTO storage.buckets (id, name, public)
VALUES ('servicos_images', 'servicos_images', true)
ON CONFLICT (id) DO NOTHING;

-- REMOVER POLÍTICAS ANTIGAS SE EXISTIREM (para recriar)
DROP POLICY IF EXISTS "Users can upload their own service images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view service images" ON storage.objects;

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

-- CRIAR TABELA SERVICOS (se não existir)
CREATE TABLE IF NOT EXISTS public.servicos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  nome text NOT NULL,
  categoria text NOT NULL,
  nome_profissional text NOT NULL,
  imagem_profissional text,
  descricao text NOT NULL,
  dias_disponiveis text[] NOT NULL,
  horarios text[] NOT NULL,
  duracao_atendimento int NOT NULL,
  tipo_atendimento text NOT NULL CHECK (tipo_atendimento IN ('presencial', 'online')),
  local text,
  telefone text NOT NULL,
  observacoes text,
  status text NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'aprovado', 'rejeitado')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- TRIGGER PARA UPDATED_AT
DROP TRIGGER IF EXISTS trg_servicos_updated_at ON public.servicos;
CREATE TRIGGER trg_servicos_updated_at
BEFORE UPDATE ON public.servicos
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- RLS
ALTER TABLE public.servicos ENABLE ROW LEVEL SECURITY;

-- REMOVER POLÍTICAS ANTIGAS DA TABELA
DROP POLICY IF EXISTS "Users can read own services" ON public.servicos;
DROP POLICY IF EXISTS "Users can insert own services" ON public.servicos;
DROP POLICY IF EXISTS "Admins can read all services" ON public.servicos;
DROP POLICY IF EXISTS "Admins can update services" ON public.servicos;

-- RECRIAR POLÍTICAS DA TABELA
CREATE POLICY "Users can read own services"
ON public.servicos
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own services"
ON public.servicos
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can read all services"
ON public.servicos
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  )
);

CREATE POLICY "Admins can update services"
ON public.servicos
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  )
);

-- 5. VERIFICAÇÃO FINAL
SELECT 'Configuração completa!' as status;