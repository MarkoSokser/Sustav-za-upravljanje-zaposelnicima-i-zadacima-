# Faza 5: Funkcije, Procedure i Triggeri

## Pregled

Faza 5 implementira aktivnu bazu podataka sa:
- **12 funkcija** za validaciju i dohvat podataka
- **11 procedura** za CRUD operacije
- **7 triggera** za automatizaciju
- **4 RULES pravila** za automatsku zastitu podataka
- **1 arhivska tablica** kreirana pomocu LIKE klauzule

### Nove znacajke
- **Tijek odobravanja zadataka** - PENDING_APPROVAL status
- **Provjera direktnih permisija** - user_permissions tablica
- **LIKE klauzula** - kreiranje arhivske tablice sa strukturom izvorne tablice
- **RULES pravila** - automatska zastita i arhivacija podataka

---

## 1. Pomocne Funkcije

### `validate_email(email_input TEXT) → BOOLEAN`
Validira format email adrese koristeci regex.

```sql
SELECT validate_email('test@example.com');  -- TRUE
SELECT validate_email('invalid-email');     -- FALSE
```

### `generate_slug(input_text TEXT) → TEXT`
Generira URL-friendly slug od teksta.

```sql
SELECT generate_slug('Moj Novi Zadatak!');  -- 'moj-novi-zadatak'
```

### `check_password_strength(password TEXT) → TABLE`
Provjerava jacinu lozinke prema sigurnosnim kriterijima.

```sql
SELECT * FROM check_password_strength('Weak');
-- is_valid: FALSE, message: 'Lozinka mora imati minimalno 8 znakova'

SELECT * FROM check_password_strength('Strong@Pass123');
-- is_valid: TRUE, message: 'Lozinka zadovoljava sve znakove'
```

**Kriteriji:**
- Minimalno 8 znakova
- Barem jedno veliko slovo
- Barem jedno malo slovo
- Barem jedan broj
- Barem jedan specijalni znak

---

## 2. RBAC Funkcije

### `user_has_permission(user_id, permission_code) → BOOLEAN`
Provjerava da li korisnik ima odredjenu permisiju.

**NOVO:** Ova funkcija sada provjerava:
1. Permisije kroz uloge (role_permissions)
2. Direktne permisije (user_permissions tablica)
3. Negacija permisija (is_granted = false)

```sql
-- Admin moze brisati zadatke?
SELECT user_has_permission(1, 'TASK_DELETE');  -- TRUE

-- Employee moze brisati zadatke?
SELECT user_has_permission(4, 'TASK_DELETE');  -- FALSE

-- Employee s direktno dodijeljenom permisijom
SELECT user_has_permission(4, 'AUDIT_READ_ALL');  -- TRUE ako je direktno dodijeljena
```

### `get_user_permissions(user_id) → TABLE`
Vraca sve permisije korisnika kroz njegove uloge I direktne dodjele.

```sql
SELECT * FROM get_user_permissions(1);
-- Vraca sve permisije za ADMIN-a (ukljucuje direktne)
```

### `get_user_direct_permissions(user_id) → TABLE`
**NOVA FUNKCIJA** - Vraca samo direktno dodijeljene permisije korisnika.

```sql
SELECT * FROM get_user_direct_permissions(4);
-- permission_code | is_granted | granted_at
-- AUDIT_READ_ALL  | true       | 2025-01-15
```

### `get_user_roles(user_id) → TABLE`
Vraca sve uloge dodijeljene korisniku.

```sql
SELECT * FROM get_user_roles(2);
-- role_id | role_name | role_description | assigned_at
```

### `is_manager_of(manager_id, employee_id) → BOOLEAN`
Provjerava da li je prvi korisnik manager drugog.

```sql
SELECT is_manager_of(2, 4);  -- TRUE (Ivan je manager Marka)
```

### `get_team_members(manager_id) → TABLE`
Vraca sve clanove tima za odredjenog managera.

```sql
SELECT * FROM get_team_members(2);
-- Vraca Marka, Petru i Luku
```

