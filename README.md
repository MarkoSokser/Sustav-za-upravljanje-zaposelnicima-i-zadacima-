# Interni sustav za upravljanje zaposlenicima i zadacima

## TBP Projekt

Sustav za upravljanje korisnicima, zadacima i pravima pristupa s RBAC modelom.


---

## Preduvjeti

Prije pokretanja instalacijskih skripti, morate imati instalirano:

1. **PostgreSQL 14+** - https://www.postgresql.org/download/
2. **Python 3.9+** - https://www.python.org/downloads/
3. **Node.js 16+** - https://nodejs.org/

---

## Instalacija

### Windows (PowerShell) - PREPORUČENO
```powershell
# Iz root foldera projekta:
.\setup\install.ps1
```

### Windows (Command Prompt)
```batch
# Iz root foldera projekta:
setup\install.bat
```

### Napredne opcije (PowerShell)
```powershell
# Preskoči bazu (ako već postoji)
.\setup\install.ps1 -SkipDatabase

# Preskoči backend (npr. za frontend developere)
.\setup\install.ps1 -SkipBackend

# Koristi custom PostgreSQL postavke
.\setup\install.ps1 -PostgresUser "myuser" -PostgresHost "192.168.1.100"
```

---

## Pokretanje

### PowerShell
```powershell
.\setup\start.ps1

# Samo backend
.\setup\start.ps1 -BackendOnly

# Samo frontend
.\setup\start.ps1 -FrontendOnly
```

### Command Prompt
```batch
setup\start.bat
```

---

## Što skripte rade?

### install.ps1 / install.bat

1. **Provjera preduvjeta** - PostgreSQL, Python, Node.js, npm
2. **Kreiranje baze podataka** - `interni_sustav`
3. **Izvršavanje SQL skripti**:
   - `01_schema.sql` - Kreiranje tablica i tipova
   - `02_seed_data.sql` - Početni podaci (korisnici, uloge)
   - `03_functions_procedures.sql` - Funkcije, procedure, triggeri
4. **Backend setup**:
   - Kreiranje Python virtual environment
   - Instaliranje paketa iz `requirements.txt`
   - Kreiranje `.env` datoteke
5. **Frontend setup**:
   - Instaliranje npm paketa

### start.ps1 / start.bat

1. Pokreće backend server u novom terminalu (port 8000)
2. Čeka 3 sekunde
3. Pokreće frontend server u novom terminalu (port 3000)

---

## Pristupni podaci

| Uloga | Username | Password |
|-------|----------|----------|
| **ADMIN** | admin | Admin123! |
| **MANAGER** | ivan_manager | IvanM2024! |
| **EMPLOYEE** | marko_dev | Marko2024! |

Detaljni pristupni podaci: [`PRISTUPNI_PODACI.md`](PRISTUPNI_PODACI.md)

---

## Linkovi

- **Aplikacija:** http://localhost:3000
- **API Docs:** http://localhost:8000/docs
- **Backend:** http://localhost:8000

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
