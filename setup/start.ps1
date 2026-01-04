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

if (-not $FrontendOnly) {
    Write-Output "Pokretanje Backend servera..."
    
    $backendPath = Join-Path $ProjectRoot "backend"
    
    Start-Process powershell -ArgumentList "-NoExit", "-Command", @"
        Set-Location '$backendPath'
        & '.\venv\Scripts\Activate.ps1'
        Write-Host 'Backend pokrenut na http://localhost:8000' -ForegroundColor Green
        Write-Host 'API Dokumentacija: http://localhost:8000/docs' -ForegroundColor Cyan
        python -m uvicorn app.main:app --reload
"@
}

if (-not $BackendOnly) {
    # Pričekaj malo da se backend pokrene
    Start-Sleep -Seconds 3
    
    Write-Output "Pokretanje Frontend servera..."
    
    $frontendPath = Join-Path $ProjectRoot "frontend"
    
    Start-Process powershell -ArgumentList "-NoExit", "-Command", @"
        Set-Location '$frontendPath'
        Write-Host 'Frontend pokrenut na http://localhost:3000' -ForegroundColor Green
        npm start
"@
}

Write-Output ""
Write-Output "Serveri se pokreću u zasebnim prozorima."
Write-Output ""
Write-Output "Pristupni podaci:"
Write-Output "  Admin:    admin / Admin123!"
Write-Output "  Manager:  ivan_manager / IvanM2024!"
Write-Output "  Employee: marko_dev / Marko2024!"
Write-Output ""
Write-Output "============================================================"
