# FAZA 4 – Logički i objektno-relacijski model (PostgreSQL)
## Interni sustav za upravljanje zaposlenicima i zadacima

---

## 4.1 Cilj faze

Cilj ove faze je **implementirati logički model baze podataka** koristeći napredne objektno-relacijske značajke PostgreSQL-a:

- ENUM tipovi za status i prioritet
- Composite tipovi za grupiranje atributa
- Domene za validaciju podataka
- Kompleksna ograničenja integriteta
- Indeksi za optimizaciju upita
- Pogledi (Views) za česte upite

---

## 4.2 Struktura SQL skripti

| Skripta | Opis |
|---------|------|
| `01_schema.sql` | Kreiranje sheme, tipova, tablica, indeksa i pogleda |
| `02_seed_data.sql` | Početni podaci (permissions, roles, testni korisnici) |

### Redoslijed izvršavanja

```bash
psql -U postgres -d employee_db -f 01_schema.sql
psql -U postgres -d employee_db -f 02_seed_data.sql
```

---

## 4.3 Objektno-relacijske značajke

### 4.3.1 ENUM tipovi

ENUM tipovi osiguravaju da atribut može imati samo unaprijed definirane vrijednosti.

```sql
-- Status zadatka
CREATE TYPE task_status AS ENUM (
    'NEW',           
    'IN_PROGRESS',   
    'ON_HOLD',       
    'COMPLETED',     
    'CANCELLED'      
);

-- Prioritet zadatka
CREATE TYPE task_priority AS ENUM (
    'LOW',           
    'MEDIUM',        
    'HIGH',         
    'URGENT'         
);

-- Vrsta audit akcije
CREATE TYPE audit_action AS ENUM (
    'INSERT',        
    'UPDATE',       
    'DELETE'         
);
```

**Prednosti ENUM tipova:**
- Validacija na razini baze podataka
- Manji prostor pohrane od VARCHAR
- Jasna dokumentacija dopuštenih vrijednosti
- Type-safe usporedbe

---

### 4.3.2 Composite tipovi

Composite tipovi grupiraju povezane atribute u jednu strukturu.

```sql
-- Tip za meta-podatke o vremenu
CREATE TYPE timestamp_metadata AS (
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Tip za adresu 
CREATE TYPE address_info AS (
    street VARCHAR(200),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100)
);
```

**Primjena:** Iako u ovom projektu koristimo zasebne stupce za `created_at` i `updated_at`, composite tipovi demonstriraju mogućnost PostgreSQL-a za objektno-orijentirano modeliranje.

---

### 4.3.3 Domene

Domene su korisnički definirani tipovi s ograničenjima.

```sql
-- Domena za email adresu
CREATE DOMAIN email_address AS VARCHAR(100)
    CHECK (VALUE ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- Domena za korisničko ime
CREATE DOMAIN username_type AS VARCHAR(50)
    CHECK (VALUE ~* '^[a-zA-Z0-9_]{3,50}$');
```

**Prednosti domena:**
- Centralizirana validacija
- Ponovna upotreba u više tablica
- Jednostavno održavanje pravila

---

## 4.4 Tablice i ograničenja

### 4.4.1 Pregled tablica

| Tablica | Tip | Broj stupaca | Opis |
|---------|-----|--------------|------|
| `users` | Glavni | 10 | Korisnici sustava |
| `roles` | Glavni | 6 | Uloge (ADMIN, MANAGER, EMPLOYEE) |
| `permissions` | Glavni | 6 | Prava pristupa |
| `tasks` | Glavni | 11 | Zadaci |
| `user_roles` | Povezni | 5 | Veza korisnik-uloga (M:N) |
| `role_permissions` | Povezni | 4 | Veza uloga-pravo (M:N) |
| `login_events` | Audit | 8 | Evidencija prijava |
| `audit_log` | Audit | 9 | Evidencija promjena |

---

### 4.4.2 Ograničenja integriteta

#### Primarni ključevi
Sve tablice koriste `SERIAL` tip za automatsko generiranje ID-a.

```sql
user_id SERIAL PRIMARY KEY
```

#### Strani ključevi s ON DELETE akcijama

