# Prosty flow pracy dla `ai-flow`

## Cel

Najprostszy i bezpieczny układ:

- `master` = wersja stabilna
- `develop` = gałąź integracyjna
- `feature/<imię>/<krótki-task>` = jedna mała zmiana, jeden PR

Pracujemy w trybie full Agent AI: człowiek zleca zadanie agentowi, a agent robi zmiany tylko na branchu `feature/...`.

## 1. Jednorazowe przygotowanie repo przez ownera

1. W GitHub dodaj collaboratorów do repo `adamzagorski92/ai-flow`.
   Na start: `marta`, `julita`, `patryk`.
2. Upewnij się, że istnieją dwie główne gałęzie:
   - `master`
   - `develop`
3. Jeśli `develop` jeszcze nie istnieje, utwórz ją raz:

```bash
git clone git@github.com:adamzagorski92/ai-flow.git
cd ai-flow
git switch master
git pull --rebase origin master
git switch -c develop
git push -u origin develop
```

## 2. Ustawienia GitHub, które trzeba włączyć

### Krok po kroku w GitHub `Rulesets`

Teraz, gdy repo jest publiczne, najprościej ustaw to przez `Rulesets`.
Zrób 2 osobne rulesety:

1. `Protect master`
2. `Protect develop`

### Ruleset dla `master`

1. Wejdź do repo `adamzagorski92/ai-flow`.
2. Kliknij `Settings`.
3. W lewym menu kliknij `Rules`.
4. Kliknij `New branch ruleset`.
5. W polu `Ruleset Name` wpisz `Protect master`.
6. W `Enforcement status` ustaw `Active`.
7. `Bypass list` zostaw pusty.
8. W `Target branches` ustaw branch tak, żeby ruleset pasował tylko do `master`.
9. W `Rules` włącz:
   - `Require a pull request before merging`
   - `Require status checks to pass` tylko jeśli masz już działający check z GitHub Actions
   - `Require linear history`
   - `Block force pushes`
   - `Restrict deletions`
10. Nie włączaj na start:

- `Restrict creations`
- `Restrict updates`
- `Require deployments to succeed`
- `Require signed commits`
- `Require code scanning results`
- `Require code quality results`

11. Kliknij `Create ruleset`.

### Ruleset dla `develop`

1. Kliknij jeszcze raz `New branch ruleset`.
2. W polu `Ruleset Name` wpisz `Protect develop`.
3. W `Enforcement status` ustaw `Active`.
4. `Bypass list` zostaw pusty.
5. W `Target branches` ustaw branch tak, żeby ruleset pasował tylko do `develop`.
6. Włącz dokładnie te same opcje co dla `master`:
   - `Require a pull request before merging`
   - `Require status checks to pass` tylko jeśli masz już działający check z GitHub Actions
   - `Require linear history`
   - `Block force pushes`
   - `Restrict deletions`
7. Kliknij `Create ruleset`.

### Co zaznaczyć w rozwiniętych checkboxach

Poniższe ustaw dokładnie tak samo w `Protect master` i w `Protect develop`.

#### W `Require a pull request before merging`

1. `Required approvals`: ustaw `1`
2. `Dismiss stale pull request approvals when new commits are pushed`: włącz
3. `Require review from specific teams`: wyłącz
4. `Require review from Code Owners`: wyłącz
5. `Require approval of the most recent reviewable push`: wyłącz
6. `Require conversation resolution before merging`: włącz
7. `Allowed merge methods`: zostaw tylko `Rebase`

#### W `Require status checks to pass`

Jeśli teraz widzisz `No checks have been added`, to znaczy, że repo nie ma jeszcze gotowego checka do wymagania.

Wtedy zrób tak:

1. na razie zostaw `Require status checks to pass` wyłączone
2. dodaj workflow testów, np. GitHub Actions
3. uruchom go przynajmniej raz
4. wróć do rulesetu i wtedy włącz `Require status checks to pass`
5. wybierz konkretny check z listy
6. włącz `Require branches to be up to date before merging`
7. zostaw wyłączone `Do not require status checks on creation`

