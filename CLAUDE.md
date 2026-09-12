# Piano Alimentare, istruzioni per chi ci lavora

App per seguire un piano alimentare di 4 settimane, con lista della spesa intelligente.
Un file HTML solo, senza build e senza server, pubblicato su GitHub Pages.
La usano Mattia e Lorenzo, installata come app (PWA) sul telefono Android.

## Comandi

```bash
python3 -m http.server 8000      # prova in locale: http://localhost:8000/index.html
```

Niente da compilare. Il file che si modifica è lo stesso che va online.

Si pubblica con un push su `main`: GitHub Pages pubblica la radice del repository
(https://mattialangella95-bit.github.io/piano-alimentare/). Un push è quindi un rilascio vero.

1. **Prima di ogni push si chiede sempre il permesso.** Si fa il commit in locale e ci si ferma.
2. **Dopo il push si fa un riepilogo** con l'utente: cosa è andato online e cosa provare sul telefono.
3. **A ogni rilascio si cambia `CACHE_VERSION`** in `service-worker.js` (`piano-v17` → `piano-v18`),
   altrimenti i telefoni continuano a usare la versione in cache.

## Struttura

1. `index.html` tutta l'app, un file solo: CSS in cima, HTML, poi un unico `<script>`
2. `supabase.js` il client di Supabase già impacchettato, non si tocca
3. `service-worker.js` cache per l'uso offline, rete prima per l'HTML
4. `manifest.json` e le icone, servono perché su Android si installi come un'app
5. `supabase.sql` la tabella `piani`, da lanciare una volta nel SQL Editor di Supabase
6. `segnalazioni.sql` le tabelle `segnalazioni` e `amministratori`, come sopra

File che stanno solo sul computer, nel `.gitignore`: `piano_backup_*.json`, `importa_*.sql`
(contengono dati personali) e `*.code-workspace`.

Le sezioni dello script sono segnate da commenti `// ---------- NOME ----------`:
persistenza, account, appunti, piano, prodotti, lista spesa, in casa, profilo,
segnalazioni, tasto indietro.

## Come sono organizzati i dati

Su Supabase, con RLS: ognuno vede solo le sue righe.

1. `piani` una riga per utente, tutto il piano nella colonna `dati` (jsonb)
2. `segnalazioni` bug e idee scritti dalla nuvoletta 💬, con la pagina e il telefono di chi scrive
3. `amministratori` chi legge tutte le segnalazioni nel Profilo. La mail non sta nel codice

Dentro `dati` c'è quello che restituisce `currentState()`.

1. `planData` 4 settimane × 7 giorni × 6 pasti, ogni ingrediente `{ name, qty, buy }`
2. `shopCheckedState` le spunte della spesa, una per ogni "volta": `settimana|giorno|pasto|prodotto`
3. `products` le correzioni per prodotto: reparto, conservazione, confezione
4. `homeStock` quello che c'è in casa, per prodotto
5. `profile` nome, colori, lunedì di inizio, note
6. `weekCompleted`, `extraItems`, `appTitle`, `cycle`, `dataVersion`

In locale `piano_utente_<id>` è la copia sul telefono. Ogni modifica va subito lì, e 800 ms
dopo su Supabase. Si legge prima il locale, poi la nuvola, e vince il più recente.
Senza rete l'app funziona lo stesso e rispedisce al ritorno della linea.

## Cose da non rompere

1. **Ogni campo nuovo dei dati va in tre posti.** In `currentState()`, e in `applyState()`
   sia dove si azzera sia dove si carica. Altrimenti non si salva o si perde al riavvio.
2. **Il piano è un ciclo di 28 giorni** che parte dal lunedì scelto nel Profilo. A ogni nuovo giro
   `resetProgress` azzera settimane completate e spunte, spostando quelle già fatte in avanti.
3. **"Oggi" si ricalcola** quando si torna sull'app (`refreshToday`): sul telefono resta aperta per giorni.
4. **Le spunte sono per singola volta**, non per prodotto, e valgono in tutte le liste
   (fresca, settimana, dispensa). La settimana nella chiave può superare la 4, perché la dispensa guarda avanti.
5. **Un prodotto si riconosce dal nome in minuscolo** (`cleanName(...).toLowerCase()`).
   `products` e `homeStock` usano quella chiave. In "In casa" il prodotto si sceglie da un menu
   con i soli prodotti del piano, così il nome combacia sempre.
6. **Le quantità passano da `cleanQty` e `parseQty`.** I totali sono in unità base (g, ml, pz…),
   per gli intervalli conta il massimo, "q.b." non si somma.
7. **In casa si consuma da solo** coi giorni passati (`consumeHomeStock`), e copre le prossime volte
   non comprate da oggi in avanti (`computeHomeCover`). Una spunta ricorda com'era, e toglierla lo ripristina.
   Sotto la voce appena spuntata c'è la tendina "Preso solo in parte?" (`applyPartial`): si torna a prima
   della spunta e si coprono le volte in ordine di data con quanto preso davvero, il resto va in casa.
   Quello che si è segnato resta visibile e annullabile finché la voce non è presa tutta: sta in `tickMemo`,
   che si salva coi dati e si azzera a ogni nuovo giro.
8. **Il tasto indietro di Android** chiude schede e pannelli invece di uscire: c'è sempre una
   "pagina di guardia" in cronologia.
9. **Le chiavi Supabase nel codice sono quelle pubbliche (anon)**: la sicurezza sta nelle regole RLS
   dei file `.sql`. Mai mettere nel codice password o chiavi di servizio.

## Segnalazioni

Bug e idee arrivano dalla nuvoletta 💬 nella tabella `segnalazioni`. Quando l'utente parla di
"lista di bug e migliorie" intende quelle aperte. Quelle chiare si risolvono, per quelle aperte
a più strade prima si propone un brainstorming. Dopo il rilascio si segnano come "Fatta",
dal Profilo dell'amministratore.

## Convenzioni di scrittura

1. JavaScript senza framework e senza librerie nuove, nello stile che c'è già
2. Codice commentato in italiano, interfaccia in italiano, parole semplici per chi non è tecnico
3. Misure del testo solo con le variabili `--fs-*`, colori solo con quelle del tema (`--forest`, `--clay`…)
4. Deve funzionare su telefono in verticale e in orizzontale, anche offline

## Quando si modifica

1. Controllare la sintassi dello script (`node --check` sul contenuto del `<script>`)
2. Provare nel browser come telefono, 390×844 e girato: accesso, piano, lista spesa, ⓘ, In casa
3. Cambiare `CACHE_VERSION` prima di pubblicare, commit in locale, poi chiedere se pushare