| Tablica | FK | Referencira | ON DELETE |
|---------|-----|-------------|-----------|
| users | manager_id | users(user_id) | SET NULL |
| tasks | created_by | users(user_id) | RESTRICT |
| tasks | assigned_to | users(user_id) | SET NULL |
| user_roles | user_id | users(user_id) | CASCADE |
| user_roles | role_id | roles(role_id) | RESTRICT |
| login_events | user_id | users(user_id) | SET NULL |
| audit_log | changed_by | users(user_id) | SET NULL |

#### CHECK ograničenja

```sql
-- Korisnik ne može biti sam sebi manager
CONSTRAINT chk_users_manager_not_self CHECK (manager_id != user_id)

-- Due date mora biti >= created_at
CONSTRAINT chk_tasks_due_date CHECK (due_date IS NULL OR due_date >= DATE(created_at))

-- Completed_at mora postojati samo za COMPLETED status
CONSTRAINT chk_tasks_completed_at CHECK (
    (status != 'COMPLETED' AND completed_at IS NULL) OR
    (status = 'COMPLETED' AND completed_at IS NOT NULL)
)

-- Failure_reason samo za neuspješne prijave
CONSTRAINT chk_login_events_failure CHECK (
    (success = TRUE AND failure_reason IS NULL) OR
    (success = FALSE)
)
```

#### UNIQUE ograničenja

```sql
CONSTRAINT uk_users_username UNIQUE (username)
CONSTRAINT uk_users_email UNIQUE (email)
CONSTRAINT uk_roles_name UNIQUE (name)
CONSTRAINT uk_permissions_code UNIQUE (code)
CONSTRAINT uk_user_roles UNIQUE (user_id, role_id)
CONSTRAINT uk_role_permissions UNIQUE (role_id, permission_id)
```

---

## 4.5 Indeksi

### 4.5.1 Pregled svih indeksa

| Tablica | Indeks | Stupci | Tip |
|---------|--------|--------|-----|
| users | idx_users_username | username | B-tree |
| users | idx_users_email | email | B-tree |
| users | idx_users_manager | manager_id | B-tree (parcijalni) |
| users | idx_users_active | is_active | B-tree |
| users | idx_users_full_name | last_name, first_name | B-tree |
| tasks | idx_tasks_status | status | B-tree |
| tasks | idx_tasks_priority | priority | B-tree |
| tasks | idx_tasks_assigned_to | assigned_to | B-tree (parcijalni) |
| tasks | idx_tasks_created_by | created_by | B-tree |
| tasks | idx_tasks_due_date | due_date | B-tree (parcijalni) |
| tasks | idx_tasks_active | status | B-tree (parcijalni) |
| login_events | idx_login_events_user | user_id | B-tree (parcijalni) |
| login_events | idx_login_events_time | login_time DESC | B-tree |
| audit_log | idx_audit_log_entity | entity_name, entity_id | B-tree |
| audit_log | idx_audit_log_time | changed_at DESC | B-tree |

### 4.5.2 Parcijalni indeksi

Parcijalni indeksi indeksiraju samo dio podataka, što štedi prostor i ubrzava upite:

```sql
-- Indeks samo za aktivne zadatke
CREATE INDEX idx_tasks_active ON tasks(status) 
WHERE status NOT IN ('COMPLETED', 'CANCELLED');

-- Indeks samo za postojeće manager_id
CREATE INDEX idx_users_manager ON users(manager_id) 
WHERE manager_id IS NOT NULL;
```

---

## 4.6 Pogledi (Views)

### 4.6.1 v_users_with_roles

Prikazuje korisnike s njihovim ulogama i managerom.

```sql
SELECT * FROM employee_management.v_users_with_roles;
```

| Stupac | Opis |
|--------|------|
| user_id | ID korisnika |
| username | Korisničko ime |
| email | E-mail |
| first_name, last_name | Ime i prezime |
| is_active | Status aktivnosti |
| manager_username | Username managera |
| manager_full_name | Puno ime managera |
| roles | Array uloga (npr. {ADMIN}) |

---

### 4.6.2 v_roles_with_permissions

Prikazuje uloge s dodijeljenim pravima.

```sql
SELECT * FROM employee_management.v_roles_with_permissions;
```

| Stupac | Opis |
|--------|------|
| role_id | ID uloge |
| role_name | Naziv uloge |
| role_description | Opis uloge |
| is_system | Je li sistemska uloga |
| permissions | Array kodova prava |
| user_count | Broj korisnika s tom ulogom |

