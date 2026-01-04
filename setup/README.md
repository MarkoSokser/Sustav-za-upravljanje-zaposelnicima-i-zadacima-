# Setup - Instalacijske skripte

Ovaj folder sadrži sve skripte potrebne za automatsku instalaciju i pokretanje projekta.

## Struktura

```
setup/
├── install.ps1    # PowerShell instalacijska skripta (preporučeno)
├── install.bat    # Batch instalacijska skripta (alternativa)
├── start.ps1      # PowerShell skripta za pokretanje
├── start.bat      # Batch skripta za pokretanje
└── README.md      # Ova dokumentacija
```

## Instalacija

### PowerShell (PREPORUČENO)
```powershell
# Iz root foldera projekta:
.\setup\install.ps1
```

### Command Prompt
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

## Preduvjeti

Prije pokretanja instalacijskih skripti, morate imati instalirano:

1. **PostgreSQL 14+** - https://www.postgresql.org/download/
2. **Python 3.9+** - https://www.python.org/downloads/
3. **Node.js 16+** - https://nodejs.org/

Skripte će automatski provjeriti jesu li ovi alati dostupni.

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
