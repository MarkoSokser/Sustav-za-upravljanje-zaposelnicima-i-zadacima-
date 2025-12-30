# Faza 6: Backend Aplikacija (FastAPI)

## Pregled

Faza 6 implementira RESTful API backend koristeći FastAPI framework. Backend služi kao aplikacijski sloj koji povezuje PostgreSQL bazu podataka s klijentskim aplikacijama.


## 1. Arhitektura

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI aplikacija
│   ├── config.py            # Konfiguracija (env varijable)
│   ├── database.py          # Povezivanje s PostgreSQL
│   ├── auth.py              # JWT autentikacija & RBAC
│   ├── schemas.py           # Pydantic modeli
│   └── routers/
│       ├── __init__.py
│       ├── auth.py          # /api/auth/*
│       ├── users.py         # /api/users/*
│       ├── tasks.py         # /api/tasks/*
│       ├── roles.py         # /api/roles/*
│       └── audit.py         # /api/audit/*
├── requirements.txt
└── .env.example
```

---

## 2. Instalacija i Pokretanje

### Preduvjeti
- Python 3.10+
- PostgreSQL 15+ s inicijaliziranom bazom (Faze 1-5)

### Koraci

```bash
# 1. Pozicioniraj se u backend folder
cd backend

# 2. Kreiraj virtualno okruženje
python -m venv venv

# 3. Aktiviraj virtualno okruženje
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# 4. Instaliraj dependencies
pip install -r requirements.txt

# 5. Kopiraj i konfiguriraj .env
copy .env.example .env
# Uredi .env s ispravnim podacima za bazu

# 6. Pokreni aplikaciju
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Dokumentacija
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

---


---

## 4. API Endpoints

### 4.1 Autentikacija (`/api/auth`)

| Metoda | Endpoint | Opis | PostgreSQL |
|--------|----------|------|------------|
| POST | `/login` | Prijava korisnika | `log_login_attempt()` |
| GET | `/me` | Trenutni korisnik | `v_users_with_roles` |
| GET | `/me/permissions` | Moje permisije | `get_user_permissions()` |
| GET | `/me/roles` | Moje uloge | `get_user_roles()` |
| POST | `/check-permission/{code}` | Provjeri permisiju | `user_has_permission()` |
| POST | `/validate-password` | Provjeri lozinku | `check_password_strength()` |
| **POST** | **`/change-password`** | **Promijeni lozinku** | **direktni SQL** |

#### Primjer promjene lozinke (NOVO)

```bash
curl -X POST "http://localhost:8000/api/auth/change-password" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "current_password": "StaraLozinka123!",
    "new_password": "NovaLozinka456!"
  }'
```

**Response:**
```json
{
  "message": "Lozinka uspješno promijenjena",
  "success": true
}
```

#### Primjer prijave

```bash
curl -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=Admin123!"
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

---

### 4.2 Korisnici (`/api/users`)

| Metoda | Endpoint | Opis | Permisija | PostgreSQL |
|--------|----------|------|-----------|------------|
| GET | `/` | Svi korisnici | USER_READ_ALL | `v_users_with_roles` |
| GET | `/statistics` | Statistike korisnika | USER_READ_ALL | `v_user_statistics` |
| GET | `/team` | **NOVO** Moj tim | USER_READ_TEAM | `get_team_members()` |
| GET | `/{id}` | Pojedini korisnik | * | `v_users_with_roles` |
| GET | `/{id}/statistics` | Statistika zadataka | * | `get_task_statistics()` |
| GET | `/{id}/team` | Članovi tima | * | `get_team_members()` |
| GET | `/{id}/permissions` | **NOVO** Permisije korisnika | USER_READ_ALL | `user_permissions` |
| POST | `/` | Kreiraj korisnika | USER_CREATE | `create_user()` |
| PUT | `/{id}` | Ažuriraj korisnika | USER_UPDATE | `update_user()` |
| PUT | `/{id}/permissions` | **NOVO** Dodaj permisiju | PERMISSION_MANAGE | `user_permissions` |
| DELETE | `/{id}` | Deaktiviraj korisnika | USER_DELETE | `deactivate_user()` |
| DELETE | `/{id}/permissions/{perm}` | **NOVO** Ukloni permisiju | PERMISSION_MANAGE | `user_permissions` |

**\*** - Vlastiti podaci ili člana tima

#### Primjer kreiranja korisnika

```bash
curl -X POST "http://localhost:8000/api/users" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "novi_korisnik",
    "email": "novi@example.com",
    "password": "Strong@Pass123",
    "first_name": "Novi",
    "last_name": "Korisnik",
    "manager_id": 2,
    "role_name": "EMPLOYEE"
  }'
