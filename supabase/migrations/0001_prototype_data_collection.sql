-- baibars FleetCare — prototip veri toplama şeması (v0)
-- Bu dosyayı Supabase panelinde SQL Editor'e yapıştırıp çalıştırın.
--
-- DİKKAT: Buradaki "anon" politikaları YALNIZCA prototip demosu içindir.
-- Faz 1'de e-posta+OTP auth geldiğinde bu politikalar kaldırılıp
-- kullanıcı-bazlı RLS politikaları yazılacaktır (bkz. CLAUDE.md).

-- 1) Hava araçları -----------------------------------------------------------
create table if not exists aircraft (
  id uuid primary key default gen_random_uuid(),
  serial_no text not null unique,
  model text not null default 'CT110',
  total_sorties integer not null default 0,
  total_flight_hours numeric(10,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2) Uçuş kayıtları ----------------------------------------------------------
create table if not exists flights (
  id uuid primary key default gen_random_uuid(),
  aircraft_id uuid not null references aircraft(id),
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  duration_min numeric(6,1),
  sortie_count_increment integer not null default 1,
  area_covered_da numeric(8,1),
  params jsonb,
  created_at timestamptz not null default now()
);

-- 3) Prototip olay günlüğü ---------------------------------------------------
-- Tasarım prototipindeki her buton/ekran etkileşimi buraya düşer.
-- Gerçek uygulamada bu tablo yerine alanına uygun tablolar kullanılır.
create table if not exists prototype_events (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,          -- ör. 'sortie_logged', 'maintenance_done'
  payload jsonb,                     -- serbest veri (kişisel veri YAZMAYIN — KVKK)
  client_id text,                    -- cihaz/oturum ayırt etmek için rastgele kimlik
  created_at timestamptz not null default now()
);

-- Uçuş eklenince sayaçları otomatik güncelle ---------------------------------
create or replace function bump_aircraft_counters()
returns trigger language plpgsql as $$
begin
  update aircraft
     set total_sorties = total_sorties + coalesce(new.sortie_count_increment, 1),
         total_flight_hours = total_flight_hours + coalesce(new.duration_min, 0) / 60.0,
         updated_at = now()
   where id = new.aircraft_id;
  return new;
end $$;

drop trigger if exists trg_bump_counters on flights;
create trigger trg_bump_counters
  after insert on flights
  for each row execute function bump_aircraft_counters();

-- RLS ------------------------------------------------------------------------
alter table aircraft enable row level security;
alter table flights enable row level security;
alter table prototype_events enable row level security;

-- DEMO politikaları (Faz 1'de kaldırılacak):
create policy "demo anon read aircraft"  on aircraft  for select to anon using (true);
create policy "demo anon read flights"   on flights   for select to anon using (true);
create policy "demo anon add flight"     on flights   for insert to anon with check (true);
create policy "demo anon add event"      on prototype_events for insert to anon with check (true);

-- Demo verisi: bir adet CT110 ------------------------------------------------
insert into aircraft (serial_no, model)
values ('CT110-2026-0001', 'CT110')
on conflict (serial_no) do nothing;
