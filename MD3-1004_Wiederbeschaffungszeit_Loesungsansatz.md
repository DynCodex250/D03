# MD3-1004 Wiederbeschaffungszeit – Lösungsweg & Herausforderungen

> Dies ist ein bewusst **allgemein gehaltenes** Begleitdokument zur vollständigen technischen Spezifikation (`MD3-1004_Wiederbeschaffungszeit_Schnittstellendokumentation_TDD.md`). Es beschreibt **wie wir das Problem angegangen sind und welche Hürden dabei aufgetreten sind** — nicht die konkrete technische Umsetzung (Schlüssel, Joins, Spaltennamen). Ziel ist, dass du dir einen eigenen Lösungsweg für Power Automate überlegen kannst, ohne an unsere Umsetzung gebunden zu sein. Die detaillierte Feld-für-Feld-Spezifikation steht bei Bedarf in der TDD.

---

## Ausgangslage

Artikel, die in den deutschen Mandanten (0800/0900) als Direktlieferungsartikel geführt werden, haben dort eine hinterlegte Wiederbeschaffungszeit. Im österreichischen Mandanten 0360 fehlt diese Information in den Standardauftragseinstellungen, wodurch bei der Auftragserfassung ein falsches (zu frühes) Versanddatum vorgeschlagen wird. Die Wiederbeschaffungszeit soll daher aus den deutschen Mandanten nach 0360 übernommen werden.

## Was am Ende erreicht werden muss

Für jeden betroffenen Artikel in 0360 müssen letztlich nur **drei Felder** in den Standardauftragseinstellungen befüllt werden (siehe Tabelle am Ende). Der eigentliche Aufwand steckt nicht im Befüllen selbst, sondern darin, **die richtigen Werte für die richtigen Artikel zusammenzubekommen** — und genau das war die eigentliche Herausforderung.

## Unser Weg — und die Hürden dabei

Wir sind nicht den naheliegendsten Weg gegangen (z. B. zwei getrennte, unabhängige Abgleiche für 0800→0360 und 0900→0360), sondern haben uns bewusst für einen anderen Ansatz entschieden. Die folgenden Punkte beschreiben die Entscheidungen und Probleme, auf die wir dabei gestoßen sind — nicht als Vorgabe, sondern als Erfahrungswerte, die bei einer Power-Automate-Umsetzung vermutlich in ähnlicher Form wieder auftauchen:

* **Mehrere Quellmandanten, ein Ziel:** Die relevanten Artikeldaten liegen verteilt in zwei deutschen Mandanten (0800 und 0900) vor. Grundsätzlich hätte man diese beiden Quellen komplett getrennt behandeln und auch zwei getrennte Importe nach 0360 fahren können.
* **Entscheidung für ein gemeinsames Importpaket:** Wir wollten am Ende nur **einen** Import nach 0360 anstoßen, nicht zwei. Das bedeutet, dass die Daten aus 0800 und 0900 vorher zu **einer** gemeinsamen Quelle zusammengeführt werden mussten. Das ist eine bewusste Designentscheidung gewesen, keine zwingende Notwendigkeit — wenn zwei getrennte Importe für Power Automate einfacher umzusetzen sind, spricht nichts dagegen.
* **Artikel mit und ohne Varianten zusammenbringen:** Ein Teil der Artikel wird mit Varianten geführt (z. B. nach Farbe/Größe differenziert), ein anderer Teil nicht (reine Hauptartikel ohne Varianten). Beide Fälle liefern strukturell unterschiedliche Daten und mussten in eine **gemeinsame, einheitliche Struktur** überführt werden, damit der nachfolgende Abgleich für beide Artikeltypen gleich funktioniert. Das war einer der aufwendigeren Teile, weil man für Artikel ohne Varianten andere/fehlende Felder hat als für Artikel mit Varianten.
* **Lebenszyklus-/Sperrstatus prüfen:** Nicht jeder Artikel darf einfach aktualisiert werden. Es musste geprüft werden, in welchem Lebenszyklus-Status (z. B. "gesperrt", "endgültig gesperrt") ein Artikel steht, damit für gesperrte Artikel **keine** Daten übertragen bzw. überschrieben werden. Diese Prüfung lief über zusätzliche Produktstammdaten, die separat herangezogen werden mussten.
* **Mögliche widersprüchliche Werte zwischen den Quellmandanten:** Da die Daten aus zwei Quellmandanten (0800 und 0900) zusammengeführt werden, kann es vorkommen, dass derselbe Artikel in beiden Mandanten unterschiedliche Wiederbeschaffungszeiten hat. Das ist kein technischer, sondern ein **fachlicher** Fall, der erkannt und (von der IT nicht automatisch, sondern durch den Fachbereich) entschieden werden muss.
* **Artikel ohne Treffer:** Nicht jeder Artikel in 0360 findet überhaupt ein Gegenstück in den deutschen Mandanten (weil er dort z. B. gar kein Direktlieferungsartikel ist). Für diese Artikel darf logischerweise auch nichts aktualisiert werden.

Keiner dieser Punkte erzwingt eine bestimmte technische Lösung. Entscheidend ist nur, dass das Endergebnis diese Fälle korrekt abbildet — **wie** (ein Flow oder mehrere, ein kombinierter Datensatz oder getrennte Abgleiche je Mandant, etc.) ist offen.

## Was am Ende tatsächlich gesetzt wird

Unabhängig vom gewählten technischen Weg landen pro Artikel nur folgende drei Felder in den Standardauftragseinstellungen von 0360:

| Feld | Zielwert |
|---|---|
| Lieferungskontrolle überschreiben | `"Yes"` (fester Wert) |
| Lieferdatumskontrolle | `"ATPPlusIssueMargin"` (fester Wert, = VfZ + Sicherheitszuschlag) |
| VfZ Planungszeitraum | Wiederbeschaffungszeit des Artikels aus dem deutschen Mandanten (0800 oder 0900), in dem er als Direktlieferungsartikel geführt wird |

Dazu kommt als vierter, "weicher" Baustein: **Rückverfolgbarkeit/Rollback**. Da produktive Stammdaten verändert werden, sollte vor jeder Änderung festgehalten werden, welcher Wert vorher in 0360 stand, damit eine Änderung bei Bedarf rückgängig gemacht werden kann. Wie das technisch gelöst wird, ist ebenfalls offen — wichtig ist nur, dass es diese Möglichkeit gibt.

---

*Für die exakte Feld-/Spalten-/Schlüssel-Logik unserer Umsetzung siehe `MD3-1004_Wiederbeschaffungszeit_Schnittstellendokumentation_TDD.md`.*
