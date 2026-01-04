@echo off
REM ============================================================
REM SKRIPTA ZA POKRETANJE - Backend i Frontend
REM ============================================================

REM Postavi putanju do root foldera
set "PROJECT_ROOT=%~dp0.."

echo.
echo ============================================================
echo    Pokretanje aplikacije
echo ============================================================
echo.

echo Pokretanje Backend servera...
start "Backend Server" cmd /k "cd /d "%PROJECT_ROOT%\backend" && venv\Scripts\activate && python -m uvicorn app.main:app --reload"

echo Cekam 3 sekunde da se backend pokrene...
timeout /t 3 /nobreak >nul

echo Pokretanje Frontend servera...
start "Frontend Server" cmd /k "cd /d "%PROJECT_ROOT%\frontend" && npm start"

echo.
echo Serveri se pokrecu u zasebnim prozorima.
echo.
echo Pristupni podaci:
echo   Admin:    admin / Admin123!
echo   Manager:  ivan_manager / IvanM2024!
echo   Employee: marko_dev / Marko2024!
echo.
echo Backend: http://localhost:8000
echo Frontend: http://localhost:3000
echo API Docs: http://localhost:8000/docs
echo.
echo ============================================================
pause
