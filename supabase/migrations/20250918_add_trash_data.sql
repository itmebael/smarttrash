-- Table for smart trashcan monitoring
create table trash_data (
  id bigint generated always as identity primary key,
  created_at timestamp with time zone default now(),
  distance numeric not null, -- ultrasonic reading in cm
  level text check (level in ('Normal', 'Medium', 'Full')) not null,
  latitude double precision, -- from GPS module
  longitude double precision, -- from GPS module
  trashcan_id text not null -- unique ID per trashcan
);

-- Enable row level security
alter table trash_data enable row level security;

-- Allow ESP32 (anon key) to insert data
create policy "Allow insert from anon"
on trash_data for insert
to anon
with check (true);

-- Allow reading data (for your app dashboard / map)
create policy "Allow select for anon"
on trash_data for select
to anon
using (true);
