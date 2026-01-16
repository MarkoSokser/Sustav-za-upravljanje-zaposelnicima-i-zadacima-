# Interni sustav za upravljanje zaposlenicima i zadacima

## TBP Projekt

Sustav za upravljanje korisnicima, zadacima i pravima pristupa s RBAC modelom.

📁 **Instalacijske skripte:** [`setup/`](setup/)

---

## ⚡ Brzi start

```powershell
# 1. Dodajte PostgreSQL u PATH
$env:PATH = "C:\Program Files\PostgreSQL\16\bin;$env:PATH"

# 2. Instalirajte sve (baza + backend + frontend)
cd setup
.\install.ps1 -PostgresPassword "postgres"

# 3. Pokrenite aplikaciju
.\start.ps1
```

Aplikacija: **http://localhost:3000** | API Docs: **http://localhost:8000/docs**



---

## Preduvjeti

Prije pokretanja instalacijskih skripti, morate imati instalirano:

1. **PostgreSQL 14+** - https://www.postgresql.org/download/
2. **Python 3.9+** - https://www.python.org/downloads/
3. **Node.js 16+** - https://nodejs.org/

---

## Automatska instalacija

### Korak 1: Dodajte PostgreSQL u PATH (jednokratno)

Prije prve instalacije, otvorite PowerShell i izvršite:

```powershell
$env:PATH = "C:\Program Files\PostgreSQL\16\bin;$env:PATH"
```

**Napomena:** Promijenite `16` u verziju vašeg PostgreSQL-a (npr. `15`, `14`, itd.)

### Korak 2: Pokrenite instalacijsku skriptu

**PowerShell (preporučeno):**
```powershell
cd setup
.\install.ps1 -PostgresPassword "postgres"
```

**Napomena:** Zamijenite `"postgres"` s vašom PostgreSQL lozinkom

Skripta će:
-  Kreirati bazu podataka `employee_db`
-  Izvršiti sve SQL skripte (schema, data, functions, advanced features)
-  Kreirati Python virtual environment
-  Instalirati Python pakete
-  Kreirati .env datoteku
-  Instalirati npm pakete

**Opcije:**
- `-SkipDatabase` - Preskače kreiranje baze podataka
- `-SkipBackend` - Preskače postavljanje backend-a
- `-SkipFrontend` - Preskače postavljanje frontend-a

### Korak 3: Pokrenite aplikaciju

**PowerShell:**
```powershell
cd setup
.\start.ps1
```

Otvorit će se dva nova PowerShell prozora - jedan za backend, drugi za frontend.

**Opcije:**
- `-BackendOnly` - Pokreće samo backend
- `-FrontendOnly` - Pokreće samo frontend

### Korak 4: Otvorite aplikaciju

- **Aplikacija:** http://localhost:3000
- **Backend API:** http://localhost:8000
- **API Docs:** http://localhost:8000/docs

---

## Ručna instalacija (ako automatska ne uspije)

### 1. Dodajte PostgreSQL u PATH

```powershell
$env:PATH = "C:\Program Files\PostgreSQL\16\bin;$env:PATH"
```

### 2. Kreiranje baze podataka

```powershell
# Otvorite psql terminal
psql -U postgres

# U psql terminalu izvršite:
CREATE DATABASE employee_db;
\c employee_db
\i database/01_schema.sql
\i database/02_seed_data.sql
\i database/03_functions_procedures.sql
\i database/04_advanced_features.sql
\q
```

### 3. Postavljanje Backend-a

```powershell
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt

# Kreirajte .env datoteku s ovim sadržajem:
# DATABASE_HOST=localhost
# DATABASE_PORT=5432
# DATABASE_NAME=employee_db
# DATABASE_USER=postgres
# DATABASE_PASSWORD=postgres
# SECRET_KEY=vašTajniKljučOvdje
# ALGORITHM=HS256
# ACCESS_TOKEN_EXPIRE_MINUTES=30
```

### 4. Postavljanje Frontend-a

```powershell
cd frontend
npm install
```

### 5. Pokretanje (potrebna 2 terminala)

