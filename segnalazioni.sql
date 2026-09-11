-- Segnalazioni (bug e idee) che gli utenti mandano dalla nuvoletta 💬 dell'app.
-- Da incollare una volta in Supabase → SQL Editor → Run. Si può rilanciare senza perdere dati.
-- L'amministratore si aggiunge a parte (vedi in fondo): la sua mail non sta in questo file.

-- Chi può leggere e gestire tutte le segnalazioni
create table if not exists public.amministratori (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.amministratori enable row level security;

drop policy if exists "vedo se sono amministratore" on public.amministratori;
create policy "vedo se sono amministratore" on public.amministratori
  for select to authenticated using (auth.uid() = user_id);

-- Le segnalazioni: una riga per messaggio
create table if not exists public.segnalazioni (
  id      bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  email   text default (auth.jwt() ->> 'email'),
  tipo    text not null default 'bug' check (tipo in ('bug', 'idea')),
  testo   text not null check (char_length(testo) between 1 and 2000),
  pagina  text,
  stato   text not null default 'nuova' check (stato in ('nuova', 'fatta')),
  creato  timestamptz not null default now()
);
alter table public.segnalazioni enable row level security;

-- Ognuno scrive a nome suo (la mail è quella del suo login) e rilegge solo le sue
drop policy if exists "scrivo le mie segnalazioni" on public.segnalazioni;
create policy "scrivo le mie segnalazioni" on public.segnalazioni
  for insert to authenticated
  with check (auth.uid() = user_id and stato = 'nuova' and email is not distinct from (auth.jwt() ->> 'email'));

drop policy if exists "leggo le mie segnalazioni" on public.segnalazioni;
create policy "leggo le mie segnalazioni" on public.segnalazioni
  for select to authenticated using (auth.uid() = user_id);

-- L'amministratore legge, segna come fatte e cancella tutte le segnalazioni
drop policy if exists "l'amministratore legge tutto" on public.segnalazioni;
create policy "l'amministratore legge tutto" on public.segnalazioni
  for select to authenticated
  using (exists (select 1 from public.amministratori a where a.user_id = auth.uid()));

drop policy if exists "l'amministratore aggiorna" on public.segnalazioni;
create policy "l'amministratore aggiorna" on public.segnalazioni
  for update to authenticated
  using (exists (select 1 from public.amministratori a where a.user_id = auth.uid()))
  with check (exists (select 1 from public.amministratori a where a.user_id = auth.uid()));

drop policy if exists "l'amministratore cancella" on public.segnalazioni;
create policy "l'amministratore cancella" on public.segnalazioni
  for delete to authenticated
  using (exists (select 1 from public.amministratori a where a.user_id = auth.uid()));

-- Per aggiungere un amministratore (da lanciare a parte, con la mail giusta):
--   insert into public.amministratori (user_id)
--   select id from auth.users where email = 'MAIL-DELL-AMMINISTRATORE'
--   on conflict do nothing;
