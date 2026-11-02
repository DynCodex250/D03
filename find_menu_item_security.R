#' Suche nach einem Menu Item in der Security-Hierarchie und Ermittlung der Lizenz
#'
#' Findet für D365FO Menu Items (Securable Objects), Privilegien (Rechte), Duties (Aufgaben)
#' oder Rollen alle übergeordneten und untergeordneten Verknüpfungen sowie die jeweils
#' ausgelöste Lizenz (SKU / Tier), differenziert nach Lese- und Schreibzugriff (Access Level).
#'
#' @details
#' Die Funktion unterstützt zwei Betriebsmodi:
#' \enumerate{
#'   \item \strong{Online / Datenbank:} Über eine aktive Datenbankverbindung (\code{con}).
#'     Es wird vorrangig die Tabelle \code{LicensingSecurityObjectExplodedGraph} abgefragt.
#'     Sollte diese nicht vorhanden sein, erfolgt ein Fallback über
#'     \code{UserSecGovRelatedObjects} und die Lizenz-Views.
#'   \item \strong{Offline / Excel & Graph:} Ohne Datenbankverbindung über einen
#'     übergebenen Lizenzgraphen (\code{graph}), eine Datei (\code{path}) oder
#'     automatische Erkennung lokaler Excel-Exporte im Projekt.
#' }
#'
#' Neben \code{menu_item} können auch \code{privilege_identifier}, \code{duty_identifier},
#' \code{role_identifier} und \code{role_name} als Filterkriterien übergeben werden.
#' Werden mehrere Filter angegeben, werden sie per logischem \strong{UND} verknüpft.
#' Großgeschriebene Spaltennamen (z. B. \code{PRIVILEGEIDENTIFIER}, \code{DUTYIDENTIFIER},
#' \code{ROLEIDENTIFIER}, \code{ROLENAME}, \code{SECURABLENAME}) werden ebenfalls unterstützt.
#'
#' @param menu_item
#' Optionaler Character-Vektor mit einem oder mehreren Namen von Menu Items / Securable Objects
#' (z. B. \code{"CustTable"}, \code{"SalesTableListPage"}).
#'
#' @param privilege_identifier
#' Optionaler Character-Vektor mit einem oder mehreren Privilegien-Identifiern
#' (Spalte \code{PRIVILEGEIDENTIFIER}).
#'
#' @param duty_identifier
#' Optionaler Character-Vektor mit einem oder mehreren Duty-Identifiern
#' (Spalte \code{DUTYIDENTIFIER}).
#'
#' @param role_identifier
#' Optionaler Character-Vektor mit einem oder mehreren Rollen-Identifiern / AOT-Namen / GUIDs
#' (Spalte \code{ROLEIDENTIFIER}).
#'
#' @param role_name
#' Optionaler Character-Vektor mit einem oder mehreren Rollenanzeigenamen
#' (Spalte \code{ROLENAME}).
#'
#' @param con
#' Optionale Datenbankverbindung (Ergebnis von \code{get_connection()}).
#'
#' @param graph
#' Optionales Tibble eines bereits geladenen Lizenzgraphen (Ergebnis von \code{read_license_graph()}).
#'
#' @param secgov
#' Optionales Tibble mit Daten aus \code{UserSecGovRelatedObjects}.
#'
#' @param path
#' Optionaler Pfad zu einer Excel-Exportdatei oder einem Ordner mit
#' \code{LICENSINGSECURITYOBJECTEXPLODEDGRAPH_*.xlsx}-Dateien. Wird weder \code{con},
#' \code{graph} noch \code{path} angegeben, sucht die Funktion automatisch nach
#' vorhandenen Graph-Dateien in den bekannten Projektordnern.
#'
#' @param exact
#' Logical. \code{TRUE} (Standard) für exakte Übereinstimmung der Werte (case-insensitive);
#' \code{FALSE} für Teilstring- bzw. Regex-Suche.
#'
#' @param quiet
#' Logical. Wenn \code{FALSE} (Standard), wird eine kurze Zusammenfassung auf der
#' Konsole ausgegeben.
#'
#' @param ...
#' Optionale Aliase für Spaltennamen im SQL-Format wie \code{SECURABLENAME},
#' \code{PRIVILEGEIDENTIFIER}, \code{DUTYIDENTIFIER}, \code{ROLEIDENTIFIER},
#' \code{ROLEIDENTIFIE} oder \code{ROLENAME}.
#'
#' @return
#' Ein Tibble mit folgenden Spalten:
#' \describe{
#'   \item{MENU_ITEM}{Name des Menu Items / Securable Objects.}
#'   \item{ACCESS_LEVEL}{Zugriffsstufe (\code{"Read"} oder \code{"Write"}).}
#'   \item{LICENSE}{Ausgelöste Lizenz (z. B. \code{"Finance or Supply Chain Management"}, \code{"Operations - Activity"}).}
#'   \item{PRIVILEGE_ID}{Technischer Identifier des Privilegs.}
#'   \item{PRIVILEGE_NAME}{Anzeigename des Privilegs.}
#'   \item{DUTY_ID}{Technischer Identifier der Duty.}
#'   \item{DUTY_NAME}{Anzeigename der Duty.}
#'   \item{ROLE_ID}{Technischer Identifier der Rolle (AOT-Name oder GUID).}
#'   \item{ROLE_NAME}{Anzeigename der Rolle.}
#'   \item{SUBROLE_ID}{Optionaler Identifier einer untergeordneten Rolle (falls vorhanden).}
#' }
#'
#' @examples
#' \dontrun{
#' # 1. Nach Menu Item suchen:
#' find_menu_item_security("SalesTable", con = con)
#'
#' # 2. Nach Menu Item gefiltert nach Rolle:
#' find_menu_item_security("CustTable", role_identifier = "ProdProductionSupervisor", graph = graph)
#'
#' # 3. Nach Duty oder Privileg suchen (auch mit Spaltennamen der Tabelle):
#' find_menu_item_security(DUTYIDENTIFIER = "FactureIncomingDocRegisterInquire_IT")
#'
#' # 4. Teilstring-Suche:
#' find_menu_item_security("CustInvoice", exact = FALSE)
#' }
#'
#' @export
find_menu_item_security <- function(menu_item = NULL,
                                    privilege_identifier = NULL,
                                    duty_identifier = NULL,
                                    role_identifier = NULL,
                                    role_name = NULL,
                                    con = NULL,
                                    graph = NULL,
                                    secgov = NULL,
                                    path = NULL,
                                    exact = TRUE,
                                    quiet = FALSE,
                                    ...) {

  dots <- list(...)

  # Aliase für flexible Parameterübergabe im SQL-Stil
  if (is.null(menu_item)) {
    if (!is.null(dots$securable_name)) menu_item <- dots$securable_name
    if (!is.null(dots$SECURABLENAME))  menu_item <- dots$SECURABLENAME
  }
  if (is.null(privilege_identifier)) {
    if (!is.null(dots$PRIVILEGEIDENTIFIER)) privilege_identifier <- dots$PRIVILEGEIDENTIFIER
    if (!is.null(dots$privilege))           privilege_identifier <- dots$privilege
  }
  if (is.null(duty_identifier)) {
    if (!is.null(dots$DUTYIDENTIFIER)) duty_identifier <- dots$DUTYIDENTIFIER
    if (!is.null(dots$duty))           duty_identifier <- dots$duty
  }
  if (is.null(role_identifier)) {
    if (!is.null(dots$ROLEIDENTIFIER)) role_identifier <- dots$ROLEIDENTIFIER
    if (!is.null(dots$ROLEIDENTIFIE))  role_identifier <- dots$ROLEIDENTIFIE
    if (!is.null(dots$role_id))        role_identifier <- dots$role_id
    if (!is.null(dots$role))           role_identifier <- dots$role
  }
  if (is.null(role_name)) {
    if (!is.null(dots$ROLENAME)) role_name <- dots$ROLENAME
  }

  target_items   <- if (!is.null(menu_item)) trimws(as.character(menu_item)) else NULL
  priv_filter    <- if (!is.null(privilege_identifier)) trimws(as.character(privilege_identifier)) else NULL
  duty_filter    <- if (!is.null(duty_identifier)) trimws(as.character(duty_identifier)) else NULL
  role_id_filter <- if (!is.null(role_identifier)) trimws(as.character(role_identifier)) else NULL
  role_nm_filter <- if (!is.null(role_name)) trimws(as.character(role_name)) else NULL

  # Bereinigen von leeren Werten
  if (!is.null(target_items))   target_items   <- target_items[nzchar(target_items)]
  if (!is.null(priv_filter))    priv_filter    <- priv_filter[nzchar(priv_filter)]
  if (!is.null(duty_filter))    duty_filter    <- duty_filter[nzchar(duty_filter)]
  if (!is.null(role_id_filter)) role_id_filter <- role_id_filter[nzchar(role_id_filter)]
  if (!is.null(role_nm_filter)) role_nm_filter <- role_nm_filter[nzchar(role_nm_filter)]

  has_filter <- any(c(
    length(target_items) > 0L,
    length(priv_filter) > 0L,
    length(duty_filter) > 0L,
    length(role_id_filter) > 0L,
    length(role_nm_filter) > 0L
  ))

  if (!has_filter) {
    stop(
      "Bitte mindestens ein Filterkriterium angeben (menu_item / SECURABLENAME, ",
      "privilege_identifier / PRIVILEGEIDENTIFIER, duty_identifier / DUTYIDENTIFIER, ",
      "role_identifier / ROLEIDENTIFIER oder role_name / ROLENAME).",
      call. = FALSE
    )
  }

  raw_res <- NULL

  # ===========================================================================
  # STRATEGIE 1: In-Memory Lizenzgraph (übergeben)
  # ===========================================================================
  if (!is.null(graph) && is.data.frame(graph) && nrow(graph) > 0L) {
    if (!quiet) message(">> Durchsuche übergebenen Lizenzgraphen...")
    raw_res <- .filter_license_graph(
      graph,
      target_items   = target_items,
      priv_filter    = priv_filter,
      duty_filter    = duty_filter,
      role_id_filter = role_id_filter,
      role_nm_filter = role_nm_filter,
      exact          = exact
    )
  }

  # ===========================================================================
  # STRATEGIE 2: Datenbankverbindung
  # ===========================================================================
  if (is.null(raw_res) && !is.null(con)) {
    if (!quiet) message(">> Frage D365FO-Datenbank ab...")
    raw_res <- .query_db_for_menu_item(
      con,
      target_items   = target_items,
      priv_filter    = priv_filter,
      duty_filter    = duty_filter,
      role_id_filter = role_id_filter,
      role_nm_filter = role_nm_filter,
      exact          = exact
    )
  }

  # ===========================================================================
  # STRATEGIE 3: Expliziter Pfad oder automatische Dateisuche
  # ===========================================================================
  if (is.null(raw_res)) {
    graph_files <- character()

    if (!is.null(path) && length(path) > 0L) {
      if (all(dir.exists(path))) {
        graph_files <- list.files(path, pattern = "EXPLODEDG.*[.]xlsx$", full.names = TRUE, ignore.case = TRUE)
      } else if (all(file.exists(path))) {
        graph_files <- path
      }
    }

    # Automatische Ordnersuche
    if (length(graph_files) == 0L) {
      search_dirs <- c(
        "Data/Input",
        "Data/Input/PPAC",
        "../Input/Excel/Database",
        "../Input/Excel",
        "Input/Excel/Database",
        "Input/Excel"
      )
      for (d in search_dirs) {
        if (dir.exists(d)) {
          found <- list.files(d, pattern = "EXPLODEDG.*[.]xlsx$", full.names = TRUE, ignore.case = TRUE)
          if (length(found) > 0L) {
            graph_files <- found
            break
          }
        }
      }
    }

    if (length(graph_files) > 0L) {
      if (!quiet) message(">> Lese lokale Lizenzgraph-Dateien: ", paste(basename(graph_files), collapse = ", "))
      loaded_graph <- .read_graph_files_internal(graph_files)
      raw_res <- .filter_license_graph(
        loaded_graph,
        target_items   = target_items,
        priv_filter    = priv_filter,
        duty_filter    = duty_filter,
        role_id_filter = role_id_filter,
        role_nm_filter = role_nm_filter,
        exact          = exact
      )
    }
  }

  # ===========================================================================
  # STRATEGIE 4: Fallback über UserSecGovRelatedObjects (ohne Voll-Graph)
  # ===========================================================================
  if (is.null(raw_res) && !is.null(secgov) && is.data.frame(secgov)) {
    if (!quiet) message(">> Nutze UserSecGovRelatedObjects...")
    raw_res <- .filter_secgov_objects(
      secgov,
      target_items   = target_items,
      priv_filter    = priv_filter,
      duty_filter    = duty_filter,
      role_id_filter = role_id_filter,
      role_nm_filter = role_nm_filter,
      exact          = exact
    )
  }

  # ===========================================================================
  # ERGEBNIS-AUFBEREITUNG
  # ===========================================================================
  filters_desc <- c(
    if (length(target_items) > 0L)   paste0("MenuItem=", paste(target_items, collapse = ",")),
    if (length(priv_filter) > 0L)    paste0("Privilege=", paste(priv_filter, collapse = ",")),
    if (length(duty_filter) > 0L)    paste0("Duty=", paste(duty_filter, collapse = ",")),
    if (length(role_id_filter) > 0L) paste0("RoleId=", paste(role_id_filter, collapse = ",")),
    if (length(role_nm_filter) > 0L) paste0("RoleName=", paste(role_nm_filter, collapse = ","))
  )

  if (is.null(raw_res) || nrow(raw_res) == 0L) {
    if (!quiet) {
      message("Keine Treffer für Filter: ", paste(filters_desc, collapse = " & "))
      message("Hinweis: Bitte Verbindung (con) oder Lizenzgraph (graph / Pfad) bereitstellen.")
    }
    return(.empty_menu_item_result())
  }

  res <- raw_res |>
    dplyr::distinct() |>
    dplyr::arrange(MENU_ITEM, ACCESS_LEVEL, ROLE_NAME, DUTY_NAME, PRIVILEGE_NAME)

  if (!quiet) {
    .print_menu_item_summary(
      res,
      target_items   = target_items,
      priv_filter    = priv_filter,
      duty_filter    = duty_filter,
      role_id_filter = role_id_filter,
      role_nm_filter = role_nm_filter
    )
  }

  tibble::as_tibble(res)
}

