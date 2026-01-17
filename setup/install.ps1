# ============================================================
# INSTALACIJSKA SKRIPTA - Interni sustav za upravljanje zadacima
# ============================================================
# Autor: [Marko Sokser]
# Verzija: 1.1
# ============================================================

param(
    [string]$PostgresUser = "postgres",
    [string]$PostgresPassword = "",
    [string]$DatabaseName = "employee_db",
    [string]$PostgresHost = "localhost",
    [string]$PostgresPort = "5432",
    [switch]$SkipDatabase,
    [switch]$SkipBackend,
    [switch]$SkipFrontend,
    [switch]$Force
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
    Write-ColorOutput Green "[OK] $Message"
}

function Write-Info($Message) {
    Write-ColorOutput Cyan "[INFO] $Message"
}

function Write-ErrorMsg($Message) {
    Write-ColorOutput Red "[ERROR] $Message"
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

# Provjera PostgreSQL (samo ako nije SkipDatabase)
if (-not $SkipDatabase) {
    # Provjeri da li je psql dostupan u PATH-u
    $psqlFound = $false
    try {
        $psqlVersion = psql --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Step "PostgreSQL pronadjen: $psqlVersion"
            $psqlFound = $true
        }
    } catch {
        # Nije u PATH-u, pokusaj pronaci na standardnim lokacijama
    }
    
    # Ako nije u PATH-u, trazi na standardnim Windows lokacijama
    if (-not $psqlFound) {
        Write-Info "PostgreSQL nije u PATH-u, pretrazujem standardne lokacije..."
        
        $possiblePaths = @(
            "C:\Program Files\PostgreSQL\16\bin",
            "C:\Program Files\PostgreSQL\15\bin",
            "C:\Program Files\PostgreSQL\14\bin",
            "C:\Program Files\PostgreSQL\13\bin",
            "C:\Program Files (x86)\PostgreSQL\16\bin",
            "C:\Program Files (x86)\PostgreSQL\15\bin",
            "C:\Program Files (x86)\PostgreSQL\14\bin"
        )
        
        foreach ($path in $possiblePaths) {
            if (Test-Path "$path\psql.exe") {
                Write-Info "PostgreSQL pronadjen u: $path"
                # Dodaj u PATH za ovu sesiju
                $env:Path += ";$path"
                $psqlVersion = & "$path\psql.exe" --version
                Write-Step "PostgreSQL verzija: $psqlVersion"
                $psqlFound = $true
                break
            }
        }
    }
    
    if (-not $psqlFound) {
        Write-ErrorMsg "PostgreSQL (psql) nije pronadjen!"
        Write-Output ""
        Write-Output "Molimo:"
        Write-Output "1. Instalirajte PostgreSQL 14+ sa: https://www.postgresql.org/download/"
        Write-Output "   ILI"
        Write-Output "2. Dodajte PostgreSQL\bin direktorij u PATH environment varijablu"
        Write-Output "   Primjer: C:\Program Files\PostgreSQL\16\bin"
        Write-Output ""
        Write-Output "Nakon instalacije, ponovno pokrenite skriptu."
        exit 1
    }
}

# Provjera Python
try {
    $pythonVersion = python --version 2>&1
    Write-Step "Python pronadjen: $pythonVersion"
} catch {
    Write-ErrorMsg "Python nije pronadjen! Molimo instalirajte Python 3.9+."
    Write-Output "Download: https://www.python.org/downloads/"
    exit 1
}

# Provjera Node.js
try {
    $nodeVersion = node --version 2>&1
    Write-Step "Node.js pronadjen: $nodeVersion"
} catch {
    Write-ErrorMsg "Node.js nije pronadjen! Molimo instalirajte Node.js 16+."
    Write-Output "Download: https://nodejs.org/"
    exit 1
}

# Provjera npm
try {
    $npmVersion = npm --version 2>&1
    Write-Step "npm pronadjen: v$npmVersion"
} catch {
    Write-ErrorMsg "npm nije pronadjen!"
    exit 1
}

Write-Output ""