To jest ważne, bo wasz flow ma wymuszać rebase na aktualny branch bazowy przed mergem.

#### Pozostałe rozwijane opcje

1. `Automatically request Copilot code review`: opcjonalne, na start zostaw wyłączone

To odpowiada tym zasadom:

- brak direct push na `master` i `develop`
- brak force push na `master` i `develop`
- merge tylko przez Pull Request
- branch ma przejść testy / checki
- historia ma zostać liniowa
- nie można usuwać chronionych branchy

Jeśli GitHub pokaże dodatkową opcję o aktualności brancha w `Require status checks to pass`, też ją włącz.

### Jeśli zamiast `Rulesets` widzisz `Branches`

Na części kont GitHub dalej pokazuje klasyczne `Branch protection rules`.
Wtedy ustaw tam dokładnie to samo dla `master` i osobno dla `develop`.

### Ustawienia merge w `Settings -> General`

Przewiń do sekcji `Pull Requests` i ustaw:

1. wyłącz `Allow merge commits`
2. wyłącz `Allow squash merging`, jeśli chcesz trzymać się zasady: tylko rebase
3. włącz `Allow rebase merging`
4. opcjonalnie włącz `Allow auto-merge`
5. najlepiej zostaw wyłączone `Always suggest updating pull request branches`

Ostatni punkt jest ważny, bo przycisk `Update branch` często prowadzi do merge z `develop` do brancha feature, a u nas ma być zawsze rebase.

### Ważna uwaga o testach / checkach

Opcja `Require status checks to pass before merging` ma sens dopiero wtedy, gdy repo ma już jakiś check, np. GitHub Actions.

Jeśli GitHub nie pokazuje jeszcze żadnego checka do wyboru, to:

1. najpierw dodaj workflow testów
2. uruchom go chociaż raz
3. wróć do protection rule i zaznacz wymagany check

To daje jedną prostą zasadę: do `develop` i `master` wchodzi kod tylko przez PR i tylko przez rebase.

## 3. Dostęp SSH tylko do tego repo

Najprostsza i poprawna wersja:

1. każdy pracuje na swoim koncie GitHub
2. każdy ma swój własny klucz SSH
3. owner daje dostęp tylko do repo `adamzagorski92/ai-flow`

Nie używajcie jednego wspólnego klucza SSH dla całego zespołu.

### Kroki dla każdej osoby

1. Wygeneruj klucz SSH:

```bash
ssh-keygen -t ed25519 -C "twoj-email@example.com"
```

2. Dodaj klucz do agenta SSH:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

3. Skopiuj klucz publiczny:

```bash
cat ~/.ssh/id_ed25519.pub
```

4. W GitHub wejdź w `Settings -> SSH and GPG keys -> New SSH key` i wklej klucz.
5. Sprawdź połączenie:

```bash
ssh -T git@github.com
```

6. Sklonuj repo po SSH:

```bash
git clone git@github.com:adamzagorski92/ai-flow.git
```

To wystarcza, żeby każda osoba miała dostęp SSH tylko tam, gdzie owner nada jej uprawnienia w GitHub.

## 4. Lokalna konfiguracja Git, żeby zawsze robić rebase

Na każdym komputerze ustaw raz:

```bash
git config --global pull.rebase true
git config --global rebase.autoStash true
git config --global fetch.prune true
```

Dzięki temu zwykły `git pull` nie zrobi merge commitów.

## 5. Codzienny flow pracy jednej osoby / jednego agenta

1. Zawsze zacznij od aktualizacji `develop`:

```bash
git switch develop
git pull --rebase origin develop
```

2. Utwórz nowy branch do jednej konkretnej zmiany:

```bash
git switch -c feature/marta/hero-section
```

