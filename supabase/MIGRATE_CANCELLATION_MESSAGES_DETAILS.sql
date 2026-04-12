-- Migração para mensagens de cancelamento com detalhes do agendamento

alter table public.appointment_cancellation_messages
add column if not exists scheduled_at timestamptz;

alter table public.appointment_cancellation_messages
add column if not exists professional_name text;

alter table public.appointment_cancellation_messages
add column if not exists specialty text;

alter table public.appointment_cancellation_messages
add column if not exists location text;

select 'Campos de detalhes das mensagens de cancelamento adicionados com sucesso.' as status;
