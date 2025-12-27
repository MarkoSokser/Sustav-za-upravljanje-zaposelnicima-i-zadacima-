# Interni sustav za upravljanje zaposlenicima i zadacima

## TBP Projekt - Web aplikacija za upravljanje korisničkim računima, ulogama i pravima pristupa

### Opis projekta

Ovaj projekt demonstrira primjenu **poopćenih i objektno-relacijskih baza podataka** (PostgreSQL) kroz implementaciju internog sustava za upravljanje zaposlenicima i zadacima s **RBAC modelom** (Role-Based Access Control).

### Tehnologije

- **Baza podataka**: PostgreSQL 15+
- **Backend**: Python FastAPI
- **Autentikacija**: JWT tokeni, bcrypt
- **RBAC**: Role-Based Access Control

---

## Brzi početak

### 1. Inicijalizacija baze podataka

```sql
-- Pokreni SQL skripte redom:
\i database/01_schema.sql
\i database/02_seed_data.sql
\i database/03_functions_procedures.sql
```

### 2. Pokretanje backend-a

```bash
cd backend
python -m venv venv
venv\Scripts\activate  # Windows
pip install -r requirements.txt
copy .env.example .env  # Konfiguriraj bazu
uvicorn app.main:app --reload
```

### 3. API Dokumentacija

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

---

## Struktura projekta

```
TBP_projekt/
├── database/
│   ├── 01_schema.sql           # Shema baze (tablice, tipovi, indeksi, pogledi)
│   ├── 02_seed_data.sql        # Početni podaci
│   └── 03_functions_procedures.sql  # Funkcije, procedure, triggeri
├── backend/
│   ├── app/
│   │   ├── main.py             # FastAPI aplikacija
│   │   ├── config.py           # Konfiguracija
│   │   ├── database.py         # DB konekcija
│   │   ├── auth.py             # JWT autentikacija
│   │   ├── schemas.py          # Pydantic modeli
│   │   └── routers/            # API rute
│   └── requirements.txt
├── tests/                       # SQL testovi za bazu
├── Prirucnici/                  # Dokumentacija po fazama
└── README.md
```

---

## PostgreSQL mogućnosti

Projekt demonstrira napredne PostgreSQL mogućnosti:

### ENUM tipovi
```sql
CREATE TYPE task_status AS ENUM ('NEW', 'IN_PROGRESS', 'ON_HOLD', 'COMPLETED', 'CANCELLED');
CREATE TYPE task_priority AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'URGENT');
```

### COMPOSITE tipovi
```sql
CREATE TYPE timestamp_metadata AS (created_at TIMESTAMP, updated_at TIMESTAMP);
CREATE TYPE address_info AS (street VARCHAR, city VARCHAR, postal_code VARCHAR, country VARCHAR);
```

### Domene
```sql
CREATE DOMAIN email_address AS VARCHAR(100)
    CHECK (VALUE ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
```

### Funkcije (11)
- `validate_email()`, `generate_slug()`, `check_password_strength()`
- `user_has_permission()`, `get_user_permissions()`, `get_user_roles()`
- `is_manager_of()`, `get_team_members()`
- `get_user_tasks()`, `get_task_statistics()`, `log_login_attempt()`

### Procedure (10)
- `create_user()`, `update_user()`, `deactivate_user()`
- `create_task()`, `update_task_status()`, `assign_task()`
- `assign_role()`, `revoke_role()`
- `cleanup_old_audit_logs()`, `cleanup_old_login_events()`

### Triggeri (7)
- Audit triggeri za `users`, `tasks`, `user_roles`
- Auto-update `updated_at` za `users`, `roles`, `tasks`
- Validacija hijerarhije managera

### Pogledi (5)
- `v_users_with_roles`, `v_roles_with_permissions`
- `v_tasks_details`, `v_user_statistics`, `v_manager_team`

---

## RBAC Model

### Uloge
| Uloga | Opis |
|-------|------|
| ADMIN | Puni pristup sustavu |
| MANAGER | Upravljanje timom i zadacima |
| EMPLOYEE | Rad s vlastitim zadacima |

### Kategorije permisija
- **USER**: USER_VIEW, USER_CREATE, USER_UPDATE, USER_DELETE
- **ROLE**: ROLE_VIEW, ROLE_CREATE, ROLE_UPDATE, ROLE_DELETE, ROLE_ASSIGN
- **TASK**: TASK_VIEW, TASK_CREATE, TASK_UPDATE, TASK_UPDATE_ANY, TASK_DELETE, TASK_ASSIGN
- **AUDIT**: AUDIT_VIEW, AUDIT_EXPORT, AUDIT_DELETE

---

## Testni korisnici

| Username | Password | Uloga |
|----------|----------|-------|
| admin | Admin@123 | ADMIN |
| ivan_manager | Manager@123 | MANAGER |
| ana_manager | Manager@123 | MANAGER |
| marko_emp | Employee@123 | EMPLOYEE |
| petra_emp | Employee@123 | EMPLOYEE |

---

## API Endpoints

### Autentikacija
- `POST /api/auth/login` - Prijava
- `GET /api/auth/me` - Trenutni korisnik
- `GET /api/auth/me/permissions` - Moje permisije

### Korisnici
- `GET /api/users` - Svi korisnici
- `POST /api/users` - Kreiraj korisnika
- `GET /api/users/{id}` - Pojedini korisnik
- `PUT /api/users/{id}` - Ažuriraj korisnika
- `DELETE /api/users/{id}` - Deaktiviraj korisnika

### Zadaci
- `GET /api/tasks` - Svi zadaci
- `GET /api/tasks/my` - Moji zadaci
- `POST /api/tasks` - Kreiraj zadatak
- `PUT /api/tasks/{id}/status` - Promijeni status
- `PUT /api/tasks/{id}/assign` - Dodijeli zadatak

### Uloge
- `GET /api/roles` - Sve uloge
- `POST /api/roles/assign` - Dodijeli ulogu
- `DELETE /api/roles/revoke` - Ukloni ulogu

### Audit
- `GET /api/audit/logs` - Audit logovi
- `GET /api/audit/logins` - Login eventi

---