3. Agent robi tylko jedną małą rzecz na tym branchu.
4. Commit tylko wtedy, gdy zmiana działa:

```bash
git add .
git commit -m "feat: dodano hero section"
```

5. Przed każdym push i przed każdym PR zawsze zrób rebase na najnowszy `develop`:

```bash
git fetch origin
git rebase origin/develop
npm test
```

6. Wypchnij branch:

```bash
git push -u origin feature/marta/hero-section
```

7. Jeśli branch był już wcześniej wypchnięty i po drodze był rebase, użyj tylko:

```bash
git push --force-with-lease
```

`--force-with-lease` jest dozwolony tylko na własnym branchu `feature/...`.
Nigdy na `develop` i nigdy na `master`.

8. Otwórz PR do `develop`.

## 6. Co robi agent, gdy PR wpada do `develop`

Docelowy prosty flow:

1. agent sprawdza, czy branch feature jest oparty na najnowszym `develop`
2. jeśli nie, agent robi:

```bash
git fetch origin
git rebase origin/develop
```

3. jeśli są konflikty, agent rozwiązuje je na branchu `feature/...`, a nie na `develop`
4. agent uruchamia testy jeszcze raz
5. jeśli wszystko jest zielone, PR jest akceptowany i mergowany do `develop`
6. merge do `develop` robimy wyłącznie jako `Rebase and merge`

Najważniejsza zasada: nigdy nie mergujemy `develop` do brancha feature. Zawsze rebase feature na `develop`.

## 7. Co dzieje się po aktualizacji `develop`

Po każdym poprawnym merge do `develop`:

1. agent albo owner otwiera PR z `develop` do `master`
2. ten PR też przechodzi testy
3. merge do `master` robimy tylko jako `Rebase and merge`

W praktyce:

- `develop` = miejsce integracji pracy zespołu
- `master` = zawsze wersja czysta i gotowa do pokazania

## 8. Zasady, które pozwalają pracować równolegle

Żeby 1 PR na minutę miało sens, zmiany muszą być bardzo małe:

1. jeden branch = jeden task
2. jeden PR = jeden temat
3. nie wrzucamy wielu rzeczy naraz
4. lepiej dodać nowy moduł niż edytować 10 wspólnych plików
5. wspólne typy, helpery i kontrakty trzymajcie w osobnych plikach
6. duże refaktory róbcie osobno, nie razem z nową funkcją
7. jeśli dwa taski dotykają tego samego pliku, najpierw domknijcie jeden PR, potem drugi

Najmniej konfliktów będzie wtedy, gdy architektura od początku będzie podzielona na małe, niezależne moduły.

## 9. Opcja na później, jeśli PR-ów będzie bardzo dużo

Jeśli naprawdę dojdziecie do bardzo dużej liczby PR-ów, warto włączyć `Merge Queue` na `develop`.

To pomaga, bo GitHub wpuszcza PR-y do merge po kolei, na aktualnej bazie, zamiast mieszać wiele równoległych merge naraz.

## 10. Krótka wersja operacyjna dla zespołu

To jest wersja robocza, z której zespół może korzystać na co dzień bez czytania całego dokumentu.

