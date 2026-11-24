-- Country Card Game: Internet rooms (multiplayer stage 2).
--
-- Run this whole file once in the Supabase dashboard: SQL Editor -> New query
-- -> paste -> Run. It is safe to run again (it updates what already exists).
--
-- Model
--   rooms         one row per room; the host's phone is the referee and writes
--                 the authoritative game state (state jsonb) after every move.
--   room_members  who is in the room (left_at is set when a player leaves).
--   room_moves    move requests from players; only the host reads them.
-- Every player signs in anonymously, so auth.uid() identifies each phone.

-- ---------------------------------------------------------------- tables

create table if not exists public.rooms (
  id         uuid primary key default gen_random_uuid(),
  code       text not null check (code ~ '^[0-9]{3}$'),
  host_id    uuid not null references auth.users (id) on delete cascade,
  status     text not null default 'lobby'
             check (status in ('lobby', 'playing', 'round_over', 'closed')),
  round      integer not null default 0,
  seats      uuid[] not null default '{}',   -- user ids of this round's players, by seat
  state      jsonb,                          -- serialized GameState of the current round
  notice     text,                           -- last room event shown to everyone
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- A code is unique among rooms that are still open; closing a room frees its code.
create unique index if not exists rooms_open_code_idx
  on public.rooms (code) where status <> 'closed';

create table if not exists public.room_members (
  room_id   uuid not null references public.rooms (id) on delete cascade,
  user_id   uuid not null references auth.users (id) on delete cascade,
  name      text not null check (char_length(name) between 1 and 16),
  joined_at timestamptz not null default now(),
  left_at   timestamptz,
  primary key (room_id, user_id)
);

create table if not exists public.room_moves (
  id         bigint generated always as identity primary key,
  room_id    uuid not null references public.rooms (id) on delete cascade,
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  round      integer not null,
  turn       integer not null,
  card_id    text not null check (char_length(card_id) <= 64),
  created_at timestamptz not null default now()
);
create index if not exists room_moves_room_idx on public.room_moves (room_id, round, turn);

-- Keep rooms.updated_at fresh (used to expire abandoned rooms).
create or replace function public.touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists rooms_touch_updated_at on public.rooms;
create trigger rooms_touch_updated_at
  before update on public.rooms
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------- helpers

create or replace function public.is_room_member(p_room uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.room_members m
    where m.room_id = p_room and m.user_id = auth.uid() and m.left_at is null
  );
$$;

create or replace function public.is_room_host(p_room uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.rooms r
    where r.id = p_room and r.host_id = auth.uid()
  );
$$;

-- ---------------------------------------------------------------- room actions

-- Creates a room with a free 3-digit code and adds the caller as host.
create or replace function public.create_room(p_name text)
returns public.rooms language plpgsql security definer set search_path = '' as $$
declare
  v_uid  uuid := auth.uid();
  v_name text := left(btrim(coalesce(p_name, '')), 16);
  v_room public.rooms;
begin
  if v_uid is null then raise exception 'NOT_SIGNED_IN'; end if;
  if v_name = '' then raise exception 'NAME_REQUIRED'; end if;

  -- Housekeeping: close abandoned rooms and this host's previous rooms,
  -- and delete rooms that have been closed for a day.
  update public.rooms set status = 'closed'
   where status <> 'closed'
     and (updated_at < now() - interval '12 hours' or host_id = v_uid);
  delete from public.rooms
   where status = 'closed' and updated_at < now() - interval '1 day';

  for i in 1..60 loop
    begin
      insert into public.rooms (code, host_id)
      values ((100 + floor(random() * 900))::int::text, v_uid)
      returning * into v_room;
      exit;
    exception when unique_violation then
      -- that code is in use; try another
    end;
  end loop;
  if v_room.id is null then raise exception 'NO_FREE_CODE'; end if;

  insert into public.room_members (room_id, user_id, name)
  values (v_room.id, v_uid, v_name);
  return v_room;
end $$;

-- Joins (or re-joins) an open room by its code.
create or replace function public.join_room(p_code text, p_name text)
returns public.rooms language plpgsql security definer set search_path = '' as $$
declare
  v_uid   uuid := auth.uid();
  v_name  text := left(btrim(coalesce(p_name, '')), 16);
  v_room  public.rooms;
  v_count integer;
begin
  if v_uid is null then raise exception 'NOT_SIGNED_IN'; end if;
  if v_name = '' then raise exception 'NAME_REQUIRED'; end if;

  select * into v_room from public.rooms
   where code = btrim(p_code) and status <> 'closed'
   for update;
  if not found then raise exception 'ROOM_NOT_FOUND'; end if;

  -- Already in the room: just refresh the name.
  if exists (select 1 from public.room_members
              where room_id = v_room.id and user_id = v_uid and left_at is null) then
    update public.room_members set name = v_name
     where room_id = v_room.id and user_id = v_uid;
    return v_room;
  end if;

  if exists (select 1 from public.room_members
              where room_id = v_room.id and left_at is null
                and lower(name) = lower(v_name)) then
    raise exception 'NAME_TAKEN';
  end if;

  select count(*) into v_count from public.room_members
   where room_id = v_room.id and left_at is null;
  if v_count >= 7 then raise exception 'ROOM_FULL'; end if;

  insert into public.room_members (room_id, user_id, name)
  values (v_room.id, v_uid, v_name)
  on conflict (room_id, user_id)
  do update set name = excluded.name, left_at = null, joined_at = now();

  update public.rooms set updated_at = now() where id = v_room.id;
  return v_room;
end $$;

-- Leaves a room; when the host leaves, the room is closed for everyone.
create or replace function public.leave_room(p_room uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  update public.room_members set left_at = now()
   where room_id = p_room and user_id = auth.uid() and left_at is null;
  update public.rooms set status = 'closed'
   where id = p_room and host_id = auth.uid();
end $$;

-- ---------------------------------------------------------------- security

alter table public.rooms        enable row level security;
alter table public.room_members enable row level security;
alter table public.room_moves   enable row level security;

drop policy if exists "members read room" on public.rooms;
create policy "members read room" on public.rooms
  for select to authenticated using (public.is_room_member(id));

drop policy if exists "host updates room" on public.rooms;
create policy "host updates room" on public.rooms
  for update to authenticated
  using (host_id = auth.uid()) with check (host_id = auth.uid());

drop policy if exists "members read members" on public.room_members;
create policy "members read members" on public.room_members
  for select to authenticated using (public.is_room_member(room_id));

drop policy if exists "members send moves" on public.room_moves;
create policy "members send moves" on public.room_moves
  for insert to authenticated
  with check (user_id = auth.uid() and public.is_room_member(room_id));

drop policy if exists "host and sender read moves" on public.room_moves;
create policy "host and sender read moves" on public.room_moves
  for select to authenticated
  using (user_id = auth.uid() or public.is_room_host(room_id));

-- Only what the app needs: rooms are created/joined/left through the functions above.
revoke all on public.rooms, public.room_members, public.room_moves from anon, authenticated;
grant select on public.rooms to authenticated;
grant update (status, round, seats, state, notice) on public.rooms to authenticated;
grant select on public.room_members to authenticated;
grant select, insert (room_id, round, turn, card_id) on public.room_moves to authenticated;

revoke execute on function public.create_room(text), public.join_room(text, text),
  public.leave_room(uuid), public.is_room_member(uuid), public.is_room_host(uuid)
  from public, anon;
grant execute on function public.create_room(text), public.join_room(text, text),
  public.leave_room(uuid), public.is_room_member(uuid), public.is_room_host(uuid)
  to authenticated;

-- ---------------------------------------------------------------- realtime

-- Push row changes of these tables to subscribed phones.
do $$
declare t text;
begin
  foreach t in array array['rooms', 'room_members', 'room_moves'] loop
    if not exists (
      select 1 from pg_publication_tables
       where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
