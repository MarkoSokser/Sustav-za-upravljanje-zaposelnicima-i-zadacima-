# ============================================================
# INSTALACIJSKA SKRIPTA - Interni sustav za upravljanje zadacima
# ============================================================
# Autor: [Marko Sokser]
# Verzija: 1.0
# ============================================================

param(
    [string]$PostgresUser = "postgres",
    [string]$PostgresPassword = "",
    [string]$DatabaseName = "interni_sustav",
    [string]$PostgresHost = "localhost",
    [string]$PostgresPort = "5432",
    [switch]$SkipDatabase,
    [switch]$SkipBackend,
    [switch]$SkipFrontend
)

$ErrorActionPreference = "Stop"

# Putanja do root foldera projekta (jedan nivo gore od setup/)
$ProjectRoot = Split-Path -Parent $PSScriptRoot

# Boje za output
function Write-ColorOutput($ForegroundColor, $Message) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Output $Message
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Step($Message) {
    Write-ColorOutput Green "✓ $Message"
}

function Write-Info($Message) {
    Write-ColorOutput Cyan "ℹ $Message"
}

function Write-ErrorMsg($Message) {
    Write-ColorOutput Red "✗ $Message"
}

# ============================================================
# PROVJERA PREDUVJETA
# ============================================================
Write-Output ""
Write-Output "============================================================"
Write-Output "   INSTALACIJA - Interni sustav za upravljanje zadacima"
Write-Output "============================================================"
Write-Output ""

Write-Info "Provjera preduvjeta..."

# Provjera PostgreSQL
try {
    $psqlVersion = psql --version 2>&1
    Write-Step "PostgreSQL pronađen: $psqlVersion"
} catch {
    Write-ErrorMsg "PostgreSQL (psql) nije pronađen! Molimo instalirajte PostgreSQL 14+."
    Write-Output "Download: https://www.postgresql.org/download/"
    exit 1
}

# Provjera Python
try {
    $pythonVersion = python --version 2>&1
    Write-Step "Python pronađen: $pythonVersion"
} catch {
    Write-ErrorMsg "Python nije pronađen! Molimo instalirajte Python 3.9+."
    Write-Output "Download: https://www.python.org/downloads/"
    exit 1
}

# Provjera Node.js
try {
    $nodeVersion = node --version 2>&1
    Write-Step "Node.js pronađen: $nodeVersion"
} catch {
    Write-ErrorMsg "Node.js nije pronađen! Molimo instalirajte Node.js 16+."
    Write-Output "Download: https://nodejs.org/"
    exit 1
}

# Provjera npm
try {
    $npmVersion = npm --version 2>&1
    Write-Step "npm pronađen: v$npmVersion"
} catch {
    Write-ErrorMsg "npm nije pronađen!"
    exit 1
}

Write-Output ""

# ============================================================
# POSTAVLJANJE BAZE PODATAKA
# ============================================================
if (-not $SkipDatabase) {
    Write-Output "============================================================"
    Write-Output "   KORAK 1: Postavljanje baze podataka"
    Write-Output "============================================================"
    Write-Output ""

    # Traži lozinku ako nije proslijeđena
    if ([string]::IsNullOrEmpty($PostgresPassword)) {
        $securePassword = Read-Host "Unesite lozinku za PostgreSQL korisnika '$PostgresUser'" -AsSecureString
        $PostgresPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
    }

    $env:PGPASSWORD = $PostgresPassword

    Write-Info "Kreiranje baze podataka '$DatabaseName'..."
    
    # Provjeri postoji li baza
    $checkDb = psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -lqt 2>&1 | Select-String $DatabaseName
    
    if ($checkDb) {
        $response = Read-Host "Baza '$DatabaseName' već postoji. Želite li je obrisati i kreirati iznova? (da/ne)"
        if ($response -eq "da") {
            Write-Info "Brisanje postojeće baze..."
            psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -c "DROP DATABASE IF EXISTS $DatabaseName;" 2>&1 | Out-Null
        } else {
            Write-Info "Preskačem kreiranje baze..."
            $SkipDatabaseCreate = $true
        }
    }

    if (-not $SkipDatabaseCreate) {
        # Kreiraj bazu
        psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -c "CREATE DATABASE $DatabaseName WITH ENCODING 'UTF8';" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Greška pri kreiranju baze podataka!"
            exit 1
        }
        Write-Step "Baza podataka kreirana"

        # Izvršavanje SQL skripti
        $databasePath = Join-Path $ProjectRoot "database"

        Write-Info "Izvršavanje 01_schema.sql..."
        psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -d $DatabaseName -f "$databasePath\01_schema.sql" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Greška pri izvršavanju 01_schema.sql!"
            exit 1
        }
        Write-Step "Schema kreirana"

        Write-Info "Izvršavanje 02_seed_data.sql..."
        psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -d $DatabaseName -f "$databasePath\02_seed_data.sql" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Greška pri izvršavanju 02_seed_data.sql!"
            exit 1
        }
        Write-Step "Početni podaci uneseni"

        Write-Info "Izvršavanje 03_functions_procedures.sql..."
        psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -d $DatabaseName -f "$databasePath\03_functions_procedures.sql" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Greška pri izvršavanju 03_functions_procedures.sql!"
            exit 1
        }
        Write-Step "Funkcije i procedure kreirane"
    }

    $env:PGPASSWORD = ""
    Write-Output ""
}

