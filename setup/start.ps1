# ============================================================
# SKRIPTA ZA POKRETANJE - Backend i Frontend
# ============================================================

param(
    [switch]$BackendOnly,
    [switch]$FrontendOnly
)

# Putanja do root foldera projekta
$ProjectRoot = Split-Path -Parent $PSScriptRoot

Write-Output ""
Write-Output "============================================================"
Write-Output "   Pokretanje aplikacije"
Write-Output "============================================================"
Write-Output ""

# Provjeri jesu li instalirani paketi
$backendPath = Join-Path $ProjectRoot "backend"
$frontendPath = Join-Path $ProjectRoot "frontend"
$venvPath = Join-Path $backendPath "venv"
$nodeModulesPath = Join-Path $frontendPath "node_modules"

# Provjera backend venv
if (-not (Test-Path $venvPath)) {
    Write-Output "Backend nije instaliran. Pokrecem install.ps1..."
    & (Join-Path $PSScriptRoot "install.ps1") -SkipDatabase
    if ($LASTEXITCODE -ne 0) {
        Write-Output "Greska pri instalaciji! Molimo pokrenite install.ps1 rucno."
        exit 1
    }
}

# Provjera frontend node_modules
if (-not (Test-Path $nodeModulesPath)) {
    Write-Output "Frontend paketi nisu instalirani. Instaliram..."
    Push-Location $frontendPath
    npm install
    Pop-Location
}

if (-not $FrontendOnly) {
    Write-Output "Pokretanje Backend servera..."
    
    $pythonPath = Join-Path $venvPath "Scripts\python.exe"
    
    Start-Process powershell -ArgumentList "-NoExit", "-Command", @"
        Set-Location '$backendPath'
        Write-Host 'Backend pokrenut na http://localhost:8000' -ForegroundColor Green
        Write-Host 'API Dokumentacija: http://localhost:8000/docs' -ForegroundColor Cyan
        & '$pythonPath' -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
"@
}

if (-not $BackendOnly) {
    # Pričekaj malo da se backend pokrene
    Start-Sleep -Seconds 3
    
    Write-Output "Pokretanje Frontend servera..."
    
    Start-Process powershell -ArgumentList "-NoExit", "-Command", @"
        Set-Location '$frontendPath'
        Write-Host 'Frontend pokrenut na http://localhost:3000' -ForegroundColor Green
        npm start
"@
}

Write-Output ""
Write-Output "Serveri se pokrecu u zasebnim prozorima."
Write-Output ""
Write-Output "Pristupni podaci:"
Write-Output "  Admin:    admin / Admin123!"
Write-Output "  Manager:  ivan_manager / IvanM2024!"
Write-Output "  Employee: marko_dev / Marko2024!"
Write-Output ""
Write-Output "============================================================"