---

## 3. Funkcije za Zadatke

### `get_user_tasks(user_id, status?, include_created?) → TABLE`
Vraca zadatke dodijeljene korisniku sa opcijama filtriranja.

```sql
-- Svi zadaci korisnika
SELECT * FROM get_user_tasks(4);

-- Samo zadaci IN_PROGRESS
SELECT * FROM get_user_tasks(4, 'IN_PROGRESS');

-- Ukljuci i zadatke koje je kreirao
SELECT * FROM get_user_tasks(2, NULL, TRUE);
```

### `get_task_statistics(user_id) → TABLE`
Vraca statistiku zadataka za korisnika.

```sql
SELECT * FROM get_task_statistics(4);
-- total_tasks | completed_tasks | in_progress_tasks | overdue_tasks | completion_rate
--     1       |       0         |         1         |       0       |     0.00
```

---

## 4. CRUD Procedure

### `create_user(...)`
Kreira novog korisnika i dodjeljuje mu pocetnu ulogu.

```sql
CALL create_user(
    'novi_korisnik',           
    'novi@example.com',        
    '$2b$12$hash...',         
    'Novo',                   
    'Prezime',                 
    2,                         
    'EMPLOYEE',               
    1,                         
    NULL                       
);
```

### `update_user(...)`
Azurira podatke korisnika.

```sql
CALL update_user(
    4,                         
    'NovoIme',              
    NULL,                      
    NULL,                      
    NULL,                     
    NULL,                     
    1                         
);
```

### `deactivate_user(user_id, deactivated_by)`
Deaktivira korisnika i ponistava njegove nezavrsene zadatke.

```sql
CALL deactivate_user(9, 1);
```

### `create_task(...)`
Kreira novi zadatak.

```sql
CALL create_task(
    'Novi zadatak',           
    'Opis zadatka',            
    'HIGH',                    
    '2025-12-31',             
    2,                        
    4,                         
    NULL                       
);
```

### `update_task_status(task_id, new_status, updated_by)`
Azurira status zadatka sa validacijom permisija i tijeka odobravanja.

```sql
CALL update_task_status(1, 'PENDING_APPROVAL', 4);  -- Zaposlenik predlaze zavrsetak
CALL update_task_status(1, 'COMPLETED', 2);         -- Manager odobrava
```

**Pravila:**
- Korisnik mora biti assignee, kreator, ili imati TASK_UPDATE_ANY permisiju
- Zavrseni zadaci se ne mogu ponovo otvoriti
- Otkazani zadaci se ne mogu mijenjati

**Tijek odobravanja:**
```
TODO → IN_PROGRESS → PENDING_APPROVAL → COMPLETED
                  ↘ CANCELLED
```
- **Zaposlenik**: moze postaviti PENDING_APPROVAL (predlaze zavrsetak)
- **Manager/Admin**: moze postaviti COMPLETED (odobrava zavrsetak)

### `assign_task(task_id, assignee_id, assigned_by)`
Dodjeljuje zadatak korisniku.

```sql
CALL assign_task(1, 5, 2);
```

### `assign_role(user_id, role_name, assigned_by)`
Dodjeljuje ulogu korisniku.

```sql
CALL assign_role(4, 'MANAGER', 1);
```

### `revoke_role(user_id, role_name, revoked_by)`
Uklanja ulogu od korisnika.

```sql
CALL revoke_role(4, 'MANAGER', 1);
```

**Pravila:**
- Korisnik mora imati barem jednu ulogu

---

## 5. Triggeri

### Audit Triggeri

| Trigger | Tabela | Dogadjaj | Opis |
|---------|--------|----------|------|
| `trg_audit_users` | users | INSERT, UPDATE, DELETE | Loguje sve promjene korisnika |
| `trg_audit_tasks` | tasks | INSERT, UPDATE, DELETE | Loguje sve promjene zadataka |
| `trg_audit_user_roles` | user_roles | INSERT, DELETE | Loguje dodjelu/uklanjanje uloga |

