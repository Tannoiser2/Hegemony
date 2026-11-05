# Hegemony - versione digitale

Versione digitale non ufficiale, per uso personale, di **Hegemony: guida la tua classe alla vittoria**
(Varnavas Timotheou e Vangelis Bagiartakis, Hegemonic Project). Quattro classi asimmetriche (Classe Operaia,
Classe Media, Classe Capitalista e Stato) con avversari IA per le classi non guidate da giocatori umani,
sullo stesso dispositivo o online con gli amici.

Si gioca qui: https://tannoiser2.github.io/Hegemony/

## Cosa c'è

- **Regole complete del gioco base a 4 giocatori**: 5 round con Preparazione, Azioni (5 turni, carta per
  l'effetto oppure scartata per un'Azione base, più un'Azione gratuita), Produzione (salari, produzione,
  bisogni di Cibo, controllo del FMI, tasse), Elezioni e Punteggio; le 7 Politiche con tutti i loro effetti
  (settore pubblico, salario minimo, moltiplicatore delle tasse, welfare, dazi e accordi commerciali,
  immigrazione); leggi con Votazione Immediata, sacchetto dei cubi Voto e Influenza segreta; lavoratori
  qualificati, impegnati, sindacati, scioperi e manifestazioni; prestiti e intervento del FMI.
- **Tutte le carte in italiano**: 160 carte Azione (107 diverse), 25 Eventi, 58 Aziende, 16 Export,
  20 Accordi Commerciali, 10 Agende Politiche e 25 Immigrazione, tradotte dal modulo di Tabletop Simulator
  usando i termini del regolamento italiano. I testi sono in `tools/sorgenti/` e diventano `dati/carte.json`
  con `tools/costruisci_dati.py`.
- **IA** che valuta ogni scelta simulandone l'effetto sulla posizione della propria classe; vota e spende
  Influenza secondo l'ideologia della classe (lo Stato segue anche la sua Agenda Politica).
- **Online** con stanze di 4 lettere su Firebase (chi crea la stanza è la Classe Operaia, poi Classe Media,
  Capitalista e Stato; i posti vuoti li guida l'IA) e **salvataggio** automatico sul dispositivo e su
  Firebase (`hegemony/salvataggi`).

## Struttura

- `scripts/motore.gd` – le regole: stato in un dizionario, decisioni numerate (stessa sequenza = stessa
  partita su tutti i dispositivi).
- `scripts/dati.gd` – tabelle delle regole e accesso a `dati/carte.json`.
- `scripts/ia.gd` – intelligenza artificiale; `scripts/main.gd` – menu e interfaccia; `scripts/rete.gd` – Firebase.
- `tools/controlla_glifi.py` – controlla che ogni carattere dei testi esista nei font.
- `firebase/database.rules.json` – regole del database (radice `hegemony`, da unire a quelle del progetto condiviso).

## Prove

```
godot --headless --path . -s res://tests/sim.gd -- 10            # 10 partite tutte IA
godot --headless --path . -s res://tests/sim.gd -- 300 casuale   # 300 partite a scelte casuali (robustezza)
godot --headless --path . -s res://tests/ui_auto.gd              # partita intera dall'interfaccia
xvfb-run godot --path . -s res://tests/foto.gd -- partita 60     # screenshot
```

## Pubblicazione

Il workflow `Pubblica` parte a mano (Actions → Pubblica → Run workflow) oppure con un commit che contiene
`[pubblica]`. Con i segreti `CLOUDFLARE_API_TOKEN` e `CLOUDFLARE_ACCOUNT_ID` pubblica anche sulla ludoteca
privata di Cloudflare.

Font: Montserrat (licenza SIL Open Font, in `assets/font/`).
