# Graf flow dla agentów

## Role

- `Feature Agent` tworzy kod na branchu `feature/...` i otwiera PR do `develop`
- `Develop Integration Agent` bierze każdy PR do `develop`, robi rebase, rozwiązuje konflikty, weryfikuje kod i przygotowuje merge
- `Release Agent` pilnuje przepływu `develop -> master`
- `Human` nie pisze kodu ręcznie; definiuje zadania i nadzoruje wynik

## Pętla `Research -> Plan -> Execute`

```mermaid
flowchart LR
    R[Research<br/>READY.md TODO.md kod testy] --> P[Plan<br/>najmniejszy następny krok]
    P --> TD[Zaktualizuj TODO.md<br/>next task i sugestie]
    TD --> E[Execute<br/>jeden branch jeden PR]
    E --> Q{Feature nadal wymaga iteracji?}
    Q -->|Tak| R
    Q -->|Nie| D[Zamknij aktywny wpis w TODO.md<br/>i dopilnuj READY.md]
```

## Główny flow

```mermaid
flowchart TD
    H[Human zleca task] --> RS[Research<br/>Sprawdź READY.md TODO.md i kod]
    RS --> D{Capability już istnieje<br/>albo ma otwartą iterację?}
    D -->|Tak| E[Pracuj na istniejącej capability]
    D -->|Nie| N[Zaprojektuj nową capability i moduł]
    E --> P[Plan<br/>Wybierz najmniejszy następny krok]
    N --> P
    P --> L{Feature wymaga<br/>więcej iteracji?}
    L -->|Tak| TD[Utwórz lub zaktualizuj<br/>kanoniczny wiersz w TODO.md]
    L -->|Nie| C[Napisz lub zmień kod]
    TD --> SG[Zapisz next task<br/>i sugestie follow-up]
    SG --> C
    C --> K{Typ zmiany}
    K -->|Rozwój modułu| TE[Dodaj nowe testy<br/>starych zielonych testów nie zmieniaj]
    K -->|Bugfix| TB[Dodaj test regresyjny<br/>stary test zmień tylko przy korekcie kontraktu]
    TE --> T[Execute<br/>Uruchom testy]
    TB --> T
    T -->|Fail| CF[Popraw kod, nie testy]
    CF --> T
    T -->|Pass| PR[Push branch i otwórz PR do develop]
    PR --> IA[Develop Integration Agent<br/>inna tożsamość GitHub niż autor PR]
    IA --> RB[git fetch origin + git rebase origin/develop]
    RB -->|Konflikty| RC[Rozwiąż konflikty na feature branchu]
    RC --> V
    RB -->|Brak konfliktów| V[Weryfikacja kodu i testów]
    V -->|Fail| VF[Popraw kod, nie testy]
    VF --> RB
    V -->|Pass| U[Zaktualizuj READY.md i TODO.md<br/>dodaj nowy wiersz albo zaktualizuj istniejący]
    U --> A[Approval PR]
    A --> M[Rebase and merge do develop]
    M --> RA[Release Agent]
    M --> NX{Są kolejne iteracje?}
    NX -->|Tak| RS
    NX -->|Nie| CL[Brak otwartego wiersza<br/>w TODO.md]
    RA --> RM[Otwórz lub odśwież PR develop -> master]
    RM --> RV[Uruchom testy i weryfikację]
    RV -->|Fail| RF[Utwórz fix branch od develop]
    RF --> RFC[Popraw kod, nie testy<br/>chyba że korygowany jest błędny kontrakt]
    RFC --> RFP[PR fix -> develop]
    RFP --> IA
    RV -->|Pass| MA[Approval PR do master]
    MA --> MM[Rebase and merge do master]
```

## Twarde zasady

- przed rozpoczęciem taska agent sprawdza `READY.md` i `TODO.md`
- jedna capability ma jeden kanoniczny wpis w `READY.md`
- jedna capability ma najwyżej jeden otwarty wiersz w `TODO.md`
- `READY.md` opisuje capability już zmergowane do `develop`, a nie pomysły lub backlog
- `TODO.md` opisuje aktywne iteracje i sugestie, a nie gotowe capability
- żeby zmniejszyć konflikty, `READY.md` aktualizuje tylko `Develop Integration Agent`
- `Feature Agent` aktualizuje tylko własny wiersz w `TODO.md`; `Develop Integration Agent` go zamyka albo normalizuje przy merge
- pracujemy iteracyjnie w pętli `Research -> Plan -> Execute`
- testy są święte; jeśli pipeline jest czerwony, agent poprawia kod
- agent nie zmienia testów tylko po to, żeby pipeline zrobił się zielony
- przy rozwoju modułu stare zielone testy zostają bez zmian
- przy bugfixie agent dodaje test regresyjny; istniejący test zmienia tylko przy korekcie kontraktu
- jeśli pojawia się osobna, sensowna capability, wpisujemy ją do sugestii w `TODO.md`
- approval PR musi zrobić inna tożsamość GitHub niż autor PR
- `master` i `develop` są tylko do PR-ów i tylko do `Rebase and merge`
- nie używamy `Update branch`; zawsze robimy rebase na `origin/develop`

## Flow przy bardzo dużej skali

```mermaid
flowchart LR
    I[Pomysł od człowieka] --> RY[Research<br/>Sprawdź READY.md i TODO.md]
    RY --> C{Capability już istnieje<br/>albo już jest iterowana?}
    C -->|Tak| EX[Rozwijaj istniejący moduł]
    C -->|Nie| NM[Utwórz nową capability]
    EX --> S{Trzeba ruszyć shared contract?}
    NM --> F[Nowy moduł i izolowany entry point]
    S -->|Nie| F2[Pracuj w istniejącym module]
    S -->|Tak| PREP[Osobny PR przygotowawczy<br/>adapter registry interface]
    PREP --> F2
    F --> P2[Plan<br/>najmniejszy kolejny krok]
    F2 --> P2
    P2 --> TD2[TODO.md<br/>aktywny wiersz albo sugestia]
    TD2 --> PR[Execute<br/>mały PR do develop]
    PR --> Q[Develop Integration Agent<br/>aktualizuje READY.md i TODO.md]
    Q --> DEV[develop]
    DEV --> REL[PR develop -> master]
    REL --> PROD[master]
```

## Zasady skalowania

- każdy feature powinien trafiać głównie do własnego modułu
- najpierw sprawdzamy `READY.md` i `TODO.md`, żeby nie budować drugi raz tego samego capability pod inną nazwą
- wspólne kontrakty i typy powinny być wydzielone z logiki feature'ów
- jeśli kilka feature'ów dotyka tego samego pliku, to znak, że trzeba wydzielić adapter albo registry
- duże refaktory i zmiany kontraktów robi się osobno, nie razem z featurem
- nowe capability dopisujemy do `READY.md`, a rozwój lub bugfix aktualizuje istniejący wpis
- długi feature nie zakłada nowego duplikatu; utrzymuje jeden aktywny wiersz w `TODO.md` i iteruje po jednym kroku
- odrębne, pasujące follow-upy zapisujemy jako sugestie w `TODO.md`, a nie jako równoległe duplikaty
- przy dużym ruchu warto włączyć `Merge Queue` na `develop`
