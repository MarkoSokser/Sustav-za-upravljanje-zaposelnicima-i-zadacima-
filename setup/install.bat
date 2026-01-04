@echo off
REM ============================================================
REM INSTALACIJSKA SKRIPTA - Interni sustav za upravljanje zadacima
REM ============================================================
REM Za korisnike koji nemaju PowerShell ili preferiraju batch
REM ============================================================

echo.
echo ============================================================
echo    INSTALACIJA - Interni sustav za upravljanje zadacima
echo ============================================================
echo.

REM Postavi putanju do root foldera (jedan nivo gore)
set "PROJECT_ROOT=%~dp0.."

REM Provjera preduvjeta
echo Provjera preduvjeta...

where psql >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [GRESKA] PostgreSQL nije pronaden! Instalirajte PostgreSQL 14+.
    echo Download: https://www.postgresql.org/download/
    pause
    exit /b 1
)
echo [OK] PostgreSQL pronaden

where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [GRESKA] Python nije pronaden! Instalirajte Python 3.9+.
    echo Download: https://www.python.org/downloads/
    pause
    exit /b 1
)
echo [OK] Python pronaden

where node >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [GRESKA] Node.js nije pronaden! Instalirajte Node.js 16+.
    echo Download: https://nodejs.org/
    pause
    exit /b 1
)
echo [OK] Node.js pronaden

echo.
echo ============================================================
echo    KORAK 1: Postavljanje baze podataka
echo ============================================================
echo.

set /p PGUSER="Unesite PostgreSQL korisnika (default: postgres): " || set PGUSER=postgres
if "%PGUSER%"=="" set PGUSER=postgres

set /p PGPASSWORD="Unesite lozinku za korisnika %PGUSER%: "

set DBNAME=interni_sustav
set PGHOST=localhost
set PGPORT=5432

echo.
echo Kreiranje baze podataka '%DBNAME%'...

psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -c "CREATE DATABASE %DBNAME% WITH ENCODING 'UTF8';" 2>nul
if %ERRORLEVEL% neq 0 (
    echo Baza mozda vec postoji, nastavljam...
)

echo Izvrsavanje SQL skripti...

psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %DBNAME% -f "%PROJECT_ROOT%\database\01_schema.sql"
if %ERRORLEVEL% neq 0 (
    echo [GRESKA] Greska pri izvrsavanju 01_schema.sql!
    pause
    exit /b 1
)
echo [OK] Schema kreirana

psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %DBNAME% -f "%PROJECT_ROOT%\database\02_seed_data.sql"
if %ERRORLEVEL% neq 0 (
    echo [GRESKA] Greska pri izvrsavanju 02_seed_data.sql!
    pause
    exit /b 1
)
echo [OK] Pocetni podaci uneseni

psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %DBNAME% -f "%PROJECT_ROOT%\database\03_functions_procedures.sql"
if %ERRORLEVEL% neq 0 (
    echo [GRESKA] Greska pri izvrsavanju 03_functions_procedures.sql!
    pause
    exit /b 1
)
echo [OK] Funkcije i procedure kreirane

set PGPASSWORD=

echo.
echo ============================================================
echo    KORAK 2: Postavljanje Backend-a
echo ============================================================
echo.

cd /d "%PROJECT_ROOT%\backend"

if not exist "venv" (
    echo Kreiranje Python virtual environment...
    python -m venv venv
)
echo [OK] Virtual environment spreman

echo Instaliranje Python paketa...
call venv\Scripts\pip.exe install -r requirements.txt --quiet
if %ERRORLEVEL% neq 0 (
    echo [GRESKA] Greska pri instaliranju Python paketa!
    cd /d "%PROJECT_ROOT%"
    pause
    exit /b 1
)
echo [OK] Python paketi instalirani

cd /d "%PROJECT_ROOT%"

echo.
echo ============================================================
echo    KORAK 3: Postavljanje Frontend-a
echo ============================================================
echo.

cd /d "%PROJECT_ROOT%\frontend"

if not exist "node_modules" (
    echo Instaliranje npm paketa (ovo moze potrajati)...
    call npm install --silent
    if %ERRORLEVEL% neq 0 (
        echo [GRESKA] Greska pri instaliranju npm paketa!
        cd /d "%PROJECT_ROOT%"
        pause
        exit /b 1
    )
)
echo [OK] npm paketi instalirani

cd /d "%PROJECT_ROOT%"

echo.
echo ============================================================
echo    INSTALACIJA USPJESNO ZAVRSENA!
echo ============================================================
echo.
echo Za pokretanje aplikacije koristite: setup\start.bat
echo.
echo Pristupni podaci:
echo   Admin:    admin / Admin123!
echo   Manager:  ivan_manager / IvanM2024!
echo   Employee: marko_dev / Marko2024!
echo.
echo Aplikacija: http://localhost:3000
echo API Docs:   http://localhost:8000/docs
echo.
pause
