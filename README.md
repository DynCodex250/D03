Viewed build_license_roles.R:30-60
Viewed export_role_xml.R:1-60
Viewed create_d365fo_security_configuration_xml.R:1-60
Viewed create_d365fo_role_xml.R:1-60
Viewed export_role_xml.R:60-140
Viewed export_role_xml.R:141-210
Viewed export_license_roles.R:1-60
Searched for "export_merged_role_xml"
Viewed export_merged_role_xml.R:1-60

Die gesuchte Funktion im Package heißt **[`export_role_xml()`](file:///c:/Users/XXX/Documents/RProjects/D365Security/R/export_role_xml.R)** (zusammen mit der Schwesterfunktion **[`export_merged_role_xml()`](file:///c:/Users/XXX/Documents/RProjects/D365Security/R/export_merged_role_xml.R)** für zusammengeführte Rollen).

Diese Funktion liest eine Rolle aus der Datenbank (`UserSecGovRelatedObjects`) und erzeugt bei einem Aufruf **automatisch alle 3 Fassungen**.

---

### Die 3 XML-Fassungen und ihre Zielordner

| Fassung | Ziel-Pfad / Format | Zweck / D365FO-Verwendung |
| :--- | :--- | :--- |
| **1. AOT-Objekt** | `<output_folder>/AxSecurityRole/<Name>.xml`<br>*(optional als `<Name>.zip`)* | **Visual Studio / Entwickler-Modell:** Direktes Hineinkopieren in das PackagesLocalDirectory eines Entwicklungs-Modells. |
| **2. Security Governance** | `<output_folder>/SecurityGovernance/<Name>.xml` | **Browser-Import:** D365FO *Sicherheitsgovernance > Sicherheits-Prozessrollen verwalten* (Export-/Import-Typ "Sicherheitskonfiguration"). |
| **3. Sicherheitskonfiguration** | `<output_folder>/SecurityConfiguration/<Name>.xml` | **Browser-Import:** D365FO *Systemverwaltung > Sicherheit > Sicherheitskonfiguration > Daten > Import*. |

> **Technischer Unterschied zwischen 2 & 3:**  
> Beide Browser-Dateien nutzen das Wurzelelement `<SecurityCustomizationData>`, unterscheiden sich im Microsoft-Standard aber in der XML-Serialisierung leerer Tags (Security Governance schreibt `<Forms />` mit Leerzeichen, Security Configuration schreibt `<Forms/>` ohne Leerzeichen).

---

### Anwendungs-Beispiel

```r
# 1. Package und Verbindung laden
library(D365Security)
con <- get_connection("ADN")

# 2. Rolle in allen 3 Fassungen exportieren
ergebnis <- export_role_xml(
  con             = con,
  role_identifier = "",  # AOT-Name oder GUID
  output_folder   = "Data/SecurityObjects",                   # Zielordner
  name            = "",  # Optional: Neuer AOT-Name
  label           = "Verkauf Innendienst Mitarbeiter",        # Optional: Neues Label
  zip             = TRUE,                                     # Erstellt auch das Visual Studio ZIP
  browser_files   = TRUE                                      # Erstellt die 2 Browser-XMLs (Gov & Config)
)

# 3. Pfade der erzeugten Dateien abrufen:
ergebnis$xml                     # Pfad zur AOT-Datei (AxSecurityRole/...)
ergebnis$zip                     # Pfad zum Visual Studio ZIP
ergebnis$security_governance      # Pfad zur Security Governance XML
ergebnis$security_configuration   # Pfad zur Sicherheitskonfiguration XML
ergebnis$subroles                # Übersicht der aufgelösten Unterrollen (AOT vs. UI)
```

---

### Die internen Bausteine (falls du Anpassungen am XML machen möchtest)

Wenn du das erzeugte XML anpassen möchtest, greifen folgende Skripte ineinander:

1. **[`R/export_role_xml.R`](file:///c:/Users/XXX/Documents/RProjects/D365Security/R/export_role_xml.R):**  
   Orchestriert den Ablauf, liest die Daten aus SQL und ruft die Datei-Schreiber auf.
2. **[`R/create_d365fo_role_xml.R`](file:///c:/Users/XXX/Documents/RProjects/D365Security/R/create_d365fo_role_xml.R):**  
   Baut das AOT-XML `<AxSecurityRole>` (Duties, Privileges, Subroles, Direct Access Permissions).
3. **[`R/create_d365fo_security_configuration_xml.R`](file:///c:/Users/XXX/Documents/RProjects/D365Security/R/create_d365fo_security_configuration_xml.R):**  
   Erzeugt den Browser-Umschlag `<SecurityCustomizationData>` und steuert über das Argument `format = "security_configuration"` bzw. `format = "security_governance"` die beiden Browser-Fassungen.
4. **[`R/export_merged_role_xml.R`](file:///c:/Users/XXX/Documents/RProjects/D365Security/R/export_merged_role_xml.R):**  
   Gleicher 3-Wege-Export, wenn du zwei Rollen (z. B. AOT-Rolle + UI-Version) zu einer konsolidierten Rolle mergen willst.

Die neue Funktion ist fertig implementiert und erfolgreich getestet. Wie gewünscht wurden **keine bestehenden Funktionen angefasst** – es wurde lediglich eine einzige neue Funktion hinzugefügt:

📁 **Neue Datei:** [export_role_from_graph_xml.R](file:///c:/Users/XXX/Documents/RProjects/D365Security/R/export_role_from_graph_xml.R)

---

### **Funktionsweise:**

```r
export_role_from_graph_xml(
  graph,                    # Dataframe/Tibble (oder Pfad zu Excel-Graph-Exporten)
  role_identifier = NULL,   # AOT-Name oder GUID (optional, falls nur 1 Rolle im Graph)
  output_folder,            # Zielverzeichnis
  name = NULL,              # Optionaler abweichender AOT-Name
  label = NULL,             # Optionales abweichendes Label
  zip = TRUE,               # ZIP-Archiv für Visual Studio erzeugen
  browser_files = TRUE,     # Die 2 Browser-Formate miterzeugen
  as_change = NULL          # Automatisch: TRUE für geänderte AOT-Rollen, FALSE für neue/GUID-Rollen
)
```

### **Erzeugt die 3 Fassungen (plus ZIP):**
1. **AOT-Rolle:** `<output_folder>/AxSecurityRole/<name>.xml` (Visual Studio / Quellcode-Modell)
2. **Security Governance:** `<output_folder>/SecurityGovernance/<name>.xml` (Browser-Import)
3. **Security Configuration:** `<output_folder>/SecurityConfiguration/<name>.xml` (Browser-Import via Systemadministration > Sicherheitskonfiguration)
4. **ZIP-Archiv:** `<output_folder>/<name>.zip` (gepackter AOT-Ordner)

---




### **Test-Ergebnis mit realen Daten:**

Getestet sowohl für Rollen mit direkten Duties (`ProdProductionSupervisor`) als auch für Rollen mit Subrollen (`XXXX_Debitorenbuchhaltung`):

- **AOT-XML erzeugt:** `AxSecurityRole/ProdProductionSupervisor.xml` ✅
- **SecurityGovernance-XML erzeugt:** `SecurityGovernance/ProdProductionSupervisor.xml` ✅
- **SecurityConfiguration-XML erzeugt:** `SecurityConfiguration/ProdProductionSupervisor.xml` ✅
- **ZIP-Archiv erzeugt:** `ProdProductionSupervisor.zip` ✅
- **Subrollen-Trennung:** Duties und Privilegien aus Subrollen verbleiben sauber in den Subrollen, direkte Duties/Privilegien werden der Rolle direkt zugeordnet ✅

### **Neue optionale Parameter:**

```r
find_menu_item_security(
  menu_item            = NULL,  # Auch als securable_name / SECURABLENAME
  privilege_identifier = NULL,  # Auch als PRIVILEGEIDENTIFIER
  duty_identifier      = NULL,  # Auch als DUTYIDENTIFIER
  role_identifier      = NULL,  # Auch als ROLEIDENTIFIER / ROLEIDENTIFIE
  role_name            = NULL,  # Auch als ROLENAME
  con                  = NULL,  # Aktive DB-Verbindung (optional)
  graph                = NULL,  # Bereits geladener Lizenzgraph (optional)
  path                 = NULL,  # Pfad zu Graph-Dateien (optional)
  exact                = TRUE,  # Exakt oder Teilstring/Regex
  quiet                = FALSE
)
```

---

### **Highlights & Flexibilität:**
1. **Beliebige Kombinationen möglich:** Man kann nach einem Menu Item suchen und gleichzeitig nach Rolle, Duty oder Privileg filtern – oder auch direkt ohne `menu_item` nur nach einer bestimmten Duty/Rolle suchen (z. B. alle enthaltenen Menu Items samt Lizenz).
2. **Unterstützung beider Schreibweisen:** Sowohl R-typische Parameter (`role_identifier`, `duty_identifier`, ...) als auch die originalen Spaltennamen der Tabelle (`ROLEIDENTIFIER`, `DUTYIDENTIFIER`, `PRIVILEGEIDENTIFIER`, `ROLENAME`, `SECURABLENAME`) werden direkt über `...` akzeptiert.
3. **Optimiert für Online (SQL) & Offline (Graph-Dateien):**
   - Im SQL-Modus (`con`) wird die dynamische `WHERE`-Klausel direkt serverseitig mit `AND` für alle angegebenen Spalten aufgebaut.
   - Im Graph-/Excel-Modus (`graph` oder automatische Erkennung) wird der Dataframe vektorisiert über alle Kriterien gefiltert.

---

### **Anwendungsbeispiele:**

```r
# 1. Menu Item filtern nach einer bestimmten Rolle:
find_menu_item_security(
  menu_item       = "FactureIncomingDocRegister_IT",
  role_identifier = "LedgerAccountant"
)

# 2. Direkt mit den Tabellenspalten als Parameter aufrufen:
find_menu_item_security(
  DUTYIDENTIFIER = "ProdProductionOrderFeedbackMaintain"
)

# 3. Alle Menu Items und Lizenzen einer Rolle auflisten:
find_menu_item_security(
  ROLEIDENTIFIER = "ProdProductionSupervisor"
)

# 4. Nach Privileg suchen:
find_menu_item_security(
  PRIVILEGEIDENTIFIER = "CustomJournalTableMaintain_IT"
)

# 5. Suche nach Rollenname:
find_menu_item_security(
  ROLENAME = "Accounting manager",
  exact    = FALSE
)
```