1. człowiek zleca task agentowi
2. agent-autora zaczyna od `Research`: sprawdza `READY.md`, `TODO.md`, kod i obecny kontrakt modułu
3. jeśli capability już istnieje w `READY.md` albo ma otwartą iterację w `TODO.md`, agent rozwija tę samą capability zamiast tworzyć duplikat pod nową nazwą
4. jeśli capability nie istnieje, agent projektuje nową capability i nowy moduł od najnowszego `develop`
5. jeśli feature będzie wymagał więcej niż jednego małego PR-a, agent zakłada albo aktualizuje jeden kanoniczny wiersz w `TODO.md`
6. agent-autora robi `Plan`: wybiera najmniejszy następny krok, zapisuje `Next smallest task` w `TODO.md` i dopisuje ewentualne sugestie powiązanych feature'ów
7. agent-autora robi `Execute`: realizuje tylko ten krok, uruchamia testy, robi rebase i otwiera PR do `develop`
8. dla rozwoju modułu stare zielone testy pozostają bez zmian; agent dodaje tylko nowe testy dla nowego zachowania
9. dla bugfixa agent najpierw dodaje test regresyjny; istniejący test wolno zmienić tylko wtedy, gdy wcześniej opisywał błędny kontrakt
10. drugi agent, na innym koncie GitHub niż autor PR, bierze PR do `develop`
11. agent integracyjny robi `git fetch origin && git rebase origin/develop`
12. jeśli są konflikty, rozwiązuje je na branchu `feature/...`, nie na `develop`
13. agent integracyjny uruchamia testy jeszcze raz i może poprawić kod, ale nie może osłabiać testów tylko po to, żeby pipeline zrobił się zielony
14. tuż przed mergem do `develop` agent integracyjny aktualizuje `READY.md`:

- dodaje nowy wiersz, jeśli capability jest naprawdę nowa
- aktualizuje istniejący wiersz, jeśli to rozwój lub bugfix istniejącej capability

15. w tym samym momencie agent integracyjny porządkuje `TODO.md`:

- zostawia wiersz otwarty z kolejnym krokiem, jeśli capability nadal wymaga iteracji
- zamyka albo usuwa aktywny wiersz, jeśli capability nie ma już kolejnego otwartego kroku

16. jeśli wszystko jest zielone, PR dostaje approval i wpada do `develop` tylko przez `Rebase and merge`
17. po każdym poprawnym update `develop` agent release otwiera albo odświeża PR z `develop` do `master`
18. agent release robi tę samą pętlę: weryfikacja, rebase, poprawa kodu, testy, approval, `Rebase and merge`
19. jeśli PR `develop -> master` nie przejdzie testów, agent nie poprawia testów i nie pcha nic bezpośrednio do `master`
20. wtedy agent tworzy nowy branch naprawczy od `develop`, naprawia tylko kod, merguje fix z powrotem do `develop`, a potem odświeża PR do `master`

Najważniejsze twarde zasady:

1. testy są święte
2. jeśli test nie przechodzi, poprawiamy kod, nie test, chyba że bugfix koryguje wcześniej błędny kontrakt
3. kodu nie piszemy i nie poprawiamy ręcznie
4. approval PR musi zrobić inne konto GitHub niż konto autora PR
5. przed każdym nowym taskiem najpierw sprawdzamy `READY.md` i `TODO.md`
6. jedna capability ma mieć jeden kanoniczny wpis w `READY.md` i najwyżej jeden otwarty wiersz w `TODO.md`
7. jeśli pojawia się pasujący, ale odrębny follow-up, zapisujemy go jako sugestię w `TODO.md`

## 11. Jak to powinno działać przy bardzo dużej liczbie feature'ów

Jeśli naprawdę będziecie wpuszczać bardzo dużo zmian równolegle, samo Git flow nie wystarczy. Trzeba od początku pilnować modularności.

### Zasady architektury

1. każdy feature powinien mieć własny moduł albo własny katalog, zamiast dopisywania logiki do wspólnych plików
2. wspólne typy, kontrakty i interfejsy trzymajcie w osobnych plikach albo paczkach
3. jeśli feature wymaga zmiany wspólnego kontraktu, róbcie to w 2 PR-ach:
   - najpierw PR przygotowawczy z kontraktem lub adapterem
   - potem PR z właściwą funkcją
4. unikajcie dużych plików centralnych, które wszyscy edytują naraz
5. preferujcie adaptery, rejestry, pluginy i feature flags zamiast rozlewania zmian po całej aplikacji
6. każdy feature powinien dotykać jak najmniejszej liczby wspólnych miejsc

### Zasady procesu

