-- SpendCraft migration — 2026-09-30
-- Run once in Supabase → SQL Editor → New query → Run. Safe to re-run.

-- 1) Remove the server-side updated_at trigger if an older schema added it.
--    Sync relies on the client's timestamp (last-write-wins).
drop trigger if exists transactions_set_updated_at on public.transactions;
drop function if exists public.set_updated_at();

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

-- Check: should list delete_own_account with security_type = DEFINER.
select routine_name, security_type
from information_schema.routines
where routine_schema = 'public' and routine_name = 'delete_own_account';
