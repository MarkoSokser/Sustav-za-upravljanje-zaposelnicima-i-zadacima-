#  Brzi vodič za pokretanje projekta

Ovaj vodič pokazuje kako brzo pokrenuti kompletan sustav (bazu, backend i frontend).

## Preduvjeti

-  PostgreSQL 14+ instaliran i pokrenut
-  Python 3.9+ instaliran
-  Node.js 16+ i npm instalirani

## Korak 1: Postavljanje baze podataka

```powershell
# Kreiraj bazu podataka
psql -U postgres
CREATE DATABASE interni_sustav;
\c interni_sustav

# Izvršavaj SQL skripte redom:
\i database/01_schema.sql
\i database/02_seed_data.sql
\i database/03_functions_procedures.sql


# Provjeri instalaciju
SELECT * FROM v_users_with_roles;
```

## Korak 2: Pokretanje Backend-a

```powershell
# Pozicioniraj se u backend direktorij
cd backend

# Kreiraj virtual environment
python -m venv venv

# Aktiviraj virtual environment
.\venv\Scripts\activate

# Instaliraj dependencies
pip install -r requirements.txt

# Pokreni backend server
python -m uvicorn app.main:app --reload
```

Backend će biti dostupan na: **http://localhost:8000**  
API dokumentacija: **http://localhost:8000/docs**

## Korak 3: Pokretanje Frontend-a

```powershell
# Otvori NOVI terminal
# Pozicioniraj se u frontend direktorij
cd frontend

# Instaliraj dependencies
npm install

# Pokreni development server
npm start
```

Frontend će se automatski otvoriti na: **http://localhost:3000**

##  Testiranje sustava

### 1. Prijava

Koristi jedan od demo računa:

| Uloga | Username | Password |
|-------|----------|----------|
| ADMIN | admin | admin123 |
| MANAGER | jnovak | manager123 |
| EMPLOYEE | ahorvat | employee123 |

### 2. Testiranje funkcionalnosti

**Admin (admin/admin123):**
1. Idi na **Users** → Kreiraj novog korisnika
2. Idi na **Roles** → Dodijeli ulogu novom korisniku
3. Idi na **Tasks** → Kreiraj zadatak
4. Idi na **Audit** → Vidi sve promjene u bazi

**Manager (jnovak/manager123):**
1. Idi na **Dashboard** → Vidi statistike
2. Idi na **Tasks** → Kreiraj zadatak za svoj tim
3. Idi na **Tasks** → Promijeni status zadatka

**Employee (ahorvat/employee123):**
1. Idi na **Dashboard** → Vidi vlastite zadatke
2. Idi na **Tasks** → Vidi samo vlastite zadatke

### 3. Provjera PostgreSQL funkcionalnosti

**Triggeri (Audit Log):**
```sql
-- U psql terminalu
SELECT * FROM audit_log ORDER BY changed_at DESC LIMIT 5;
```

**Funkcije:**
```sql
-- Provjeri korisnička prava
SELECT user_has_permission(1, 'USER_CREATE');

-- Dohvati zadatke korisnika
SELECT * FROM get_user_tasks(3);
```

**Procedure:**
```sql
-- Kreiraj korisnika procedurom
CALL sp_create_user(
    'testuser', 'test@example.com', 'password123',
    'Test', 'User', NULL, NULL
);
```

**Viewovi:**
```sql
-- Pregled korisnika s ulogama
SELECT * FROM v_users_with_roles;

-- Detalji zadataka
SELECT * FROM v_tasks_details;