# ============================================================
# POSTAVLJANJE BAZE PODATAKA
# ============================================================
if (-not $SkipDatabase) {
    # Privremeno postavi Continue za SQL naredbe (NOTICE poruke nisu greske)
    $ErrorActionPreference = "Continue"
    
    Write-Output "============================================================"
    Write-Output "   KORAK 1: Postavljanje baze podataka"
    Write-Output "============================================================"
    Write-Output ""

    # Trazi lozinku ako nije proslijedjena
    if ([string]::IsNullOrEmpty($PostgresPassword)) {
        $securePassword = Read-Host "Unesite lozinku za PostgreSQL korisnika '$PostgresUser'" -AsSecureString
        $PostgresPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
    }

    $env:PGPASSWORD = $PostgresPassword

    Write-Info "Kreiranje baze podataka '$DatabaseName'..."
    
    # Provjeri postoji li baza
    $checkDb = psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -lqt 2>&1 | Select-String $DatabaseName
    
    if ($checkDb) {
        if ($Force) {
            $response = "da"
        } else {
            $response = Read-Host "Baza '$DatabaseName' vec postoji. Zelite li je obrisati i kreirati iznova? (da/ne)"
        }
        if ($response -eq "da") {
            Write-Info "Brisanje postojece baze..."
            psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -c "DROP DATABASE IF EXISTS $DatabaseName;" 2>&1 | Out-Null
        } else {
            Write-Info "Preskachem kreiranje baze..."
            $SkipDatabaseCreate = $true
        }
    }

    if (-not $SkipDatabaseCreate) {
        # Kreiraj bazu
        psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -c "CREATE DATABASE $DatabaseName WITH ENCODING 'UTF8';" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Greska pri kreiranju baze podataka!"
            exit 1
        }
        Write-Step "Baza podataka kreirana"

        # Izvrsavanje SQL skripti
        $databasePath = Join-Path $ProjectRoot "database"

        Write-Info "Izvrsavanje 01_schema.sql..."
        $result = psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -d $DatabaseName -f "$databasePath\01_schema.sql" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Greska pri izvrsavanju 01_schema.sql!"
            Write-Output $result
            exit 1
        }
        Write-Step "Schema kreirana"

        Write-Info "Izvrsavanje 02_seed_data.sql..."
        $result = psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -d $DatabaseName -f "$databasePath\02_seed_data.sql" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Greska pri izvrsavanju 02_seed_data.sql!"
            Write-Output $result
            exit 1
        }
        Write-Step "Pocetni podaci uneseni"

        Write-Info "Izvrsavanje 03_functions_procedures.sql..."
        $result = psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -d $DatabaseName -f "$databasePath\03_functions_procedures.sql" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Greska pri izvrsavanju 03_functions_procedures.sql!"
            Write-Output $result
            exit 1
        }
        Write-Step "Funkcije i procedure kreirane"

        Write-Info "Izvrsavanje 04_advanced_features.sql..."
        $result = psql -h $PostgresHost -p $PostgresPort -U $PostgresUser -d $DatabaseName -f "$databasePath\04_advanced_features.sql" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Greska pri izvrsavanju 04_advanced_features.sql!"
            Write-Output $result
            exit 1
        }
        Write-Step "Napredne funkcionalnosti kreirane"
    }

    $env:PGPASSWORD = ""
    # Vrati ErrorActionPreference na Stop
    $ErrorActionPreference = "Stop"
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
    $venvPath = Join-Path $backendPath "venv"
    if (-not (Test-Path $venvPath)) {
        Write-Info "Kreiranje Python virtual environment..."
        python -m venv venv
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Greska pri kreiranju virtual environment!"
            Pop-Location
            exit 1
        }
        Write-Step "Virtual environment kreiran"
    } else {
        Write-Step "Virtual environment vec postoji"
    }

    # Instaliraj dependencies koristeci venv pip
    Write-Info "Instaliranje Python paketa..."
    $pipPath = Join-Path $venvPath "Scripts\pip.exe"
    & $pipPath install -r requirements.txt --quiet
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorMsg "Greska pri instaliranju Python paketa!"
        Pop-Location
        exit 1
    }
    Write-Step "Python paketi instalirani"

    # Kreiraj .env ako ne postoji
    $envFile = Join-Path $backendPath ".env"
    if (-not (Test-Path $envFile)) {
        Write-Info "Kreiranje .env datoteke..."
        # Generiraj sigurni SECRET_KEY
        $secretKey = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 64 | ForEach-Object {[char]$_})
        
        $envLines = @(
            "# ==========================================="
            "# ENVIRONMENT VARIABLES"
            "# ==========================================="
            ""
            "# Database Configuration"
            "DATABASE_HOST=$PostgresHost"
            "DATABASE_PORT=$PostgresPort"
            "DATABASE_NAME=$DatabaseName"
            "DATABASE_USER=$PostgresUser"
            "DATABASE_PASSWORD=$PostgresPassword"
            ""
            "# JWT Configuration"
            "SECRET_KEY=$secretKey"
            "ALGORITHM=HS256"
            "ACCESS_TOKEN_EXPIRE_MINUTES=30"
        )
        $envLines -join "`n" | Out-File -FilePath $envFile -Encoding UTF8 -NoNewline
        Write-Step ".env datoteka kreirana"
    } else {
        Write-Step ".env datoteka vec postoji"
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

    # Privremeno postavi Continue za npm (warning poruke nisu greske)
    $ErrorActionPreference = "Continue"
    
    # Uvijek pokreni npm install za provjeru azurnosti paketa
    Write-Info "Instaliranje npm paketa (ovo moze potrajati)..."
    $result = npm install 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorMsg "Greska pri instaliranju npm paketa!"
        Write-Output $result
        Pop-Location
        exit 1
    }
    Write-Step "npm paketi instalirani"
    
    # Vrati ErrorActionPreference
    $ErrorActionPreference = "Stop"

    Pop-Location
    Write-Output ""
}

# ============================================================
# ZAVRSETAK
# ============================================================
Write-Output "============================================================"
Write-Output "   INSTALACIJA USPJESNO ZAVRSENA!"
Write-Output "============================================================"
Write-Output ""
Write-Output "Za pokretanje aplikacije:"
Write-Output ""
Write-Output "  Koristite skriptu: .\setup\start.ps1"
Write-Output ""
Write-Output "  Ili rucno:"
Write-Output "  1. Backend (Terminal 1):"
Write-Output "     cd backend"
Write-Output "     .\venv\Scripts\activate"
Write-Output "     python -m uvicorn app.main:app --reload"
Write-Output ""
Write-Output "  2. Frontend (Terminal 2):"
Write-Output "     cd frontend"
Write-Output "     npm start"
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
