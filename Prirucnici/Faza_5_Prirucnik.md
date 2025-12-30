# Faza 5: Funkcije, Procedure i Triggeri

## Pregled

Faza 5 implementira aktivnu bazu podataka sa:
- **12 funkcija** za validaciju i dohvat podataka
- **11 procedura** za CRUD operacije
- **7 triggera** za automatizaciju

### Nove značajke
- **Tijek odobravanja zadataka** - PENDING_APPROVAL status
- **Provjera direktnih permisija** - user_permissions tablica

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
    'novi_korisnik',           -- username
    'novi@example.com',        -- email
    '$2b$12$hash...',         -- password_hash
    'Novo',                    -- first_name
    'Prezime',                 -- last_name
    2,                         -- manager_id
    'EMPLOYEE',                -- role_name
    1,                         -- created_by
    NULL                       -- OUT: p_new_user_id
);
```

### `update_user(...)`
Azurira podatke korisnika.

```sql
CALL update_user(
    4,                         -- user_id
    'NovoIme',                -- first_name
    NULL,                      -- last_name (bez promjene)
    NULL,                      -- email (bez promjene)
    NULL,                      -- manager_id (bez promjene)
    NULL,                      -- is_active (bez promjene)
    1                          -- updated_by
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
    'Novi zadatak',            -- title
    'Opis zadatka',            -- description
    'HIGH',                    -- priority
    '2025-12-31',              -- due_date
    2,                         -- created_by
    4,                         -- assigned_to
    NULL                       -- OUT: p_new_task_id
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
    'admin',                   -- username
    '192.168.1.1'::INET,       -- ip_address
    'Mozilla/5.0...',          -- user_agent
    TRUE,                      -- success
    NULL                       -- failure_reason
);
```

**Moguce vrijednosti failure_reason:**
- `INVALID_CREDENTIALS`
- `ACCOUNT_INACTIVE`
- `ACCOUNT_LOCKED`

---

## Testiranje

```sql
-- Postavi search_path
SET search_path TO employee_management;

-- Test RBAC
SELECT user_has_permission(1, 'TASK_DELETE');  -- TRUE (admin)
SELECT user_has_permission(4, 'TASK_DELETE');  -- FALSE (employee)

-- Test statistike
SELECT * FROM get_task_statistics(4);

-- Test tima
SELECT * FROM get_team_members(2);

-- Test audit loga
UPDATE users SET first_name = 'Test' WHERE user_id = 1;
SELECT * FROM audit_log WHERE entity_name = 'users' ORDER BY audit_log_id DESC LIMIT 1;
```
