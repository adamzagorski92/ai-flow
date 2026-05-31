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

Dla branchy `master` i `develop` ustaw protection rules:

1. zablokuj direct push
2. zablokuj force push
3. wymagaj Pull Request przed mergem
4. wymagaj aktualnej gałęzi przed mergem
5. wymagaj zielonych testów / checków
6. włącz linear history
7. wyłącz usuwanie branchy chronionych

W `Settings -> General -> Pull Requests` ustaw:

1. włącz `Rebase and merge`
2. wyłącz `Merge commit`
3. wyłącz `Squash merge`, jeśli chcesz trzymać się zasady: tylko rebase
4. opcjonalnie włącz `Auto-merge`

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
