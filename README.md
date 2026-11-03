

Das Problem wurde behoben!

### **Ursache des Fehlers:**
[find_menu_item_security()](file:///c:/Users/XXX/Documents/RProjects/D365Security/R/find_menu_item_security.R) hatte zuvor sprechende Spaltennamen wie `ROLE_ID`, `ROLE_NAME`, `DUTY_ID`, `MENU_ITEM` zurückgegeben.  
[export_role_from_graph_xml()](file:///c:/Users/XXX/Documents/RProjects/D365Security/R/export_role_from_graph_xml.R) erwartet jedoch die originalen Spalten der Tabelle `LicensingSecurityObjectExplodedGraph` (`ROLEIDENTIFIER`, `ROLENAME`, `DUTYIDENTIFIER`, `PRIVILEGEIDENTIFIER`, `SECURABLENAME`, etc.).

---

### **Umgesetzte Anpassungen:**

1. **[find_menu_item_security()](file:///c:/Users/XXX/Documents/RProjects/D365Security/R/find_menu_item_security.R) liefert jetzt exakt das Standard-Graph-Schema:**
   - `ROLEIDENTIFIER`
   - `ROLENAME`
   - `SUBROLEIDENTIFIER`
   - `SUBROLENAME`
   - `DUTYIDENTIFIER`
   - `DUTYNAME`
   - `PRIVILEGEIDENTIFIER`
   - `PRIVILEGENAME`
   - `SECURABLETYPE`
   - `SECURABLENAME`
   - `SECURABLECHILDNAME`
   - `ACCESSLEVEL`
   - `LICENSE`

2. **[export_role_from_graph_xml()](file:///c:/Users/XXX/Documents/RProjects/D365Security/R/export_role_from_graph_xml.R) ist nun zusätzlich fehlertolerant:**
   - **Automatische Alias-Erkennung:** Erkennt und akzeptiert auch `ROLE_ID`, `ROLE_NAME`, `DUTY_ID`, `PRIVILEGE_ID`, `SUBROLE_ID`, `MENU_ITEM`.
   - **Intelligente AOT-Namenserkennung:** Falls bei einer Mutation (wie in deinem Screenshot) der Identifier Leerzeichen enthält, der Rollenname jedoch ein gültiger AOT-Name ohne Leerzeichen ist, werden Name und Label automatisch korrekt zugeordnet.

---

### **So funktioniert dein Code jetzt nahtlos:**

Sowohl mit den neuen Spaltennamen:

```r
t <- find_menu_item_security(
  con = cnn,
  PRIVILEGEIDENTIFIER = c("SalesFormLetter_InvoiceMaintain", "CredManForceHoldProcess"),
  ROLEIDENTIFIER      = c("CollectionLetterCollectionsManager", "CustInvoiceAccountsReceivableClerk")
) |> 
  dplyr::mutate(
    ROLEIDENTIFIER    = "XXXX",
    ROLENAME          = "XXXX",
    SUBROLEIDENTIFIER = NA_character_,
    DUTYIDENTIFIER    = NA_character_,
    DUTYNAME          = NA_character_
  )

export_role_from_graph_xml(
  graph         = t,
  output_folder = "Data/SecurityObjects"
)
```

... als auch wenn du deinen bisherigen Aufruf mit `ROLE_ID` / `ROLE_NAME` ausführst!

Das ADN-Archiv [D365Security_ADN_Test.zip](file:///C:/Users/XXX/Downloads/D365Security_ADN_Test.zip) wurde ebenfalls direkt mit den Korrekturen neu erstellt.


Listed directory Deliverables
Viewed Offene_Punkte.md:1-100

Das ist eine klassische Führungssituation. Die Frage der IT-Leitung **„Kann ich dir helfen?“** ist keine Niederlage, sondern deine **größte Chance**:

1. **Psychologischer Dreh:** Geh **nicht** defensiv hinein („Ich rechtfertige mich, warum es so lange dauert“). Tritt als **Architekt und Projektsteuerer** auf, der das Thema von einem unkontrollierten Chaos in ein revisionssicheres, kostensparendes System überführt hat.
2. **Die Realität:** Bei D365-Berechtigungen dauert *nie* die IT-Arbeit am längsten, sondern die **Abstimmung, Disziplin und Testbereitschaft der Fachbereiche**.
3. **Sein Hilfsangebot nutzen:** Wenn ein IT-Leiter fragt „Kann ich helfen?“, sagst du nicht „Nein, alles gut“, sondern: **„Ja, genau an drei Stellen brauche ich deinen Management-Hebel!“** Damit machst du ihn zum Verbündeten.
