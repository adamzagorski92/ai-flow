# AI Flow Workbench

To repo jest przygotowane tak, żeby zespół mógł pracować w tym samym środowisku niezależnie od systemu operacyjnego.
Główny workflow to: lokalne repo po SSH, jeden kontener `workbench`, a w nim `opencode`, `gh`, `git`, `bd` i `whisper.cpp`.

Stan narzędzi kontenerowych jest trzymany lokalnie w ukrytym katalogu `.workbench/` w repo. Dzięki temu każdy klon ma własne cache, logowanie `gh`, ustawienia OpenCode i modele Whisper bez problemów z uprawnieniami Dockera.

Właściwy kod aplikacji nie trafia do `.workbench`. Jeśli kod ma lądować w Git, lepszym miejscem jest `apps/<APP_CODE_NAME>`: to katalog wersjonowany, oddzielony od cache, tokenów i stanu CLI.

## Co jest gotowe

- `docker compose up -d` buduje i uruchamia kontener roboczy
- `opencode` działa w kontenerze i czyta zasady projektu z `AGENTS.md`
- `gh` jest dostępne do pracy z PR-ami i repo GitHub
- `bd` jest dostępne do planowania iteracji agentowych
- `whisper.cpp` i model są przygotowane do transkrypcji audio w kontenerze
- katalog `apps/<APP_CODE_NAME>` jest tworzony automatycznie jako miejsce na kod aplikacji

## Wymagania

- macOS: Docker Desktop
- Ubuntu/Linux: Docker Engine + Docker Compose
- Windows: WSL2 + Docker Desktop z włączoną integracją z dystrybucją WSL
- własny klucz SSH dodany do GitHub
- klon repo po SSH

## Szybki start

1. Skopiuj `.env.example` do `.env`.
2. Uzupełnij minimum:
   - `OPENCODE_PROVIDER`
   - `APP_CODE_NAME`
   - `GIT_AUTHOR_NAME`
   - `GIT_AUTHOR_EMAIL`
3. Jeśli wybierasz `OPENCODE_PROVIDER=openrouter`, ustaw też `OPENROUTER_API_KEY`.
4. Jeśli wybierasz `OPENCODE_PROVIDER=opencode`, po uruchomieniu `opencode` zrób jednorazowe `/connect` i wybierz `OpenCode Zen`.
5. Opcjonalnie ustaw `GH_TOKEN`, jeśli chcesz od razu używać `gh` bez osobnego logowania.
6. Na Linuxie lub WSL ustaw `LOCAL_UID` i `LOCAL_GID` na wynik `id -u` i `id -g`, jeśli nie są równe `1000`.
7. Uruchom środowisko:

```bash
docker compose up -d --build
```

8. Wejdź do kontenera:

```bash
bash scripts/enter-workbench.sh
```

9. Przejdź do katalogu aplikacji:

```bash
cd "$APP_CODE_DIR"
```

10. Jeśli nie używasz `GH_TOKEN`, zaloguj `gh` raz w środku kontenera:

```bash
gh auth login
```

11. Uruchom OpenCode:

```bash
opencode
```

Możesz też wejść od razu do katalogu aplikacji:

```bash
bash scripts/enter-app-workspace.sh
```

## Provider switch

Samo OpenCode nie jest ograniczone do OpenRoutera. W tym repo provider jest przełączany przez `OPENCODE_PROVIDER` w `.env`.

Dostępne warianty:

- `OPENCODE_PROVIDER=opencode` używa OpenCode Zen i domyślnych presetów `OPENCODE_ZEN_MODEL_ID` oraz `OPENCODE_ZEN_SMALL_MODEL_ID`
- `OPENCODE_PROVIDER=openrouter` używa OpenRoutera i presetów `OPENROUTER_MODEL_ID` oraz `OPENROUTER_SMALL_MODEL_ID`

`opencode.json` dalej ładuje instrukcje z:

- `AGENTS.md`
- `Flow-solution.md`
- `Agent-flow.md`
- `READY.md`
- `TODO.md`

Po każdej zmianie `OPENCODE_PROVIDER` albo klucza providera w `.env` odtwórz kontener przez `docker compose up -d --force-recreate`.

Dla OpenCode Zen rekomendowany workflow jest taki:

- ustaw `OPENCODE_PROVIDER=opencode`
- uruchom `opencode`
- wykonaj `/connect`
- wybierz `OpenCode Zen`

Dla OpenRoutera workflow jest taki:

- ustaw `OPENCODE_PROVIDER=openrouter`
- wpisz `OPENROUTER_API_KEY` w `.env`
- odtwórz kontener

## GitHub CLI

- `git` używa Twoich kluczy z hosta przez mount `~/.ssh`
- `gh` może działać przez `GH_TOKEN` z `.env` albo po jednorazowym `gh auth login`
- PR-y i branch protection są dalej egzekwowane przez GitHub rulesets

## Gdzie powstaje kod aplikacji

- `APP_CODE_NAME` w `.env` wskazuje nazwę katalogu roboczego aplikacji
- host przechowuje kod w `./apps/$APP_CODE_NAME`
- kontener widzi ten sam katalog jako `/workspace/apps/$APP_CODE_NAME`
- katalog `.workbench/` zostaje tylko na stan OpenCode, `gh`, modele Whisper i cache runtime

## Whisper.cpp

Przy pierwszym starcie kontenera model `whisper.cpp` jest pobierany do `.workbench/whisper-models`.
Do transkrypcji plików audio użyj:

```bash
whisper-transcribe /sciezka/do/pliku.wav
```

## Ważne ograniczenie voice

`whisper.cpp` jest w kontenerze, ale dokładne `push-to-talk` pod sam klawisz `Alt` nie zostało spięte jako uniwersalny mechanizm dla macOS, Ubuntu i Windows/WSL.
To nie jest ograniczenie repo, tylko miksu: terminal, host OS, mikrofon i Docker.

W tej wersji wdrożenia:

- transkrypcja przez `whisper.cpp` jest gotowa
- główny workflow agentowy jest gotowy
- pełny globalny hotkey `Alt -> mów -> wstaw do opencode` wymaga osobnej hostowej nakładki dla każdego OS

Jeśli będziesz chciał, kolejny etap może dodać osobne host-helpery dla:

- macOS
- Ubuntu/Linux
- Windows/WSL
