-- Adicionar coluna para armazenar token FCM na tabela de perfis
-- Execute este script no Supabase SQL Editor

-- Adicionar coluna fcm_token
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Adicionar comentário na coluna
COMMENT ON COLUMN public.profiles.fcm_token IS 'Token do Firebase Cloud Messaging para push notifications';

-- Criar índice para consultas rápidas (apenas para tokens não nulos)
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token 
ON public.profiles(fcm_token) 
WHERE fcm_token IS NOT NULL;

-- Verificar se a coluna foi criada corretamente
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles' 
    AND column_name = 'fcm_token';

-- Exemplo de consulta para ver tokens cadastrados
-- SELECT id, email, full_name, fcm_token 
-- FROM public.profiles 
-- WHERE fcm_token IS NOT NULL;