**Napomena:** Audit triggeri koriste `changed_by = NULL` kako bi izbjegli FK constraint probleme prilikom brisanja korisnika. Informacija o tome tko je napravio promjenu može se pohraniti u `new_value`/`old_value` JSONB poljima.

**Format audit zapisa:**
```json
{
  "old_value": {"username": "old_name", "email": "old@email.com"},
  "new_value": {"username": "new_name", "email": "new@email.com"}
}
```

### Auto-Update Triggeri

| Trigger | Tabela | Opis |
|---------|--------|------|
| `trg_users_updated_at` | users | Automatski postavlja updated_at |
| `trg_roles_updated_at` | roles | Automatski postavlja updated_at |
| `trg_tasks_updated_at` | tasks | Automatski postavlja updated_at |

### Validacijski Triggeri

| Trigger | Tabela | Opis |
|---------|--------|------|
| `trg_validate_manager_hierarchy` | users | Sprecava cirkularne reference u hijerarhiji |

**Pravila:**
- Korisnik ne moze biti sam sebi manager
- Maksimalna dubina hijerarhije: 10 nivoa
- Cirkularne reference nisu dozvoljene

---

## 6. Maintenance Procedure

### `cleanup_old_audit_logs(days_to_keep)`
Brise audit zapise starije od zadanog broja dana.

```sql
CALL cleanup_old_audit_logs(365);  -- Zadrzava zadnjih godinu dana
```

### `cleanup_old_login_events(days_to_keep)`
Brise login evente starije od zadanog broja dana.

```sql
CALL cleanup_old_login_events(90);  -- Zadrzava zadnjih 90 dana
```

---

## 7. Sigurnosne Funkcije

### `log_login_attempt(...)`
Loguje pokusaj prijave u sustav.

```sql
SELECT log_login_attempt(
    'admin',                  
    '192.168.1.1'::INET,      
    'Mozilla/5.0...',          
    TRUE,                     
    NULL                       
);
```

**Moguce vrijednosti failure_reason:**
- `INVALID_CREDENTIALS`
- `ACCOUNT_INACTIVE`
- `ACCOUNT_LOCKED`

---

## 8. LIKE Klauzula - Arhivska Tablica

### Sto je LIKE klauzula?

LIKE klauzula u PostgreSQL-u omogucuje kreiranje nove tablice koja nasljedjuje strukturu postojece tablice. To je korisno za:
- Kreiranje arhivskih tablica
- Kreiranje backup tablica
- Kreiranje tablica za testiranje

### `tasks_archive` - Arhivska tablica za zadatke

Tablica `tasks_archive` kreirana je pomocu LIKE klauzule i sluzi za pohranu zavrsenih/otkazanih zadataka starijih od 180 dana.

```sql
CREATE TABLE tasks_archive (
    LIKE tasks INCLUDING DEFAULTS INCLUDING COMMENTS,
    archived_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    archived_by INTEGER,
    archive_reason TEXT
);

ALTER TABLE tasks_archive ADD PRIMARY KEY (task_id);
```

**Sto LIKE klauzula kopira:**
- Nazive i tipove stupaca
- DEFAULT vrijednosti (INCLUDING DEFAULTS)
- Komentare (INCLUDING COMMENTS)

**Sto LIKE klauzula NE kopira:**
- PRIMARY KEY (mora se rucno dodati)
- FOREIGN KEY ogranicenja
- SERIAL/IDENTITY sekvence
- Indekse (osim uz INCLUDING INDEXES)

### Struktura tasks_archive tablice

| Stupac | Tip | Opis |
|--------|-----|------|
| task_id | INTEGER | ID zadatka (PK) |
| title | VARCHAR(200) | Naziv zadatka |
| description | TEXT | Opis zadatka |
| status | task_status | Status (COMPLETED/CANCELLED) |
| priority | task_priority | Prioritet |
| due_date | DATE | Rok zavretka |
| created_by | INTEGER | Kreator |
| assigned_to | INTEGER | Dodijeljen korisniku |
| created_at | TIMESTAMP | Datum kreiranja |
| updated_at | TIMESTAMP | Datum azuriranja |
| completed_at | TIMESTAMP | Datum zavrsetka |
| **archived_at** | TIMESTAMP | Datum arhiviranja |
| **archived_by** | INTEGER | Tko je arhivirao |
| **archive_reason** | TEXT | Razlog arhiviranja |

