Zusammenfassung der heutigen Gespräche
Ziel des Gesamtvorhabens

Das Hauptziel ist die Reduzierung der D365-Lizenzkosten, insbesondere in den Bereichen Pflege, Textil und Service Plus, ohne die Arbeitsfähigkeit der Anwender einzuschränken. Dazu sollen Rollen analysiert, aufgesplittet und anschließend fachlich getestet werden.

1. Lizenzanalyse und Rollenoptimierung
Ausgangssituation
Es wurde eine Analyse erstellt, die zeigt:
Welche Rollen existieren
Wie viele Benutzer die Rollen besitzen
Welche Lizenz die Rolle auslöst
Welche monatlichen Kosten dadurch entstehen
Die teuersten Rollen sollen zuerst betrachtet werden.
Die Analyse hat gezeigt, dass dieselbe Rolle unterschiedliche Lizenzkosten verursachen kann, weil Benutzer zusätzliche Rollen haben.
Wichtige Erkenntnis
Maßgeblich ist stets die teuerste Lizenz eines Benutzers.
Basislizenzen wie:
Finance
Supply Chain Management (SCM)
Commerce
haben Vorrang vor:
Activity
Team Member

Beispiel:

Ein Benutzer besitzt eine Activity-Rolle.
Eine zusätzliche Finance-Rolle löst jedoch eine Finance-Lizenz aus.
Die Activity-Lizenz spielt dann praktisch keine Rolle mehr.
Ziel
Identifizieren, welche Benutzer die teuren Zusatzlizenzen tatsächlich benötigen.
Möglichst viele Benutzer auf günstigere Lizenztypen zurückführen.
2. Vorgehen beim Rollensplitting
Grundidee
Rollen werden technisch aufgeteilt.
Fachliche Berechtigungen bleiben zunächst erhalten.
Teure Lizenzbestandteile werden in separate Zusatzrollen ausgelagert.

Beispiel:

Vertriebsrolle bleibt erhalten.
Finance-Berechtigungen werden in eine zusätzliche Rolle verschoben.
Vorteile
Bessere Transparenz.
Gezieltes Entziehen teurer Berechtigungen.
Geringeres Risiko bei Tests.
Schrittweise Optimierung möglich.
3. Teststrategie
Keine Einzeltests pro Mitarbeiter

Stattdessen:

Für jede Rolle werden 1-2 repräsentative Mitarbeiter ausgewählt.
Diese testen mit der neuen Rolle ihre tägliche Arbeit.

Beispiele:

Daniel testet Vertrieb.
Für Einkauf wird ein Vertreter aus dem Einkauf benötigt.
Weitere Testpersonen werden über die Fachbereiche bestimmt.
Testfrage

Die Anwender sollen prüfen:

Kann ich mit dieser Rolle meinen normalen Arbeitsalltag vollständig durchführen?

Bewertung

Wenn etwas nicht funktioniert:

Ist es ein echter Fehler?
Oder darf die Rolle diese Funktion bewusst nicht ausführen?

Nicht jede fehlende Berechtigung ist automatisch ein Problem.

4. Fachliche Verantwortung

Für jeden Bereich wird ein Verantwortlicher benötigt.

Aufgaben:

Tester benennen
Rollenänderungen bewerten
Berechtigungsbedarfe bestätigen
Entscheidungen dokumentieren

Das Rollenkonzept darf nicht ausschließlich von der IT gepflegt werden.

5. Service Plus

Für Service Plus soll ein strukturierter Ansatz aufgebaut werden.

Benötigt werden:

Rollen- und Stellenmatrix
Stelle
Rolle
Verantwortlicher
Aufgaben
Berechtigungen
Stellenbeschreibungen

Es soll dokumentiert werden:

Was eine Stelle im Alltag macht
Welche Prozesse genutzt werden
Welche Berechtigungen erforderlich sind
Testsuites

Für jede Stelle bzw. Rolle:

eigene Testsuite
eigene Testfälle
6. Trennung der Testarten

Es wurde mehrfach betont, dass folgende Themen getrennt werden müssen:

Rollen- und Berechtigungstests

Ziel:

Lizenzreduzierung
Rollenoptimierung
Prüfung von Berechtigungen
End-to-End- und Regressionstests

Ziel:

Fachliche Prozessvalidierung
Gesamtabnahme
Integrationstests

Beide Testarten haben:

unterschiedliche Ziele
unterschiedliche Teilnehmer
unterschiedliche Ergebnisse

Deshalb sollen sie in getrennten Testplänen geführt werden.

7. Testmanagement
Struktur

Eigener Testplan:

Rollen- und Berechtigungstests

Darin:

Testsuite je Rolle
Testsuite je Stelle

Die Fachbereiche sollen konkrete Arbeitsschritte beschreiben:

keine große Dokumentation
keine Theorie
reale Arbeitsschritte ("Durchklicktests")

Aus diesen Schritten entstehen die Testfälle.

8. Kommunikation
Jour fixe

Es sollen regelmäßige Termine stattfinden.

Geplant:

Strang A eigener Termin
Strang B eigener Termin

Nicht am gleichen Tag.

Grund:

Vorbereitung
Nachbereitung
Fokus auf ein Thema pro Woche
Ziel
Ergebnisse vorstellen
Probleme diskutieren
Entscheidungen dokumentieren
Fachbereiche einbinden
9. Organisatorische Grundsätze
Fokus auf wenige Themen gleichzeitig.
Schritt-für-Schritt-Vorgehen.
Erst die teuersten Rollen bearbeiten.
Änderungen sauber dokumentieren.
Fachbereiche aktiv einbinden.
Entscheidungen nachvollziehbar festhalten.
Vereinbarte nächsten Schritte
Teuerste Rollen priorisieren.
Rollen aufsplitten.
Fachliche Ansprechpartner benennen.
Testpersonen pro Bereich bestimmen.
Rollen- und Berechtigungstestplan aufbauen.
Service-Plus-Matrix erstellen.
Stellenbeschreibungen erarbeiten.
Tests durchführen.
Ergebnisse auswerten.
Lizenzpotenziale bewerten.
Änderungen schrittweise nach PROD übernehmen.
Regelmäßige Jour-fixe-Termine etablieren.

Kernaussage des gesamten Gesprächs:
 Die Lizenzoptimierung soll nicht theoretisch erfolgen, sondern durch ein kontrolliertes Rollensplitting, gezielte Praxistests mit repräsentativen Anwendern, klare Verantwortlichkeiten in den Fachbereichen und eine saubere Trennung von Berechtigungs- und Fachtests. Ziel ist die nachhaltige Reduzierung der Lizenzkosten bei gleichzeitig abgesicherter Arbeitsfähigkeit der Benutzer.