# ============================================================
# POSTAVLJANJE BACKEND-a
# ============================================================
if (-not $SkipBackend) {
    Write-Output "============================================================"
    Write-Output "   KORAK 2: Postavljanje Backend-a (Python/FastAPI)"
    Write-Output "============================================================"
    Write-Output ""

    $backendPath = Join-Path $ProjectRoot "backend"
    Push-Location $backendPath

    # Kreiraj virtual environment ako ne postoji
    if (-not (Test-Path "venv")) {
        Write-Info "Kreiranje Python virtual environment..."
        python -m venv venv
        Write-Step "Virtual environment kreiran"
    } else {
        Write-Step "Virtual environment već postoji"
    }

    # Aktiviraj venv i instaliraj dependencies
    Write-Info "Instaliranje Python paketa..."
    & ".\venv\Scripts\pip.exe" install -r requirements.txt --quiet
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorMsg "Greška pri instaliranju Python paketa!"
        Pop-Location
        exit 1
    }
    Write-Step "Python paketi instalirani"

    # Kreiraj .env ako ne postoji
    $envFile = Join-Path $backendPath ".env"
    if (-not (Test-Path $envFile)) {
        Write-Info "Kreiranje .env datoteke..."
        @"
DATABASE_URL=postgresql://${PostgresUser}:${PostgresPassword}@${PostgresHost}:${PostgresPort}/${DatabaseName}
SECRET_KEY=your-super-secret-key-change-in-production-$(Get-Random -Maximum 999999)
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
"@ | Out-File -FilePath $envFile -Encoding UTF8
        Write-Step ".env datoteka kreirana"
    } else {
        Write-Step ".env datoteka već postoji"
    }

    Pop-Location
    Write-Output ""
}

# ============================================================
# POSTAVLJANJE FRONTEND-a
# ============================================================
if (-not $SkipFrontend) {
    Write-Output "============================================================"
    Write-Output "   KORAK 3: Postavljanje Frontend-a (React)"
    Write-Output "============================================================"
    Write-Output ""

    $frontendPath = Join-Path $ProjectRoot "frontend"
    Push-Location $frontendPath

    # Instaliraj npm pakete
    if (-not (Test-Path "node_modules")) {
        Write-Info "Instaliranje npm paketa (ovo može potrajati)..."
        npm install --silent 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Greška pri instaliranju npm paketa!"
            Pop-Location
            exit 1
        }
        Write-Step "npm paketi instalirani"
    } else {
        Write-Step "npm paketi već instalirani"
    }

    Pop-Location
    Write-Output ""
}

# ============================================================
# ZAVRŠETAK
# ============================================================
Write-Output "============================================================"
Write-Output "   ✓ INSTALACIJA USPJEŠNO ZAVRŠENA!"
Write-Output "============================================================"
Write-Output ""
Write-Output "Za pokretanje aplikacije:"
Write-Output ""
Write-Output "  1. Pokrenite Backend (Terminal 1):"
Write-Output "     cd backend"
Write-Output "     .\venv\Scripts\activate"
Write-Output "     python -m uvicorn app.main:app --reload"
Write-Output ""
Write-Output "  2. Pokrenite Frontend (Terminal 2):"
Write-Output "     cd frontend"
Write-Output "     npm start"
Write-Output ""
Write-Output "  Ili koristite skriptu: .\setup\start.ps1"
Write-Output ""
Write-Output "Pristupni podaci za testiranje:"
Write-Output "  Admin:    admin / Admin123!"
Write-Output "  Manager:  ivan_manager / IvanM2024!"
Write-Output "  Employee: marko_dev / Marko2024!"
Write-Output ""
Write-Output "Dokumentacija: README.md"
Write-Output "API Docs: http://localhost:8000/docs"
Write-Output "Aplikacija: http://localhost:3000"
Write-Output ""
Write-Output "============================================================"