---

### 4.6.3 v_tasks_details

Detaljni pregled zadataka.

```sql
SELECT * FROM employee_management.v_tasks_details;
```

| Stupac | Opis |
|--------|------|
| task_id | ID zadatka |
| title, description | Naziv i opis |
| status, priority | Status i prioritet |
| due_date | Rok završetka |
| creator_name | Tko je kreirao |
| assignee_name | Kome je dodijeljen |
| due_status | OVERDUE, DUE_TODAY, DUE_SOON, ON_TRACK |

---

### 4.6.4 v_user_statistics

Statistika aktivnosti korisnika.

```sql
SELECT * FROM employee_management.v_user_statistics;
```

| Stupac | Opis |
|--------|------|
| user_id | ID korisnika |
| full_name | Puno ime |
| tasks_created | Broj kreiranih zadataka |
| tasks_assigned | Broj dodijeljenih zadataka |
| tasks_completed | Broj završenih zadataka |
| tasks_active | Broj aktivnih zadataka |
| successful_logins | Broj uspješnih prijava |
| last_login | Vrijeme zadnje prijave |

---

### 4.6.5 v_manager_team

Pregled tima za svakog managera.

```sql
SELECT * FROM employee_management.v_manager_team 
WHERE manager_username = 'ivan_manager';
```

| Stupac | Opis |
|--------|------|
| manager_id | ID managera |
| manager_name | Ime managera |
| employee_id | ID zaposlenika |
| employee_name | Ime zaposlenika |
| employee_roles | Uloge zaposlenika |

---

## 4.7 Početni podaci

### 4.7.1 Prava pristupa (24 prava)

| Kategorija | Broj prava | Primjeri |
|------------|-----------|----------|
| USER | 7 | USER_CREATE, USER_READ_ALL, USER_UPDATE_SELF |
| ROLE | 6 | ROLE_CREATE, ROLE_ASSIGN, PERMISSION_MANAGE |
| TASK | 8 | TASK_CREATE, TASK_ASSIGN, TASK_READ_TEAM |
| AUDIT | 3 | AUDIT_READ_ALL, LOGIN_EVENTS_READ_SELF |

### 4.7.2 Uloge (3 sistemske)

| Uloga | Broj prava | Opis |
|-------|-----------|------|
| ADMIN | 24 | Sva prava |
| MANAGER | 12 | Upravljanje timom i zadacima |
| EMPLOYEE | 5 | Vlastiti podaci i zadaci |

### 4.7.3 Testni korisnici (9 korisnika)

| Username | Uloga | Manager | Tim |
|----------|-------|---------|-----|
| admin | ADMIN | - | - |
| ivan_manager | MANAGER | - | Razvoj |
| ana_manager | MANAGER | - | Dizajn |
| marko_dev | EMPLOYEE | ivan_manager | Razvoj |
| petra_dev | EMPLOYEE | ivan_manager | Razvoj |
| luka_dev | EMPLOYEE | ivan_manager | Razvoj |
| maja_design | EMPLOYEE | ana_manager | Dizajn |
| tomislav_design | EMPLOYEE | ana_manager | Dizajn |
| inactive_user | EMPLOYEE (deaktiviran) | - | - |

**Testna lozinka za sve korisnike:** `Password123!`

---

## 4.8 Instalacija i testiranje

### Kreiranje baze

```bash
# Kreiranje baze podataka
createdb -U postgres employee_db

# Pokretanje skripti
psql -U postgres -d employee_db -f database/01_schema.sql
psql -U postgres -d employee_db -f database/02_seed_data.sql
```

### Testni upiti

```sql
-- Postavi shemu
SET search_path TO employee_management;

-- Provjeri korisnike s ulogama
SELECT * FROM v_users_with_roles;

-- Provjeri RBAC matricu
SELECT * FROM v_roles_with_permissions;

-- Provjeri aktivne zadatke
SELECT * FROM v_tasks_details WHERE status NOT IN ('COMPLETED', 'CANCELLED');

-- Provjeri tim managera
SELECT * FROM v_manager_team WHERE manager_username = 'ivan_manager';

-- Provjeri statistiku korisnika
SELECT * FROM v_user_statistics;
```