```

---

### 4.3 Zadaci (`/api/tasks`)

| Metoda | Endpoint | Opis | Permisija | PostgreSQL |
|--------|----------|------|-----------|------------|
| GET | `/` | Svi zadaci | TASK_READ_ALL | `v_tasks_details` |
| GET | `/my` | Moji zadaci | - | `get_user_tasks()` |
| GET | `/my/statistics` | Moja statistika | - | `get_task_statistics()` |
| GET | `/{id}` | Pojedini zadatak | * | `v_tasks_details` |
| POST | `/` | Kreiraj zadatak | TASK_CREATE | `create_task()` |
| PUT | `/{id}` | Ažuriraj zadatak | TASK_UPDATE | direktni SQL |
| PUT | `/{id}/status` | Promijeni status | * | `update_task_status()` |
| PUT | `/{id}/assign` | Dodijeli zadatak | TASK_ASSIGN | `task_assignees` |
| DELETE | `/{id}` | Obriši zadatak | TASK_DELETE | direktni SQL |

#### Workflow odobravanja zadataka (NOVO)

**Pravila promjene statusa:**
- **Employee** može: NEW → IN_PROGRESS → ON_HOLD → PENDING_APPROVAL
- **Employee NE MOŽE** direktno staviti COMPLETED
- **Manager/Admin** može odobriti: PENDING_APPROVAL → COMPLETED
- **Manager/Admin** može vratiti: PENDING_APPROVAL → IN_PROGRESS

#### Primjer predaje zadatka na odobrenje (Employee)

```bash
curl -X PUT "http://localhost:8000/api/tasks/1/status" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"status": "PENDING_APPROVAL"}'
```

#### Primjer odobravanja zadatka (Manager/Admin)

```bash
curl -X PUT "http://localhost:8000/api/tasks/1/status" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"status": "COMPLETED"}'
```

**Napomena:** Manager može staviti COMPLETED samo ako je zadatak u statusu PENDING_APPROVAL.

---

### 4.4 Uloge (`/api/roles`)

| Metoda | Endpoint | Opis | Permisija | PostgreSQL |
|--------|----------|------|-----------|------------|
| GET | `/` | Sve uloge | ROLE_READ | `v_roles_with_permissions` |
| GET | `/permissions` | Sve permisije | ROLE_READ | `permissions` |
| GET | `/{id}` | Pojedina uloga | ROLE_READ | `v_roles_with_permissions` |
| GET | `/{id}/users` | Korisnici s ulogom | ROLE_READ | direktni SQL |
| POST | `/` | Kreiraj ulogu | ROLE_CREATE | direktni SQL |
| PUT | `/{id}` | Ažuriraj ulogu | ROLE_UPDATE | direktni SQL |
| POST | `/assign` | Dodijeli ulogu | ROLE_ASSIGN | `assign_role()` |
| DELETE | `/revoke` | Ukloni ulogu | ROLE_ASSIGN | `revoke_role()` |
| DELETE | `/{id}` | Obriši ulogu | ROLE_DELETE | direktni SQL |
| POST | `/{id}/permissions/{code}` | Dodaj permisiju | ROLE_UPDATE | direktni SQL |
| DELETE | `/{id}/permissions/{code}` | Ukloni permisiju | ROLE_UPDATE | direktni SQL |

---

### 4.5 Audit (`/api/audit`)

| Metoda | Endpoint | Opis | Permisija | PostgreSQL |
|--------|----------|------|-----------|------------|
| GET | `/logs` | Audit logovi | AUDIT_VIEW | `audit_log` |
| GET | `/logs/entity/{name}/{id}` | Povijest entiteta | AUDIT_VIEW | `audit_log` |
| GET | `/logins` | Login eventi | AUDIT_VIEW | `login_events` |
| GET | `/logins/failed` | Neuspjele prijave | AUDIT_VIEW | `login_events` |
| GET | `/statistics` | Statistike | AUDIT_VIEW | agregacije |
| POST | `/cleanup/logs` | Očisti logove | AUDIT_DELETE | `cleanup_old_audit_logs()` |
| POST | `/cleanup/logins` | Očisti logine | AUDIT_DELETE | `cleanup_old_login_events()` |

---

## 5. Integracija s PostgreSQL

### 5.1 Korištenje funkcija

```python
# U routers/auth.py
@router.get("/me/permissions")
async def get_my_permissions(current_user, conn):
    """Koristi get_user_permissions() funkciju iz baze"""
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM get_user_permissions(%s)", 
                   (current_user['user_id'],))
        return cur.fetchall()
```

### 5.2 Korištenje procedura

```python
# U routers/users.py
@router.post("")
async def create_user(user_data, current_user, conn):
    """Koristi create_user() proceduru iz baze"""
    with conn.cursor() as cur:
        cur.execute("""
            CALL create_user(%s, %s, %s, %s, %s, %s, %s, %s, NULL)
        """, (
            user_data.username, user_data.email, password_hash,
            user_data.first_name, user_data.last_name,
            user_data.manager_id, user_data.role_name,
            current_user['user_id']
        ))