# =============================================================================
# INTERNE HILFSFUNKTIONEN
# =============================================================================

.filter_license_graph <- function(df,
                                  target_items = NULL,
                                  priv_filter = NULL,
                                  duty_filter = NULL,
                                  role_id_filter = NULL,
                                  role_nm_filter = NULL,
                                  exact = TRUE) {
  cols <- toupper(names(df))
  names(df) <- cols

  sec_col <- if ("SECURABLENAME" %in% cols) "SECURABLENAME" else if ("RESOURCE_" %in% cols) "RESOURCE_" else NULL

  n_rows <- nrow(df)
  keep <- rep(TRUE, n_rows)

  .match_col <- function(col_name, filter_vals) {
    if (is.null(filter_vals) || length(filter_vals) == 0L) return(rep(TRUE, n_rows))
    if (!col_name %in% cols) return(rep(FALSE, n_rows))
    vals <- as.character(df[[col_name]])
    vals[is.na(vals)] <- ""
    if (exact) {
      tolower(trimws(vals)) %in% tolower(trimws(filter_vals))
    } else {
      pattern <- paste(filter_vals, collapse = "|")
      grepl(pattern, vals, ignore.case = TRUE)
    }
  }

  if (!is.null(target_items) && length(target_items) > 0L) {
    if (!is.null(sec_col)) {
      keep <- keep & .match_col(sec_col, target_items)
    } else {
      return(NULL)
    }
  }

  if (!is.null(priv_filter) && length(priv_filter) > 0L) {
    keep <- keep & .match_col("PRIVILEGEIDENTIFIER", priv_filter)
  }

  if (!is.null(duty_filter) && length(duty_filter) > 0L) {
    keep <- keep & .match_col("DUTYIDENTIFIER", duty_filter)
  }

  if (!is.null(role_id_filter) && length(role_id_filter) > 0L) {
    keep <- keep & .match_col("ROLEIDENTIFIER", role_id_filter)
  }

  if (!is.null(role_nm_filter) && length(role_nm_filter) > 0L) {
    keep <- keep & .match_col("ROLENAME", role_nm_filter)
  }

  matched <- df[keep, , drop = FALSE]
  if (nrow(matched) == 0L) return(NULL)

  sec_name <- if (!is.null(sec_col)) as.character(matched[[sec_col]]) else NA_character_
  acc_lvl <- if ("ACCESSLEVEL" %in% cols) {
    val <- as.character(matched$ACCESSLEVEL)
    ifelse(val == "1", "Read", ifelse(val == "2", "Write", val))
  } else {
    "Unknown"
  }

  lic <- if ("LICENSE" %in% cols) as.character(matched$LICENSE) else "Unbekannt"
  priv_id <- if ("PRIVILEGEIDENTIFIER" %in% cols) as.character(matched$PRIVILEGEIDENTIFIER) else NA_character_
  priv_nm <- if ("PRIVILEGENAME" %in% cols) as.character(matched$PRIVILEGENAME) else priv_id
  duty_id <- if ("DUTYIDENTIFIER" %in% cols) as.character(matched$DUTYIDENTIFIER) else NA_character_
  duty_nm <- if ("DUTYNAME" %in% cols) as.character(matched$DUTYNAME) else duty_id
  role_id <- if ("ROLEIDENTIFIER" %in% cols) as.character(matched$ROLEIDENTIFIER) else NA_character_
  role_nm <- if ("ROLENAME" %in% cols) as.character(matched$ROLENAME) else role_id
  sub_id  <- if ("SUBROLEIDENTIFIER" %in% cols) as.character(matched$SUBROLEIDENTIFIER) else NA_character_

  data.frame(
    MENU_ITEM      = sec_name,
    ACCESS_LEVEL   = acc_lvl,
    LICENSE        = lic,
    PRIVILEGE_ID   = priv_id,
    PRIVILEGE_NAME = priv_nm,
    DUTY_ID        = duty_id,
    DUTY_NAME      = duty_nm,
    ROLE_ID        = role_id,
    ROLE_NAME      = role_nm,
    SUBROLE_ID     = sub_id,
    stringsAsFactors = FALSE
  )
}