---

## 9. RULES - Pravila za Automatsku Zastitu

### Sto su RULES?

PostgreSQL RULES su mehanizam za transformaciju upita. Kada se izvrsi odredjeni upit (INSERT, UPDATE, DELETE, SELECT), RULE moze:
- **DO INSTEAD** - Zamijeniti originalni upit drugim upitom
- **DO ALSO** - Izvrsiti dodatni upit uz originalni
- **DO INSTEAD NOTHING** - Potpuno ignorirati originalni upit

### Razlika izmedju RULES i TRIGGERS

| Karakteristika | RULES | TRIGGERS |
|----------------|-------|----------|
| Razina | Upit (query rewriting) | Red (row-level) |
| Izvrsavanje | Prije izvrsenja upita | Prije/Poslije operacije |
| Performanse | Brze za bulk operacije | Bolje za pojedinacne redove |
| Fleksibilnost | Ogranicena | Veca (PL/pgSQL) |
| Vidljivost | Upit se transformira | Upit ostaje isti |

### RULE 1: prevent_system_role_delete

**Svrha:** Sprijecava brisanje sistemskih uloga (ADMIN, MANAGER, EMPLOYEE).

```sql
CREATE RULE prevent_system_role_delete AS
    ON DELETE TO roles
    WHERE OLD.is_system = TRUE
    DO INSTEAD NOTHING;
```

**Primjer:**
```sql
-- Pokusaj brisanja ADMIN uloge - IGNORIRA SE
DELETE FROM roles WHERE name = 'ADMIN';
-- Rezultat: 0 redova obrisano, uloga ostaje netaknuta

-- Brisanje custom uloge - USPJESNO
DELETE FROM roles WHERE name = 'CUSTOM_ROLE' AND is_system = FALSE;
-- Rezultat: Uloga je obrisana
```

### RULE 2: log_user_delete_attempt

**Svrha:** Automatski logira svaki pokusaj brisanja korisnika u audit_log tablicu.

```sql
CREATE RULE log_user_delete_attempt AS
    ON DELETE TO users
    DO ALSO (
        INSERT INTO audit_log (entity_name, entity_id, action, old_value, new_value)
        VALUES (
            'users', 
            OLD.user_id, 
            'DELETE',
            jsonb_build_object(
                'username', OLD.username,
                'email', OLD.email,
                'first_name', OLD.first_name,
                'last_name', OLD.last_name,
                'deleted_at', CURRENT_TIMESTAMP
            ),
            NULL
        )
    );
```

**Primjer:**
```sql
-- Brisanje korisnika automatski kreira audit zapis
DELETE FROM users WHERE user_id = 10;

-- Provjera audit loga
SELECT * FROM audit_log WHERE entity_name = 'users' AND action = 'DELETE';
-- old_value: {"username": "korisnik", "email": "korisnik@example.com", ...}
```

### RULE 3: auto_archive_old_completed

**Svrha:** Automatski arhivira zavrsene/otkazane zadatke starije od 180 dana.

```sql
CREATE RULE auto_archive_old_completed AS
    ON UPDATE TO tasks
    WHERE NEW.status IN ('COMPLETED', 'CANCELLED') 
    AND NEW.updated_at < CURRENT_TIMESTAMP - INTERVAL '180 days'
    DO ALSO (
        INSERT INTO tasks_archive (...)
        SELECT ... 
        WHERE NOT EXISTS (SELECT 1 FROM tasks_archive WHERE task_id = NEW.task_id)
    );
```