```

### 5.3 Korištenje pogleda

```python
# U routers/tasks.py
@router.get("")
async def get_all_tasks(conn):
    """Koristi v_tasks_details pogled iz baze"""
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM v_tasks_details")
        return cur.fetchall()
```

### 5.4 RBAC provjere

```python
# U auth.py
def check_permission(conn, user_id: int, permission_code: str) -> bool:
    """Koristi user_has_permission() funkciju iz baze"""
    with conn.cursor() as cur:
        cur.execute(
            "SELECT user_has_permission(%s, %s) as has_permission",
            (user_id, permission_code)
        )
        result = cur.fetchone()
        return result['has_permission'] if result else False
```

---

## 6. Autentikacija i Autorizacija

### 6.1 JWT Token Flow

1. Korisnik šalje username/password na `/api/auth/login`
2. Backend validira kredencijale protiv baze
3. Ako uspješno, generira JWT token s user_id i username
4. Token se logira putem `log_login_attempt()` funkcije
5. Klijent koristi token u `Authorization: Bearer {token}` header-u
6. Backend dekodira token i dohvaća korisnika iz baze

### 6.2 RBAC Flow

1. Endpoint je zaštićen s `require_permission("PERMISSION_CODE")`
2. Middleware dekodira JWT token
3. Dohvaća se korisnik iz baze
4. Poziva se `user_has_permission()` funkcija iz baze
5. Ako korisnik nema permisiju, vraća se 403 Forbidden

---

## 7. Testiranje API-ja

### 7.1 Automatsko Testiranje

Backend dolazi s kompletnom test skriptom koja testira sve endpointe i funkcionalnosti.

#### Pokretanje Test Skripte

```bash
# 1. Aktiviraj virtualno okruženje 
venv\Scripts\activate

# 2. Pokreni test skriptu
python test_api.py
```

#### Test Pokrivenost

Test skripta provjerava **41 test slučaj**:

**1. Health Check (4 testa)**
- Root endpoint dostupnost
- API verzija
- Health endpoint
- Database konekcija

**2. Autentikacija (9 testova)**
- Admin login
- Token generiranje
- Neuspješna prijava
- Trenutni korisnik
- Permisije korisnika
- Uloge korisnika

**3. Korisnici (5 testova)**
- Lista svih korisnika
- Statistike korisnika
- Pojedinačni korisnik
- Tim korisnika

**4. Zadaci (6 testova)**
- Lista zadataka
- Kreiranje zadatka
- Statistike zadataka
- Moji zadaci

**5. Uloge (6 testova)**
- Lista uloga
- Provjera sistemskih uloga (ADMIN, MANAGER, EMPLOYEE)
- Lista permisija

**6. Audit Logovi (3 testa)**
- Audit zapisi
- Login eventi

**7. Sigurnost (2 testa)**
- Odbijanje neautoriziranog pristupa
- Odbijanje nevažećeg tokena

**8. Različiti Korisnici (4 testa)**
- Manager login i uloge
- Employee login
- RBAC permisije


**Napomena**: Svi korisnici trenutno dijele istu lozinku (`Admin@123`) za potrebe testiranja.

---

### 7.2 Korištenje Swagger UI

1. Otvori http://localhost:8000/docs
2. Klikni na "Authorize" button
3. Unesi **username** i **password** (npr. `admin` / `Admin@123`)
4. Klikni "Authorize"
5. Testiraj endpoint-e

**Važno**: U Swagger UI unosiš username i password, ne JWT token! Swagger automatski upravlja tokenom.

---

### 7.3 Primjeri s curl

```bash
# 1. Prijava
TOKEN=$(curl -s -X POST "http://localhost:8000/api/auth/login" \
  -d "username=admin&password=Admin@123" | jq -r '.access_token')

# 2. Dohvati profil
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/auth/me"

# 3. Dohvati sve korisnike
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/users"

# 4. Kreiraj zadatak
curl -X POST "http://localhost:8000/api/tasks" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Novi zadatak", "priority": "HIGH"}'

# 5. Provjeri audit log
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/audit/logs?limit=10"
```

---

## 8. Demonstracija PostgreSQL Mogućnosti

Backend aktivno koristi sve mogućnosti baze implementirane u prethodnim fazama:

| Mogućnost | Primjena u Backend-u |
|-----------|---------------------|
| ENUM tipovi | TaskStatus, TaskPriority enum klase mapiraju se na PostgreSQL ENUM |
| Domene | email_address validacija kroz bazu |
| Funkcije | RBAC provjere, statistike, validacije |
| Procedure | CRUD operacije s transakcijama |
| Triggeri | Automatsko audit logiranje (transparentno) |
| Pogledi | Denormalizirani podaci za efikasne upite |

---