**Terminal 1 - Backend:**
```powershell
cd backend
.\venv\Scripts\activate
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Terminal 2 - Frontend:**
```powershell
cd frontend
npm start
```

---

## Pristupni podaci

| Uloga | Username | Password |
|-------|----------|----------|
| **ADMIN** | admin | Admin123! |
| **MANAGER** | ivan_manager | IvanM2024! |
| **EMPLOYEE** | marko_dev | Marko2024! |

Detaljni pristupni podaci: [`PRISTUPNI_PODACI.md`](PRISTUPNI_PODACI.md)

---

## Rješavanje problema

### "psql nije pronađen"
Dodajte PostgreSQL `bin` folder u PATH varijablu:

```powershell
# PowerShell (privremeno - samo za trenutnu sesiju)
$env:PATH = "C:\Program Files\PostgreSQL\16\bin;$env:PATH"

# Ili trajno (System Properties > Environment Variables)
# Dodajte u PATH: C:\Program Files\PostgreSQL\16\bin
```

**Napomena:** Promijenite `16` u vašu verziju PostgreSQL-a

### "python nije pronađen"
- Provjerite je li Python instaliran: https://www.python.org/downloads/
- Tijekom instalacije označite **"Add Python to PATH"**

### Greška pri kreiranju baze
- Provjerite je li PostgreSQL servis pokrenut (Services → postgresql-x64-16)
- Provjerite korisničko ime i lozinku u naredbi
- Ako baza već postoji, instalacijska skripta će pitati želite li je prepisati

### npm install greške
```powershell
# Obrišite node_modules i pokušajte ponovno
Remove-Item -Recurse -Force frontend\node_modules
cd frontend
npm cache clean --force
npm install
```

### Backend ne može se spojiti na bazu
- Provjerite `.env` datoteku u `backend/` folderu
- Uvjerite se da su podaci za bazu točni (host, port, database, user, password)

### Frontend ne prikazuje podatke
- Provjerite radi li backend na http://localhost:8000
- Otvorite http://localhost:8000/docs da vidite API dokumentaciju
- Provjerite konzolu preglednika (F12) za greške

---

## Struktura projekta

```
Sustav-za-upravljanje-zaposelnicima-i-zadacima/
├── setup/                       # Instalacijske skripte
│   ├── install.ps1             # Automatska instalacija (PowerShell)
│   ├── install.bat             # Automatska instalacija (Batch)
│   ├── start.ps1               # Pokretanje aplikacije (PowerShell)
│   └── start.bat               # Pokretanje aplikacije (Batch)
├── database/                    # SQL skripte
│   ├── 01_schema.sql           # Database schema
│   ├── 02_seed_data.sql        # Početni podaci (korisnici, uloge)
│   ├── 03_functions_procedures.sql # Funkcije i procedure
│   └── 04_advanced_features.sql    # Napredne funkcionalnosti
├── backend/                     # FastAPI REST API
│   ├── app/                    # Aplikacijski kod
│   ├── requirements.txt        # Python paketi
│   ├── venv/                   # Virtual environment (kreira se)
│   └── .env                    # Environment varijable (kreira se)
├── frontend/                    # React aplikacija
│   ├── src/                    # Source kod
│   ├── public/                 # Statički resursi
│   ├── package.json            # npm paketi
│   └── node_modules/           # npm paketi (kreiraju se)
├── tests/                       # SQL testovi
├── Prirucnici/                  # Dokumentacija
├── ERA/                         # ERA dijagram
├── PRISTUPNI_PODACI.md          # Korisnički podaci za testiranje
└── README.md                    # Ova datoteka
```

---

## Napomene o sigurnosti

⚠️ **VAŽNO:** `.env` datoteka je uključena u repozitorij **SAMO ZA POTREBE TESTIRANJA** projekta.

U produkcijskom okruženju:
- `.env` datoteka **NIKADA** ne smije biti u repozitoriju
- Koristite jake, jedinstvene lozinke
- Koristite različite SECRET_KEY vrijednosti
- Aktivirajte `.env` u `.gitignore`
