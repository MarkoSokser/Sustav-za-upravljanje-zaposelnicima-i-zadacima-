# Interni sustav za upravljanje zaposlenicima i zadacima

## TBP Projekt - Kompletan sustav za upravljanje korisnicima, zadacima i pravima pristupa

###  Opis projekta

Ovaj projekt demonstrira primjenu **poopćenih i objektno-relacijskih baza podataka** (PostgreSQL) kroz implementaciju internog sustava za upravljanje zaposlenicima i zadacima s **RBAC modelom** (Role-Based Access Control).

**Projekt uključuje:**
-  PostgreSQL bazu s naprednim značajkama (ENUM, COMPOSITE tipovi, domene, funkcije, procedure, triggere)
-  FastAPI REST API backend s JWT autentikacijom
-  **React frontend aplikaciju** sa svim funkcionalnostima
-  Potpuni RBAC sustav (3 uloge, 12 permisija)
-  Automatski audit log putem PostgreSQL triggerah
-  **Višestruka dodjela zadataka** (M:N veza - jedan zadatak može imati više assignee-a)

###  Tehnologije

- **Baza podataka**: PostgreSQL 15+
- **Backend**: Python FastAPI 0.109+
- **Frontend**: React 18.2 + React Router + Axios
- **Autentikacija**: JWT tokeni, bcrypt
- **RBAC**: Role-Based Access Control

---

##  Automatska instalacija

### Preduvjeti
- PostgreSQL 14+ instaliran i pokrenut
- Python 3.9+
- Node.js 16+ i npm

### Windows (PowerShell) - PREPORUČENO
```powershell
# Pokrenite instalacijsku skriptu iz setup foldera
.\setup\install.ps1
```

### Windows (Command Prompt)
```batch
# Pokrenite batch skriptu iz setup foldera
setup\install.bat
```

Instalacijska skripta automatski:
1.  Provjerava preduvjete (PostgreSQL, Python, Node.js)
2.  Kreira bazu podataka
3.  Izvršava sve SQL skripte (schema, seed data, funkcije)
4.  Postavlja Python virtual environment i instalira pakete
5.  Instalira npm pakete za frontend

### Pokretanje nakon instalacije
```powershell
.\setup\start.ps1    # ili setup\start.bat
```

---

##  Ručna instalacija

 **Detaljne upute:** [`QUICK_START.md`](QUICK_START.md)

**1. Baza podataka:**
```powershell
psql -U postgres
CREATE DATABASE interni_sustav;
\c interni_sustav
\i database/01_schema.sql
\i database/02_seed_data.sql
\i database/03_functions_procedures.sql

```

**2. Backend:**
```powershell
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
python -m uvicorn app.main:app --reload
```
Backend: **http://localhost:8000** | Docs: **http://localhost:8000/docs**

**3. Frontend:**
```powershell
cd frontend
npm install
npm start
```
Frontend: **http://localhost:3000**

###  Demo pristupni podaci

| Uloga | Username | Password | Opis |
|-------|----------|----------|------|
| **ADMIN** | admin | admin123 | Puni pristup svim funkcijama |
| **MANAGER** | jnovak | manager123 | Upravljanje timom i zadacima |
| **EMPLOYEE** | ahorvat | employee123 | Pregled vlastitih zadataka |

---

## Struktura projekta

```
TBP_projekt/
├── database/                    # PostgreSQL baza
│   ├── 01_schema.sql           # Shema (tablice, ENUM, COMPOSITE, domene, viewovi)
│   ├── 02_seed_data.sql        # Početni podaci (demo korisnici)
│   └── 03_functions_procedures.sql  # Funkcije, procedure, triggeri
├── backend/                     # FastAPI REST API
│   ├── app/
│   │   ├── main.py             # Glavna aplikacija
│   │   ├── routers/            # users, tasks, roles, auth, audit
│   │   ├── auth.py             # JWT autentikacija + RBAC
│   │   └── schemas.py          # Pydantic modeli
│   └── requirements.txt
├── frontend/                    # **React aplikacija (NOVO)**
│   ├── src/
│   │   ├── pages/              # Login, Dashboard, Users, Tasks, Roles, Audit
│   │   ├── components/         # Layout, ProtectedRoute
│   │   ├── context/            # AuthContext
│   │   ├── services/           # API calls (Axios)
│   │   └── App.js
│   ├── package.json
│   └── README.md
├── tests/                       # SQL testovi za bazu
├── Prirucnici/                  # Detaljni priručnici po fazama
│   ├── PRIRUCNIK_PROJEKTA.md   # Glavni canvas
│   ├── Faza_1_2_3_Prirucnik.md
│   ├── Faza_4_Prirucnik.md
│   ├── Faza_5_Prirucnik.md
│   ├── Faza_6_Prirucnik.md
│   └── Faza_7_Prirucnik.md     # **Frontend (NOVO)**
├── QUICK_START.md               # Brzi vodič za pokretanje
├── start.ps1                    # Automatska PowerShell skripta
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
- `v_tasks_details` (ažurirano za višestruku dodjelu)
- `v_user_statistics`, `v_manager_team`

### Tablice (9)
- `users`, `roles`, `permissions`, `user_roles`, `role_permissions`
- `tasks`, `task_assignees` (NOVO - M:N veza za višestruku dodjelu)
- `login_events`, `audit_logs`

---

## RBAC Model

###📱 Frontend funkcionalnosti

### Stranice

1. ** Login** - JWT autentikacija
2. ** Dashboard** - Statistike i pregled zadataka
3. ** Users** - CRUD za korisnike (prikazuje `v_users_with_roles` view)
4. ** Tasks** - CRUD za zadatke (koristi `task_status` i `task_priority` ENUM-e)
5. ** Roles** - Dodjela i upravljanje ulogama
6. ** Audit Logs** - Prikaz svih promjena (triggeri `trg_audit_*`)

### Demonstracija PostgreSQL značajki

| PostgreSQL element | Gdje se prikazuje |
|-------------------|-------------------|
| ENUM tipovi | Tasks stranica (status, prioritet) |
| COMPOSITE tipovi | Automatski (timestamp_metadata) |
| Domene | Users stranica (email validacija) |
| Funkcije | Dashboard (get_user_tasks, get_overdue_tasks) |
| Procedure | Sve CRUD operacije (create_user, create_task) |
| Triggeri | Audit stranica (automatski logovi) |
| Viewovi | Users, Tasks, Roles stranice |
| RBAC | Cijela aplikacija (provjera permisija)SER_UPDATE, USER_DELETE
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


