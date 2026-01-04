"""
FastAPI Main Application
Interni sustav za upravljanje zaposlenicima i zadacima - Backend API
"""

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import time

# Import routera
from .routers import auth, users, tasks, roles, audit


# Kreiranje FastAPI aplikacije
app = FastAPI(
    title="Interni sustav za upravljanje zaposlenicima i zadacima",
    description="""
## Backend API za upravljanje zaposlenicima i zadacima

Ovaj API demonstrira korištenje naprednih mogućnosti PostgreSQL baze podataka:

### Baza podataka koristi:
- **ENUM tipovi**: task_status, task_priority, audit_action
- **COMPOSITE tipovi**: timestamp_metadata, address_info
- **Domene**: email_address, username_type za validaciju
- **11 funkcija**: validate_email, user_has_permission, get_user_tasks, itd.
- **10 procedura**: create_user, create_task, assign_role, itd.
- **7 triggera**: audit logovi, auto-update timestamps
- **5 pogleda**: v_users_with_roles, v_tasks_details, itd.

### RBAC Model:
- **ADMIN**: Puni pristup sustavu
- **MANAGER**: Upravljanje timom i zadacima
- **EMPLOYEE**: Pregled i rad s vlastitim zadacima

### Autentikacija:
- JWT tokeni za autentikaciju
- Bcrypt za hashiranje lozinki
- Evidencija svih pokušaja prijave
    """,
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)


# CORS Middleware - dozvoljavamo sve za razvoj
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Middleware za mjerenje vremena odgovora
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response


# Exception handler za generičke greške
@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={
            "message": "Interna greška servera",
            "detail": str(exc)
        }
    )


# Uključi routere
app.include_router(auth.router, prefix="/api")
app.include_router(users.router, prefix="/api")
app.include_router(tasks.router, prefix="/api")
app.include_router(roles.router, prefix="/api")
app.include_router(audit.router, prefix="/api")


# Root endpoint
@app.get("/", tags=["Root"])
async def root():
    """
    Root endpoint - informacije o API-ju
    """
    return {
        "name": "Interni sustav za upravljanje zaposlenicima i zadacima",
        "version": "1.0.0",
        "description": "Backend API za TBP projekt",
        "documentation": "/docs",
        "endpoints": {
            "auth": "/api/auth",
            "users": "/api/users",
            "tasks": "/api/tasks",
            "roles": "/api/roles",
            "audit": "/api/audit"
        }
    }


# Health check endpoint
@app.get("/health", tags=["Health"])
async def health_check():
    """
    Provjera zdravlja aplikacije
    """
    from .database import get_connection
    
    try:
        conn = get_connection()
        with conn.cursor() as cur:
            cur.execute("SELECT 1")
        conn.close()
        db_status = "healthy"
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"
    
    return {
        "status": "running",
        "database": db_status
    }


# Informacije o bazi podataka
@app.get("/api/database-info", tags=["Database"])
async def database_info():
    """
    Informacije o PostgreSQL bazi podataka.
    Demonstrira napredne mogućnosti korištene u projektu.
    """
    return {
        "schema": "employee_management",
        "postgresql_features": {
            "enum_types": [
                "task_status (NEW, IN_PROGRESS, ON_HOLD, COMPLETED, CANCELLED)",
                "task_priority (LOW, MEDIUM, HIGH, URGENT)",
                "audit_action (INSERT, UPDATE, DELETE)"
            ],
            "composite_types": [
                "timestamp_metadata (created_at, updated_at)",
                "address_info (street, city, postal_code, country)"
            ],
            "domains": [
                "email_address - validacija email formata",
                "username_type - validacija korisničkog imena"
            ]
        },
        "tables": [
            "users", "roles", "permissions", "tasks",
            "user_roles", "role_permissions", 
            "login_events", "audit_log"
        ],
        "functions": [
            "validate_email()", "generate_slug()", "check_password_strength()",
            "user_has_permission()", "get_user_permissions()", "get_user_roles()",
            "is_manager_of()", "get_team_members()",
            "get_user_tasks()", "get_task_statistics()",
            "log_login_attempt()"
        ],
        "procedures": [
            "create_user()", "update_user()", "deactivate_user()",
            "create_task()", "update_task_status()", "assign_task()",
            "assign_role()", "revoke_role()",
            "cleanup_old_audit_logs()", "cleanup_old_login_events()"
        ],
        "triggers": [
            "trg_audit_users - audit log za korisnike",
            "trg_audit_tasks - audit log za zadatke",
            "trg_audit_user_roles - audit log za dodjelu uloga",
            "trg_users_updated_at - auto-update timestamp",
            "trg_roles_updated_at - auto-update timestamp",
            "trg_tasks_updated_at - auto-update timestamp",
            "trg_validate_manager_hierarchy - validacija hijerarhije"
        ],
        "views": [
            "v_users_with_roles - korisnici s ulogama",
            "v_roles_with_permissions - uloge s permisijama",
            "v_tasks_details - detaljni prikaz zadataka",
            "v_user_statistics - statistika korisnika",
            "v_manager_team - prikaz timova"
        ]
    }


# Startup event
@app.on_event("startup")
async def startup_event():
    """
    Izvršava se pri pokretanju aplikacije
    """
    print("=" * 60)
    print("  Interni sustav za upravljanje zaposlenicima i zadacima")
    print("  Backend API pokrenut!")
    print("=" * 60)
    print("  Dokumentacija: http://localhost:8000/docs")
    print("  ReDoc: http://localhost:8000/redoc")
    print("=" * 60)


# Shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    """
    Izvršava se pri zaustavljanju aplikacije
    """
    print("Backend API zaustavljen.")
