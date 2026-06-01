# TODO Registry

`TODO.md` jest rejestrem aktywnych iteracji capability, które wymagają więcej niż jednego kroku albo więcej niż jednego PR-a.
Capability już gotowe albo już dostępne w `develop` opisuje `READY.md`.

## Flow `Research -> Plan -> Execute`

1. `Research`: sprawdź `READY.md`, `TODO.md`, kod, testy i obecny kontrakt modułu
2. `Plan`: wybierz najmniejszy następny krok, zdecyduj czy to `new capability`, `extension` albo `bugfix`, i zaktualizuj odpowiedni wiersz w tabeli aktywnej
3. `Execute`: zrealizuj tylko ten krok, uruchom testy i otwórz jeden mały PR
4. jeśli po tej iteracji feature nadal nie jest gotowy, nie twórz drugiego feature'a; wróć do `Research` i kontynuuj ten sam wiersz w `TODO.md`
5. jeśli w trakcie pracy pojawi się osobna, sensowna capability, wpisz ją do tabeli sugestii, zamiast zaczynać równoległy duplikat

## Zasady aktualizacji

1. jeden aktywny feature = jeden kanoniczny wiersz w tabeli aktywnej
2. jedna capability może mieć wiele branchy i wiele PR-ów, ale tylko jeden aktywny wiersz w `TODO.md`
3. Feature Agent aktualizuje własny wiersz podczas `Research`, `Plan` i `Execute`
4. Develop Integration Agent może znormalizować albo zamknąć wiersz przy merge do `develop`
5. nowe aktywne wiersze dopisuj na końcu tabeli; nie sortuj całego pliku przy zwykłej pracy
6. jeśli capability nie ma już otwartych kolejnych kroków, usuń ją z tabeli aktywnej po upewnieniu się, że `READY.md` jest aktualne
7. sugestia staje się aktywnym featurem dopiero wtedy, gdy zostanie wybrana jako realny następny task

## Tabela aktywnych iteracji

| Capability / feature | Linked READY capability | Type | Current phase | Next smallest task | Current branch / PR | Owner | Started on | Last updated on | Notes |
| -------------------- | ----------------------- | ---- | ------------- | ------------------ | ------------------- | ----- | ---------- | --------------- | ----- |

## Tabela sugestii powiązanych feature'ów

| Suggested feature | Parent capability | Why it fits | Suggested by | Suggested on | State |
| ----------------- | ----------------- | ----------- | ------------ | ------------ | ----- |
