-- Piano Alimentare: una riga per ogni utente, con dentro tutto il suo piano.
-- Da incollare una volta sola in Supabase → SQL Editor → Run.
-- Si può rilanciare senza problemi: non cancella dati già salvati.

create table if not exists public.piani (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  dati       jsonb not null,
  aggiornato timestamptz not null default now()
);

-- Ognuno vede e modifica solo il proprio piano
alter table public.piani enable row level security;

drop policy if exists "leggo il mio piano" on public.piani;
create policy "leggo il mio piano" on public.piani
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "creo il mio piano" on public.piani;
create policy "creo il mio piano" on public.piani
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "modifico il mio piano" on public.piani;
create policy "modifico il mio piano" on public.piani
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "cancello il mio piano" on public.piani;
create policy "cancello il mio piano" on public.piani
  for delete to authenticated using (auth.uid() = user_id);