.build_sql_clause <- function(col_name, filter_vals, exact) {
  if (is.null(filter_vals) || length(filter_vals) == 0L) return(NULL)
  filter_vals <- gsub("'", "''", filter_vals)
  if (exact) {
    placeholders <- paste0("'", tolower(trimws(filter_vals)), "'", collapse = ", ")
    sprintf("LOWER(%s) IN (%s)", col_name, placeholders)
  } else {
    clauses <- sprintf("LOWER(%s) LIKE '%%%s%%'", col_name, tolower(trimws(filter_vals)))
    paste0("(", paste(clauses, collapse = " OR "), ")")
  }
}

.query_db_for_menu_item <- function(con,
                                    target_items = NULL,
                                    priv_filter = NULL,
                                    duty_filter = NULL,
                                    role_id_filter = NULL,
                                    role_nm_filter = NULL,
                                    exact = TRUE) {
  # 1. Versuch: Direkte Abfrage auf LicensingSecurityObjectExplodedGraph
  tbl_check <- tryCatch({
    DBI::dbGetQuery(con, "SELECT TOP 1 * FROM LicensingSecurityObjectExplodedGraph")
    TRUE
  }, error = function(e) FALSE)

  if (tbl_check) {
    conds <- c(
      .build_sql_clause("SECURABLENAME", target_items, exact),
      .build_sql_clause("PRIVILEGEIDENTIFIER", priv_filter, exact),
      .build_sql_clause("DUTYIDENTIFIER", duty_filter, exact),
      .build_sql_clause("ROLEIDENTIFIER", role_id_filter, exact),
      .build_sql_clause("ROLENAME", role_nm_filter, exact)
    )
    conds <- conds[!vapply(conds, is.null, logical(1))]
    val_clause <- if (length(conds) > 0L) paste(conds, collapse = " AND ") else "1=1"

    sql <- paste0("
      SELECT
          SECURABLENAME         AS MENU_ITEM,
          CASE ACCESSLEVEL
              WHEN 1 THEN 'Read'
              WHEN 2 THEN 'Write'
              ELSE CAST(ACCESSLEVEL AS VARCHAR)
          END                   AS ACCESS_LEVEL,
          LICENSE               AS LICENSE,
          PRIVILEGEIDENTIFIER   AS PRIVILEGE_ID,
          PRIVILEGENAME         AS PRIVILEGE_NAME,
          DUTYIDENTIFIER        AS DUTY_ID,
          DUTYNAME              AS DUTY_NAME,
          ROLEIDENTIFIER        AS ROLE_ID,
          ROLENAME              AS ROLE_NAME,
          SUBROLEIDENTIFIER     AS SUBROLE_ID
      FROM LicensingSecurityObjectExplodedGraph
      WHERE ", val_clause, "
    ")

    res <- tryCatch(DBI::dbGetQuery(con, sql), error = function(e) NULL)
    if (!is.null(res) && nrow(res) > 0L) return(res)
  }

  # 2. Versuch: Fallback über UserSecGovRelatedObjects + Licensing-Tabellen
  secgov_check <- tryCatch({
    DBI::dbGetQuery(con, "SELECT TOP 1 * FROM UserSecGovRelatedObjects")
    TRUE
  }, error = function(e) FALSE)

  if (secgov_check) {
    conds_secgov <- c(
      .build_sql_clause("sec.RESOURCE_", target_items, exact),
      .build_sql_clause("sec.PRIVILEGEIDENTIFIER", priv_filter, exact),
      .build_sql_clause("sec.DUTYIDENTIFIER", duty_filter, exact),
      .build_sql_clause("sec.ROLEIDENTIFIER", role_id_filter, exact),
      .build_sql_clause("sec.ROLENAME", role_nm_filter, exact)
    )
    conds_secgov <- conds_secgov[!vapply(conds_secgov, is.null, logical(1))]
    val_clause_secgov <- if (length(conds_secgov) > 0L) paste(conds_secgov, collapse = " AND ") else "1=1"

    sql <- paste0("
      SELECT
          sec.RESOURCE_                 AS MENU_ITEM,
          CASE COALESCE(laep.ACCESSLEVEL, 1)
              WHEN 1 THEN 'Read'
              WHEN 2 THEN 'Write'
              ELSE CAST(laep.ACCESSLEVEL AS VARCHAR)
          END                           AS ACCESS_LEVEL,
          COALESCE(lsku.SKUNAME, 'None') AS LICENSE,
          sec.PRIVILEGEIDENTIFIER       AS PRIVILEGE_ID,
          sec.PRIVILEGENAME             AS PRIVILEGE_NAME,
          sec.DUTYIDENTIFIER            AS DUTY_ID,
          sec.DUTYNAME                  AS DUTY_NAME,
          sec.ROLEIDENTIFIER            AS ROLE_ID,
          sec.ROLENAME                  AS ROLE_NAME,
          CAST(NULL AS VARCHAR(255))    AS SUBROLE_ID
      FROM UserSecGovRelatedObjects sec
      LEFT JOIN LicensingEntitlementObjects obj
          ON LOWER(obj.AOTNAME) = LOWER(sec.RESOURCE_)
      LEFT JOIN LicensingAllEntitledPermissions laep
          ON laep.ENTITLEMENTOBJECT = obj.RECID
      LEFT JOIN LicensingAllSKUs lsku
          ON lsku.RECID = laep.SKURECID
      WHERE ", val_clause_secgov, "
    ")
    return(tryCatch(DBI::dbGetQuery(con, sql), error = function(e) NULL))
  }

  NULL
}

.filter_secgov_objects <- function(secgov,
                                   target_items = NULL,
                                   priv_filter = NULL,
                                   duty_filter = NULL,
                                   role_id_filter = NULL,
                                   role_nm_filter = NULL,
                                   exact = TRUE) {
  cols <- toupper(names(secgov))
  names(secgov) <- cols

  res_col <- if ("RESOURCE_" %in% cols) "RESOURCE_" else if ("SECURABLENAME" %in% cols) "SECURABLENAME" else NULL
  n_rows <- nrow(secgov)
  keep <- rep(TRUE, n_rows)

  .match_col <- function(col_name, filter_vals) {
    if (is.null(filter_vals) || length(filter_vals) == 0L) return(rep(TRUE, n_rows))
    if (!col_name %in% cols) return(rep(FALSE, n_rows))
    vals <- as.character(secgov[[col_name]])
    vals[is.na(vals)] <- ""
    if (exact) {
      tolower(trimws(vals)) %in% tolower(trimws(filter_vals))
    } else {
      pattern <- paste(filter_vals, collapse = "|")
      grepl(pattern, vals, ignore.case = TRUE)
    }
  }

  if (!is.null(target_items) && length(target_items) > 0L) {
    if (!is.null(res_col)) {
      keep <- keep & .match_col(res_col, target_items)
    } else {
      return(NULL)
    }
  }

  if (!is.null(priv_filter) && length(priv_filter) > 0L) {
    keep <- keep & .match_col("PRIVILEGEIDENTIFIER", priv_filter)
  }

  if (!is.null(duty_filter) && length(duty_filter) > 0L) {
    keep <- keep & .match_col("DUTYIDENTIFIER", duty_filter)
  }

  if (!is.null(role_id_filter) && length(role_id_filter) > 0L) {
    keep <- keep & .match_col("ROLEIDENTIFIER", role_id_filter)
  }

  if (!is.null(role_nm_filter) && length(role_nm_filter) > 0L) {
    keep <- keep & .match_col("ROLENAME", role_nm_filter)
  }

  matched <- secgov[keep, , drop = FALSE]
  if (nrow(matched) == 0L) return(NULL)

  sec_name <- if (!is.null(res_col)) as.character(matched[[res_col]]) else NA_character_
  priv_id  <- if ("PRIVILEGEIDENTIFIER" %in% cols) as.character(matched$PRIVILEGEIDENTIFIER) else NA_character_
  priv_nm  <- if ("PRIVILEGENAME" %in% cols) as.character(matched$PRIVILEGENAME) else priv_id
  duty_id  <- if ("DUTYIDENTIFIER" %in% cols) as.character(matched$DUTYIDENTIFIER) else NA_character_
  duty_nm  <- if ("DUTYNAME" %in% cols) as.character(matched$DUTYNAME) else duty_id
  role_id  <- if ("ROLEIDENTIFIER" %in% cols) as.character(matched$ROLEIDENTIFIER) else NA_character_
  role_nm  <- if ("ROLENAME" %in% cols) as.character(matched$ROLENAME) else role_id
  sub_id   <- if ("SUBROLEIDENTIFIER" %in% cols) as.character(matched$SUBROLEIDENTIFIER) else NA_character_

  data.frame(
    MENU_ITEM      = sec_name,
    ACCESS_LEVEL   = "Read/Write",
    LICENSE        = "Siehe Lizenzbericht",
    PRIVILEGE_ID   = priv_id,
    PRIVILEGE_NAME = priv_nm,
    DUTY_ID        = duty_id,
    DUTY_NAME      = duty_nm,
    ROLE_ID        = role_id,
    ROLE_NAME      = role_nm,
    SUBROLE_ID     = sub_id,
    stringsAsFactors = FALSE
  )
}

.read_graph_files_internal <- function(files) {
  cols_to_keep <- c("ROLEIDENTIFIER", "ROLENAME", "SUBROLEIDENTIFIER", "SUBROLENAME",
                    "DUTYIDENTIFIER", "DUTYNAME", "PRIVILEGEIDENTIFIER", "PRIVILEGENAME",
                    "SECURABLETYPE", "SECURABLENAME", "SECURABLECHILDNAME", "ACCESSLEVEL", "LICENSE")
  rows <- lapply(files, function(f) {
    tryCatch({
      df <- readxl::read_excel(f, col_types = "text")
      names(df) <- toupper(trimws(names(df)))
      present <- intersect(cols_to_keep, names(df))
      df[, present, drop = FALSE]
    }, error = function(e) NULL)
  })
  rows <- rows[!vapply(rows, is.null, logical(1))]
  if (length(rows) == 0L) return(data.frame())
  dplyr::bind_rows(rows)
}

.empty_menu_item_result <- function() {
  tibble::tibble(
    MENU_ITEM      = character(),
    ACCESS_LEVEL   = character(),
    LICENSE        = character(),
    PRIVILEGE_ID   = character(),
    PRIVILEGE_NAME = character(),
    DUTY_ID        = character(),
    DUTY_NAME      = character(),
    ROLE_ID        = character(),
    ROLE_NAME      = character(),
    SUBROLE_ID     = character()
  )
}

.print_menu_item_summary <- function(df,
                                     target_items = NULL,
                                     priv_filter = NULL,
                                     duty_filter = NULL,
                                     role_id_filter = NULL,
                                     role_nm_filter = NULL) {
  cat("\n===================================================================\n")
  cat("  SICHERHEITS- UND LIZENZANALYSE: SUCHE IN DER SECURITY-HIERARCHIE\n")
  cat("===================================================================\n")
  if (length(target_items) > 0L)   cat("• Menu Item(s):       ", paste(target_items, collapse = ", "), "\n")
  if (length(priv_filter) > 0L)    cat("• Privilege Filter:   ", paste(priv_filter, collapse = ", "), "\n")
  if (length(duty_filter) > 0L)    cat("• Duty Filter:        ", paste(duty_filter, collapse = ", "), "\n")
  if (length(role_id_filter) > 0L) cat("• Role ID Filter:     ", paste(role_id_filter, collapse = ", "), "\n")
  if (length(role_nm_filter) > 0L) cat("• Role Name Filter:   ", paste(role_nm_filter, collapse = ", "), "\n")
  cat("Gefundene Treffer-Zeilen:", nrow(df), "\n\n")

  # Nach Items gruppieren
  items <- unique(na.omit(df$MENU_ITEM))
  display_items <- head(items, 5)
  for (item in display_items) {
    sub_df <- df[df$MENU_ITEM == item, ]
    cat(sprintf("▶ MENU ITEM: %s\n", item))

    # Lizenzen je Access Level
    lics <- unique(paste0(sub_df$ACCESS_LEVEL, ": ", sub_df$LICENSE))
    cat("  • Ausgelöste Lizenz(en):", paste(lics, collapse = " | "), "\n")

    # Privileges
    privs <- unique(na.omit(sub_df$PRIVILEGE_NAME))
    cat("  • Enthalten in", length(privs), "Privileg(ien):", paste(head(privs, 3), collapse = ", "))
    if (length(privs) > 3) cat(" ... (+", length(privs) - 3, "weitere)")
    cat("\n")

    # Duties
    duties <- unique(na.omit(sub_df$DUTY_NAME))
    cat("  • Enthalten in", length(duties), "Aufgabe(n)/Duty:", paste(head(duties, 3), collapse = ", "))
    if (length(duties) > 3) cat(" ... (+", length(duties) - 3, "weitere)")
    cat("\n")

    # Roles
    roles <- unique(na.omit(sub_df$ROLE_NAME))
    cat("  • Enthalten in", length(roles), "Rolle(n):", paste(head(roles, 3), collapse = ", "))
    if (length(roles) > 3) cat(" ... (+", length(roles) - 3, "weitere)")
    cat("\n\n")
  }
  if (length(items) > 5) {
    cat(sprintf("... und %d weitere Menu Items.\n", length(items) - 5))
  }
  cat("===================================================================\n\n")
}
