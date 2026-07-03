-- ============================================================
-- RemindMD — Supabase schema
-- Auth: uses Supabase's built-in auth.users (no custom users table needed)
-- ============================================================

create extension if not exists "pgcrypto";

-- ------------------------------------------------------------
-- ENUMS
-- ------------------------------------------------------------
create type modality as enum ('pharma', 'herbal', 'supplement', 'practice');
create type appt_type as enum ('medical', 'therapy', 'class', 'other');
create type reminder_style as enum ('gentle', 'standard', 'insistent');
create type schedule_kind as enum ('fixed_times', 'interval_days', 'days_of_week', 'as_needed');

-- ------------------------------------------------------------
-- REGIMEN ITEMS  (meds, supplements, herbal, practices)
-- ------------------------------------------------------------
create table regimen_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,

  name text not null,
  modality modality not null,
  dose_note text,

  schedule_kind schedule_kind not null default 'fixed_times',
  fixed_times time[] default '{}',
  interval_days int,
  days_of_week int[],

  reminder_style reminder_style not null default 'standard',
  active boolean not null default true,

  supply_on_hand numeric,
  supply_per_dose numeric,
  supply_unit text,
  supply_reorder_threshold numeric,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_regimen_items_user on regimen_items(user_id);

-- ------------------------------------------------------------
-- APPOINTMENTS  (medical visits, therapy, classes)
-- ------------------------------------------------------------
create table appointments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,

  title text not null,
  type appt_type not null,
  location text,
  notes text,

  start_time timestamptz not null,
  end_time timestamptz,

  recurs boolean not null default false,
  recurrence_days_of_week int[],
  recurrence_interval_days int,

  reminder_lead_minutes int[] not null default '{60}',

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_appointments_user on appointments(user_id);
create index idx_appointments_start on appointments(start_time);

-- ------------------------------------------------------------
-- DOSE LOGS
-- ------------------------------------------------------------
create type dose_status as enum ('taken', 'skipped', 'snoozed');

create table dose_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  regimen_item_id uuid not null references regimen_items(id) on delete cascade,

  scheduled_for timestamptz not null,
  logged_at timestamptz not null default now(),
  status dose_status not null
);

create index idx_dose_logs_item on dose_logs(regimen_item_id, scheduled_for);
create index idx_dose_logs_user_date on dose_logs(user_id, scheduled_for);

-- ------------------------------------------------------------
-- APPOINTMENT ATTENDANCE LOGS
-- ------------------------------------------------------------
create type attendance_status as enum ('attended', 'missed', 'rescheduled');

create table appointment_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  appointment_id uuid not null references appointments(id) on delete cascade,

  occurred_at timestamptz not null,
  status attendance_status not null,
  notes text
);

create index idx_appt_logs_appt on appointment_logs(appointment_id);

-- ------------------------------------------------------------
-- updated_at trigger helper
-- ------------------------------------------------------------
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_regimen_items_updated
  before update on regimen_items
  for each row execute function set_updated_at();

create trigger trg_appointments_updated
  before update on appointments
  for each row execute function set_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table regimen_items enable row level security;
alter table appointments enable row level security;
alter table dose_logs enable row level security;
alter table appointment_logs enable row level security;

create policy "own regimen items" on regimen_items
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own appointments" on appointments
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own dose logs" on dose_logs
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own appointment logs" on appointment_logs
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- Convenience view: "today" feed
-- ============================================================
create or replace view today_feed as
select
  'dose' as kind,
  ri.id as source_id,
  ri.user_id,
  ri.name as title,
  ri.modality::text as category,
  t as scheduled_time
from regimen_items ri,
     unnest(ri.fixed_times) as t
where ri.active and ri.schedule_kind = 'fixed_times'

union all

select
  'appointment' as kind,
  a.id as source_id,
  a.user_id,
  a.title,
  a.type::text as category,
  a.start_time::time as scheduled_time
from appointments a
where a.start_time::date = current_date;

alter view today_feed set (security_invoker = true);
