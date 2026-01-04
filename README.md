# Interni sustav za upravljanje zaposlenicima i zadacima

## TBP Projekt

Sustav za upravljanje korisnicima, zadacima i pravima pristupa s RBAC modelom.

📁 **Instalacijske skripte:** [`setup/`](setup/)

---

## Preduvjeti

Prije pokretanja instalacijskih skripti, morate imati instalirano:

1. **PostgreSQL 14+** - https://www.postgresql.org/download/
2. **Python 3.9+** - https://www.python.org/downloads/
3. **Node.js 16+** - https://nodejs.org/

---

## Automatska instalacija

### Korak 1: Pokrenite instalacijsku skriptu

**PowerShell (preporučeno):**
```powershell
.\setup\install.ps1
```

**Command Prompt:**
```batch
setup\install.bat
```

### Korak 2: Pokrenite aplikaciju

**PowerShell:**
```powershell
.\setup\start.ps1
```

**Command Prompt:**
```batch
setup\start.bat
```

### Korak 3: Otvorite aplikaciju

- **Aplikacija:** http://localhost:3000
- **API Docs:** http://localhost:8000/docs

---

## Ručna instalacija (ako automatska ne uspije)

### 1. Kreiranje baze podataka

```powershell
# Otvorite psql terminal
psql -U postgres

# U psql terminalu izvršite:
CREATE DATABASE interni_sustav;
\c interni_sustav
\i database/01_schema.sql
\i database/02_seed_data.sql
\i database/03_functions_procedures.sql
\q
```

### 2. Postavljanje Backend-a

```powershell
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Postavljanje Frontend-a

```powershell
cd frontend
npm install
```

### 4. Pokretanje (potrebna 2 terminala)

**Terminal 1 - Backend:**
```powershell
cd backend
.\venv\Scripts\activate
python -m uvicorn app.main:app --reload
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
- Dodajte PostgreSQL `bin` folder u PATH varijablu
- Tipično: `C:\Program Files\PostgreSQL\15\bin`

### "python nije pronađen"
- Provjerite je li Python instaliran
- Provjerite je li dodan u PATH

### Greška pri kreiranju baze
- Provjerite je li PostgreSQL servis pokrenut
- Provjerite korisničko ime i lozinku

### npm install greške
- Obrišite `node_modules` folder i pokušajte ponovno
- Pokrenite `npm cache clean --force`

---

## Struktura projekta

```
TBP_projekt/
├── setup/                       # Instalacijske skripte
│   ├── install.ps1             
│   ├── install.bat             
│   ├── start.ps1               
│   └── start.bat               
├── database/                    # SQL skripte
│   ├── 01_schema.sql           
│   ├── 02_seed_data.sql        
│   └── 03_functions_procedures.sql
├── backend/                     # FastAPI REST API
├── frontend/                    # React aplikacija
├── tests/                       # SQL testovi
├── Prirucnici/                  # Dokumentacija
├── PRISTUPNI_PODACI.md          # Korisnički podaci
└── README.md                    # Ova datoteka
```
