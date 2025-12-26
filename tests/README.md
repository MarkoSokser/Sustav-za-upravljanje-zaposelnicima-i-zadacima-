# 🧪 Test Suite - Employee Management System

Kompletna test suite za testiranje PostgreSQL baze podataka.

##  Pregled Testova

Testovi su organizirani u **7 kategorija** koje pokrivaju sve aspekte baze:

| Test File | Kategorija | Broj Testova | Opis |
|-----------|-----------|--------------|------|
| `01_test_basic_setup.sql` | SETUP | 5 | Provjera baze, sheme, tablica i ključeva |
| `02_test_types.sql` | TYPES | 10 | ENUM, Domain i Composite tipovi |
| `03_test_tables.sql` | TABLES | 10 | Constrainti i relacijske veze |
| `04_test_functions.sql` | FUNCTIONS | 15 | Sve funkcije (validacija, RBAC, business logic) |
| `05_test_procedures.sql` | PROCEDURES | 10 | CRUD procedure |
| `06_test_triggers.sql` | TRIGGERS | 10 | Audit, validation i auto-update triggeri |
| `07_test_views_indexes.sql` | VIEWS/INDEXES | 10 | View-ovi i indeksi |

**Ukupno: 70 testova**

---

##  Pokretanje Testova

### Preduvjeti

1. PostgreSQL 15+ instaliran
2. Baza `employee_db` kreirana
3. Schema i podaci učitani:
   ```bash
   psql -U postgres -d employee_db -f database/01_schema.sql
   psql -U postgres -d employee_db -f database/02_seed_data.sql
   psql -U postgres -d employee_db -f database/03_functions_procedures.sql
   ```

### Pokretanje Svih Testova

```bash
# Iz root direktorija projekta
psql -U postgres -d employee_db -f tests/00_test_master.sql
```

### Pokretanje Pojedinačnih Testova

```bash
# Test 1: Basic Setup
psql -U postgres -d employee_db -f tests/01_test_basic_setup.sql

# Test 2: Types
psql -U postgres -d employee_db -f tests/02_test_types.sql

# Test 3: Tables
psql -U postgres -d employee_db -f tests/03_test_tables.sql

# Test 4: Functions
psql -U postgres -d employee_db -f tests/04_test_functions.sql

# Test 5: Procedures
psql -U postgres -d employee_db -f tests/05_test_procedures.sql

# Test 6: Triggers
psql -U postgres -d employee_db -f tests/06_test_triggers.sql

# Test 7: Views & Indexes
psql -U postgres -d employee_db -f tests/07_test_views_indexes.sql
```

---

##  Očekivani Rezultati

### Izvještaj nakon pokretanja

Nakon pokretanja master test skripte, dobit ćete:

1. **Category Summary**
   ```
   test_category | total_tests | passed | failed | skipped | success_rate
   --------------+-------------+--------+--------+---------+-------------
   SETUP         |      5      |   5    |   0    |    0    |   100.00
   TYPES         |     10      |  10    |   0    |    0    |   100.00
   TABLES        |     10      |  10    |   0    |    0    |   100.00
   FUNCTIONS     |     15      |  15    |   0    |    0    |   100.00
   PROCEDURES    |     10      |  10    |   0    |    0    |   100.00
   TRIGGERS      |     10      |  10    |   0    |    0    |   100.00
   VIEWS         |      5      |   5    |   0    |    0    |   100.00
   INDEXES       |      5      |   5    |   0    |    0    |   100.00
   ```

2. **Overall Summary**
   ```
   total_tests | passed | failed | skipped | success_rate
   ------------+--------+--------+---------+-------------
       70      |   70   |   0    |    0    |   100.00
   ```

3. **Failed Tests Details** (ako postoje)
   - Lista svih testova koji nisu prošli
   - Razlog neuspjeha
   - Vrijeme izvršenja

---

##  Što Se Testira?

### 1. Basic Setup (SETUP)
-  Postojanje sheme `employee_management`
-  Postojanje svih 8 tablica
-  Učitani početni podaci (users, roles, permissions)
-  Primarni ključevi na svim tablicama
-  Strani ključevi (10+ relacija)

### 2. Custom Types (TYPES)
-  ENUM `task_status` (NEW, IN_PROGRESS, COMPLETED, etc.)
-  ENUM `task_priority` (LOW, MEDIUM, HIGH, URGENT)
-  ENUM `audit_action` (INSERT, UPDATE, DELETE)
-  Domain `email_address` validacija
-  Domain `username_type` validacija
-  Composite `timestamp_metadata`
-  Composite `address_info`
-  Negativni testovi (nevaljani podaci)

### 3. Tables & Constraints (TABLES)
-  UNIQUE constraint (username, email)
-  CHECK constraint (self-manager, due_date)
-  CHECK constraint (completed_at logic)
-  Foreign key validacija
-  ON DELETE RESTRICT
-  ON DELETE SET NULL
-  ON DELETE CASCADE
-  NOT NULL constraints

### 4. Functions (FUNCTIONS)
-  `validate_email()` - validacija emaila
-  `generate_slug()` - generiranje slug-a
-  `check_password_strength()` - provjera lozinke
-  `user_has_permission()` - RBAC provjera
-  `get_user_permissions()` - dohvat permisija
-  `get_user_roles()` - dohvat uloga
-  `is_manager_of()` - hijerarhija managera
-  `get_team_members()` - članovi tima
-  `get_user_tasks()` - zadaci korisnika
-  `get_task_statistics()` - statistika

### 5. Procedures (PROCEDURES)
-  `create_user()` - kreiranje korisnika
-  `update_user()` - ažuriranje korisnika
-  `deactivate_user()` - deaktivacija
-  `create_task()` - kreiranje zadatka
-  `update_task_status()` - promjena statusa
-  `assign_task()` - dodjeljivanje zadatka
-  `assign_role()` - dodjeljivanje uloge
-  `revoke_role()` - uklanjanje uloge
-  Validacija duplikata
-  Business logic validacija

### 6. Triggers (TRIGGERS)
-  `audit_users_changes` - INSERT/UPDATE/DELETE
-  `audit_tasks_changes` - INSERT/UPDATE/DELETE
-  `audit_user_roles_changes` - INSERT/DELETE
-  `update_updated_at_column` - auto-update
-  `validate_manager_hierarchy` - self-reference
-  `validate_manager_hierarchy` - circular reference
-  JSONB audit log format
-  Automatsko postavljanje timestampova

### 7. Views & Indexes (VIEWS/INDEXES)
-  `v_users_with_roles` - struktura i podaci
-  `v_roles_with_permissions` - RBAC matrix
-  `v_tasks_details` - detalji zadataka
-  `v_user_statistics` - statistika korisnika
-  `v_manager_team` - tim managera
-  Indeksi za users tablicu (5 indeksa)
-  Indeksi za tasks tablicu (6 indeksa)
-  Indeksi za audit_log tablicu (4 indeksa)
-  Performance - index usage

---

##  Interpretacija Rezultata

###  PASS
- Test je prošao uspješno
- Funkcionalnost radi kako se očekuje

###  FAIL
- Test nije prošao
- Poruka greške objašnjava problem
- Provjerite `test_message` kolonu u rezultatima


##  Čišćenje nakon Testova

Testovi automatski čiste test podatke koje kreiraju. Međutim, ako želite potpuno resetirati bazu:

```sql
-- Resetiranje baze
DROP SCHEMA IF EXISTS employee_management CASCADE;

-- Ponovno kreiranje
\i database/01_schema.sql
\i database/02_seed_data.sql
\i database/03_functions_procedures.sql
```

---
