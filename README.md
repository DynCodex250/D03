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

Welche Anpassung möchtest du an der Erstellung oder an der Struktur des XMLs vornehmen?
