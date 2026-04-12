create extension if not exists "pgcrypto";
create extension if not exists "btree_gist";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  role text not null default 'community' check (role in ('admin', 'volunteer', 'community')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.handle_updated_at();

alter table public.profiles enable row level security;

create policy "Users can read own profile"
on public.profiles
for select
using (auth.uid() = id);

create policy "Users can update own profile"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "Users can insert own profile"
on public.profiles
for insert
with check (auth.uid() = id);

create policy "Admins can read all profiles"
on public.profiles
for select
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
);

create table if not exists public.professional_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  specialty text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_professional_profiles_updated_at on public.professional_profiles;
create trigger trg_professional_profiles_updated_at
before update on public.professional_profiles
for each row execute function public.handle_updated_at();

create table if not exists public.professional_availabilities (
  id uuid primary key default gen_random_uuid(),
  professional_id uuid not null references public.professional_profiles(user_id) on delete cascade,
  day_of_week int not null check (day_of_week between 0 and 6),
  start_time time not null,
  end_time time not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (start_time < end_time)
);

drop trigger if exists trg_professional_availabilities_updated_at on public.professional_availabilities;
create trigger trg_professional_availabilities_updated_at
before update on public.professional_availabilities
for each row execute function public.handle_updated_at();

alter table public.professional_availabilities
drop constraint if exists professional_availability_no_overlap;

alter table public.professional_availabilities
add constraint professional_availability_no_overlap
exclude using gist (
  professional_id with =,
  day_of_week with =,
  tsrange(
    ('2000-01-01'::date + start_time)::timestamp,
    ('2000-01-01'::date + end_time)::timestamp,
    '[)'
  ) with &&
);

create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  community_user_id uuid not null references public.profiles(id) on delete restrict,
  professional_id uuid not null references public.professional_profiles(user_id) on delete restrict,
  specialty text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null default 'scheduled' check (status in ('scheduled', 'completed', 'cancelled', 'no_show')),
  notes text,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (starts_at < ends_at)
);

drop trigger if exists trg_appointments_updated_at on public.appointments;
create trigger trg_appointments_updated_at
before update on public.appointments
for each row execute function public.handle_updated_at();

create index if not exists idx_appointments_professional_starts
on public.appointments(professional_id, starts_at);

create index if not exists idx_appointments_community_starts
on public.appointments(community_user_id, starts_at);

alter table public.appointments
drop constraint if exists appointments_no_overlap;

alter table public.appointments
add constraint appointments_no_overlap
exclude using gist (
  professional_id with =,
  tstzrange(starts_at, ends_at, '[)') with &&
)
where (status = 'scheduled');

create or replace function public.validate_appointment_inside_availability()
returns trigger as $$
declare
  local_start timestamp;
  local_end timestamp;
  local_dow int;
  has_slot boolean;
begin
  local_start := new.starts_at at time zone 'America/Sao_Paulo';
  local_end := new.ends_at at time zone 'America/Sao_Paulo';
  local_dow := extract(dow from local_start);

  select exists (
    select 1
    from public.professional_availabilities pa
    where pa.professional_id = new.professional_id
      and pa.day_of_week = local_dow
      and local_start::time >= pa.start_time
      and local_end::time <= pa.end_time
  ) into has_slot;

  if not has_slot then
    raise exception 'Horário fora da disponibilidade do profissional';
  end if;

  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_validate_appointment_inside_availability on public.appointments;
create trigger trg_validate_appointment_inside_availability
before insert or update of starts_at, ends_at, professional_id
on public.appointments
for each row
when (new.status = 'scheduled')
execute function public.validate_appointment_inside_availability();

alter table public.professional_profiles enable row level security;
alter table public.professional_availabilities enable row level security;
alter table public.appointments enable row level security;

create policy "Community reads active professionals"
on public.professional_profiles
for select
using (is_active = true);

create policy "Admin manages professionals"
on public.professional_profiles
for all
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
)
with check (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
);

create policy "Professionals read own record"
on public.professional_profiles
for select
using (auth.uid() = user_id);

create policy "Everyone can read active availabilities"
on public.professional_availabilities
for select
using (true);

create policy "Admin manages availabilities"
on public.professional_availabilities
for all
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
)
with check (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
);

create policy "Professional manages own availabilities"
on public.professional_availabilities
for all
using (auth.uid() = professional_id)
with check (auth.uid() = professional_id);

create policy "Community reads own appointments"
on public.appointments
for select
using (auth.uid() = community_user_id);

create policy "Professional reads own appointments"
on public.appointments
for select
using (auth.uid() = professional_id);

create policy "Admin reads all appointments"
on public.appointments
for select
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
);

create policy "Community creates own appointments"
on public.appointments
for insert
with check (
  auth.uid() = community_user_id
  and auth.uid() = created_by
);

create policy "Community updates own scheduled appointments"
on public.appointments
for update
using (
  auth.uid() = community_user_id
  and status in ('scheduled', 'confirmed')
)
with check (
  auth.uid() = community_user_id
);

create policy "Professional updates own appointments"
on public.appointments
for update
using (auth.uid() = professional_id)
with check (auth.uid() = professional_id);

create policy "Admin updates all appointments"
on public.appointments
for update
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
)
with check (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
);