**Kada se aktivira:**
- Kada se azurira zadatak koji je COMPLETED ili CANCELLED
- I taj zadatak ima updated_at stariji od 180 dana
- I zadatak vec nije u arhivi

**Primjer:**
```sql
-- Azuriranje starog zavrsenog zadatka triggeruje arhivaciju
UPDATE tasks 
SET status = 'COMPLETED' 
WHERE task_id = 100 AND updated_at < CURRENT_TIMESTAMP - INTERVAL '181 days';

-- Zadatak je sada u tasks_archive tablici
SELECT * FROM tasks_archive WHERE task_id = 100;
```

### RULE 4: prevent_completed_task_edit

**Svrha:** Sprijecava izmjenu zavrsenih ili otkazanih zadataka (osim promjene statusa).

```sql
CREATE RULE prevent_completed_task_edit AS
    ON UPDATE TO tasks
    WHERE OLD.status IN ('COMPLETED', 'CANCELLED')
    AND (
        NEW.title != OLD.title OR
        NEW.description IS DISTINCT FROM OLD.description OR
        NEW.priority != OLD.priority OR
        NEW.due_date IS DISTINCT FROM OLD.due_date OR
        NEW.created_by != OLD.created_by OR
        NEW.assigned_to IS DISTINCT FROM OLD.assigned_to
    )
    DO INSTEAD NOTHING;
```

**Sto se NE moze mijenjati na zavrsenom zadatku:**
- title (naslov)
- description (opis)
- priority (prioritet)
- due_date (rok)
- created_by (kreator)
- assigned_to (dodijeljen)

**Sto se MOZE mijenjati:**
- status (npr. vratiti zadatak na doradu)

**Primjer:**
```sql
-- Pokusaj izmjene naslova zavrsenog zadatka - IGNORIRA SE
UPDATE tasks SET title = 'Novi naslov' WHERE task_id = 5 AND status = 'COMPLETED';
-- Rezultat: 0 redova azurirano

-- Promjena statusa - USPJESNO
UPDATE tasks SET status = 'IN_PROGRESS' WHERE task_id = 5;
-- Rezultat: Status promijenjen (ako je dozvoljeno workflow-om)
```

---

## 10. Pregled svih RULES

| RULE | Tablica | Dogadjaj | Akcija | Opis |
|------|---------|----------|--------|------|
| `prevent_system_role_delete` | roles | DELETE | DO INSTEAD NOTHING | Blokira brisanje sistemskih uloga |
| `log_user_delete_attempt` | users | DELETE | DO ALSO | Logira brisanje u audit_log |
| `auto_archive_old_completed` | tasks | UPDATE | DO ALSO | Arhivira stare zavrsene zadatke |
| `prevent_completed_task_edit` | tasks | UPDATE | DO INSTEAD NOTHING | Blokira izmjenu zavrsenih zadataka |

---

## 11. SQL Skripta za Napredne Funkcije

Sve napredne funkcije nalaze se u datoteci `database/04_advanced_features.sql`.

### Redoslijed izvrsavanja

```bash
# 1. Prvo izvrsi osnovne skripte
psql -U postgres -d employee_db -f database/01_schema.sql
psql -U postgres -d employee_db -f database/02_seed_data.sql
psql -U postgres -d employee_db -f database/03_functions_procedures.sql

# 2. Zatim napredne funkcije
psql -U postgres -d employee_db -f database/04_advanced_features.sql
```

### Testiranje

```bash
# Pokreni testove za napredne funkcije
psql -U postgres -d employee_db -f tests/08_test_advanced_features.sql
```

**Ocekivani rezultati testova:**
```
TEST 1: tasks_archive tablica kreirana pomocu LIKE: OK
TEST 2: Zastita sistemskih uloga od brisanja: OK
TEST 3: Automatski audit log pri brisanju korisnika: OK
TEST 4: Automatska arhivacija starih zavrsenih zadataka: OK
TEST 5: Zastita zavrsenih zadataka od izmjena: OK
TEST 6: Provjera da su svi RULES kreirani: OK (svi 4 RULES kreirani)
```

---