1. jeden PR ma być mały i zamknięty tematycznie
2. duży refaktor nigdy nie może iść razem z nową funkcją
3. agent integracyjny ma prawo poprawić kod pod kompatybilność, ale nie ma prawa rozszerzać zakresu biznesowego zadania
4. jeśli kilka feature'ów wymaga tego samego shared file, najpierw trzeba wydzielić z niego stabilny punkt rozszerzeń
5. jeśli ruch będzie naprawdę duży, włączcie `Merge Queue` przynajmniej na `develop`
6. `READY.md` nie może być backlogiem ani listą pomysłów; to rejestr capability już zmergowanych do `develop`
7. żeby zmniejszyć konflikty w `READY.md`, ten plik aktualizuje tylko agent integracyjny podczas finalizacji PR do `develop`
8. nowe capability dopisujcie na końcu tabeli, bez sortowania całego pliku przy każdym PR

Cel jest prosty: deweloper ma myśleć głównie o swoim module, a nie o tym, kto równolegle edytuje ten sam plik.

## 12. `READY.md` jako rejestr capability

`READY.md` ma być jednym źródłem prawdy o tym, co już istnieje w `develop`.
W przeciwieństwie do niego `TODO.md` trzyma capability aktywne, iterowane albo jeszcze niedomknięte.

Zasady działania:

1. przed startem każdego taska agent-autora sprawdza `READY.md`
2. jeśli wpis już istnieje, agent rozwija albo naprawia tę samą capability i ten sam moduł
3. jeśli wpisu nie ma, dopiero wtedy tworzy nową capability
4. jeden wpis = jedna capability; nie dokładamy drugiego wpisu tylko dlatego, że zakres funkcji się rozszerzył
5. `Created on` i `Created by` zostają bez zmian przez cały cykl życia capability
6. przy rozwoju lub bugfixie zmieniamy tylko `Last updated on`, `Last updated by`, `Notes` i ewentualnie `Canonical module / path`
7. jeśli bugfix wymaga korekty kontraktu, trzeba to opisać w `Notes`, żeby kolejny agent wiedział, dlaczego test został zmieniony

Najważniejszy cel tego pliku: unikanie zespołowego DRY, czyli unikanie budowania drugi raz tego, co już istnieje pod inną nazwą albo w innym module.

## 13. `TODO.md` jako rejestr aktywnych iteracji

`TODO.md` trzyma capability, które są jeszcze w ruchu.
To nie jest lista gotowych funkcji i nie zastępuje `READY.md`.

Zasady działania:

1. jeden długi feature może mieć wiele branchy i wiele PR-ów, ale tylko jeden aktywny wiersz w `TODO.md`
2. Feature Agent aktualizuje własny wiersz w fazach `Research`, `Plan` i `Execute`
3. jeśli praca trwa dłużej, agent nie zakłada nowej capability, tylko iteruje ten sam wiersz krok po kroku
4. jeśli w trakcie pracy pojawia się osobna capability, dopisujemy ją do tabeli sugestii, zamiast od razu tworzyć drugi równoległy feature
5. gdy capability nie ma już otwartych kolejnych kroków, agent integracyjny domyka jej aktywny wpis w `TODO.md`

Najważniejszy cel tego pliku: niczego nie gubić przy długiej iteracji i jednocześnie nie duplikować pracy zespołu.

## 14. Flow `Research -> Plan -> Execute`

1. `Research`: sprawdzamy `READY.md`, `TODO.md`, kod, testy i kontrakty modułów
2. `Plan`: wybieramy najmniejszy następny krok, określamy typ zmiany i zapisujemy to w `TODO.md`
3. `Execute`: dowozimy tylko ten krok w jednym branchu i jednym PR-ze
4. jeśli feature nadal nie jest gotowy, wracamy do `Research` i iterujemy ten sam wpis w `TODO.md`
5. jeśli capability jest już gotowa i nie ma kolejnych kroków, aktywny wpis w `TODO.md` znika, a trwały stan zostaje w `READY.md`
