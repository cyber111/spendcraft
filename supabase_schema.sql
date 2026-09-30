-- SpendCraft — Supabase schema
-- Run this in the Supabase SQL editor (Dashboard → SQL Editor → New query).
--
-- Every table is scoped to a user via `user_id`, and Row Level Security (RLS)
-- policies below guarantee that a signed-in user can only read and write
-- rows where `auth.uid() = user_id`. The anon key shipped in the app is safe
-- to expose precisely because RLS enforces isolation server-side.

-- ---------------------------------------------------------------------------
-- transactions
-- ---------------------------------------------------------------------------
create table if not exists transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  amount numeric not null,
  type text not null check (type in ('income','expense')),
  category_id text not null,
  note text,
  date timestamptz not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists transactions_user_date_idx
  on transactions (user_id, date desc);

-- ---------------------------------------------------------------------------
-- categories (custom categories per user; the defaults live in the client)
-- ---------------------------------------------------------------------------
create table if not exists categories (
  id text not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  icon text not null,
  color int not null,
  type text not null check (type in ('income','expense')),
  primary key (id, user_id)
);

-- ---------------------------------------------------------------------------
-- budgets
-- ---------------------------------------------------------------------------
create table if not exists budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  month text not null,           -- 'YYYY-MM'
  category_id text,              -- null = overall monthly budget
  limit_amount numeric not null,
  unique (user_id, month, category_id)
);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- Without these policies, enabling RLS blocks ALL access. Each policy says:
--   USING      → which existing rows the user may see/update/delete
--   WITH CHECK → which new/updated rows the user may write
-- Both are tied to auth.uid(), the id of the currently signed-in user.
-- ---------------------------------------------------------------------------
alter table transactions enable row level security;
alter table categories   enable row level security;
alter table budgets      enable row level security;

drop policy if exists "own_txns"    on transactions;
drop policy if exists "own_cats"    on categories;
drop policy if exists "own_budgets" on budgets;

create policy "own_txns" on transactions
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "own_cats" on categories
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "own_budgets" on budgets
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- NOTE: no "set updated_at = now()" trigger. Sync is last-write-wins on the
-- client's `updated_at`; a server trigger would overwrite it with server time
-- and let an older offline edit beat a newer one.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Account deletion (Google Play requires in-app account deletion).
-- `security definer` runs with the function owner's rights so it may delete
-- from auth.users, but it only ever deletes the caller's own row
-- (auth.uid()). `on delete cascade` above then removes that user's
-- transactions, categories and budgets.
-- ---------------------------------------------------------------------------
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Not signed in';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;
