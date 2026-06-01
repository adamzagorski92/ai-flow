# READY Registry

`READY.md` jest kanonicznym rejestrem capability już zmergowanych do `develop`.
To nie jest backlog, lista pomysłów ani lista branchy.
Aktywne, wieloiteracyjne albo jeszcze niedomknięte prace trzymamy w `TODO.md`.

## Po co ten plik

1. przed rozpoczęciem taska agent sprawdza, czy capability już istnieje
2. jeśli istnieje, rozwija albo naprawia istniejący moduł zamiast tworzyć duplikat
3. jeśli nie istnieje, dopiero wtedy powstaje nowa capability
4. dzięki temu zespół unika zespołowego DRY, czyli budowania drugi raz tego samego pod inną nazwą

## Zasady aktualizacji

1. ten plik aktualizuje tylko `Develop Integration Agent`
2. aktualizacja dzieje się podczas finalizacji PR do `develop`
3. jedna capability ma jeden kanoniczny wiersz w tabeli
4. nowa capability = dopisz nowy wiersz na końcu tabeli
5. rozwój albo bugfix istniejącej capability = zaktualizuj istniejący wiersz
6. `Created on` i `Created by` nie zmieniają się po pierwszym wpisie
7. przy kolejnych zmianach aktualizuj `Last updated on`, `Last updated by` i `Notes`
8. w polach `Created by` i `Last updated by` wpisuj nazwę właściciela taska lub autora capability, nie nazwę konta reviewera

## Polityka testów

1. rozwój capability: stare zielone testy zostają bez zmian; dodajemy tylko nowe testy dla nowego zachowania
2. bugfix: dodajemy test regresyjny
3. istniejący test można zmienić tylko wtedy, gdy wcześniej opisywał błędny kontrakt
4. jeśli bugfix koryguje kontrakt, trzeba to opisać w kolumnie `Notes`

## Tabela capability

| Capability | Canonical module / path | State | Created on | Created by | Last updated on | Last updated by | Extension point | Notes |
| ---------- | ----------------------- | ----- | ---------- | ---------- | --------------- | --------------- | --------------- | ----- |
