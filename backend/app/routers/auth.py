"""
Auth Router - Autentikacija endpoints
Prijava, odjava, informacije o trenutnom korisniku
"""

from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordRequestForm
from datetime import timedelta
from typing import List

from ..database import get_db_dependency
from ..auth import (
    authenticate_user, create_access_token, get_current_active_user,
    get_password_hash, log_login_attempt, get_user_permissions_list,
    get_user_roles_list
)
from ..schemas import (
    Token, LoginRequest, UserResponse, UserWithRoles,
    UserPermission, MessageResponse
)
from ..config import get_settings


router = APIRouter(prefix="/auth", tags=["Autentikacija"])
settings = get_settings()


@router.post("/login", response_model=Token, summary="Prijava korisnika")
async def login(
    request: Request,
    form_data: OAuth2PasswordRequestForm = Depends(),
    conn = Depends(get_db_dependency)
):
    """
    Prijava korisnika u sustav.
    
    Koristi PostgreSQL funkcije:
    - log_login_attempt() za evidenciju prijava
    
    Returns:
        JWT access token za autentikaciju
    """
    # Dohvati IP adresu i user agent
    client_ip = request.client.host if request.client else "0.0.0.0"
    user_agent = request.headers.get("user-agent", "Unknown")
    
    # DEBUG: Ispiši što primamo
    print(f"🔍 LOGIN ATTEMPT: username={form_data.username}, has_password={bool(form_data.password)}")
    print(f"🔍 Headers: Authorization={request.headers.get('authorization', 'NONE')}")
    
    # Pokusaj autentikacije
    user = authenticate_user(conn, form_data.username, form_data.password)
    
    if not user:
        # Logiraj neuspjeli pokusaj
        log_login_attempt(
            conn, form_data.username, client_ip, user_agent,
            success=False, failure_reason="INVALID_CREDENTIALS"
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Neispravno korisnicko ime ili lozinka",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Logiraj uspjesnu prijavu
    log_login_attempt(
        conn, form_data.username, client_ip, user_agent,
        success=True, user_id=user['user_id']
    )
    
    # Kreiraj token
    access_token = create_access_token(
        data={"sub": user['username'], "user_id": user['user_id']},
        expires_delta=timedelta(minutes=settings.access_token_expire_minutes)
    )
    
    return Token(access_token=access_token, token_type="bearer")


@router.post("/logout", response_model=MessageResponse, summary="Odjava korisnika")
async def logout(current_user: dict = Depends(get_current_active_user)):
    """
    Odjava korisnika iz sustava.
    
    Napomena: JWT token je stateless, pa "logout" zapravo ne mora nista raditi na backendu.
    Frontend jednostavno brise token iz localStorage.
    Ovaj endpoint postoji samo za API konzistentnost.
    """
    return MessageResponse(message=f"Korisnik {current_user['username']} uspjesno odjavljen")


@router.get("/me", response_model=UserWithRoles, summary="Trenutni korisnik")
async def get_current_user_info(
    current_user: dict = Depends(get_current_active_user),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca informacije o trenutno prijavljenom korisniku.
    
    Koristi PostgreSQL funkcije:
    - get_user_roles() za dohvacanje uloga
    - get_user_permissions() za dohvacanje permisija
    
    Koristi PostgreSQL view:
    - v_users_with_roles
    """
    with conn.cursor() as cur:
        cur.execute("""
            SELECT * FROM v_users_with_roles 
            WHERE user_id = %s
        """, (current_user['user_id'],))
        user_data = cur.fetchone()
    
    if not user_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Korisnik nije pronadjen"
        )
    
    # Dohvati permisije
    permissions = get_user_permissions_list(conn, current_user['user_id'])
    
    return UserWithRoles(
        user_id=user_data['user_id'],
        username=user_data['username'],
        email=user_data['email'],
        first_name=user_data['first_name'],
        last_name=user_data['last_name'],
        is_active=user_data['is_active'],
        manager_id=None,  # Nije u view-u direktno
        created_at=user_data['created_at'],
        updated_at=user_data['updated_at'],
        roles=user_data['roles'] if user_data['roles'] else [],
        permissions=permissions,
        manager_username=user_data['manager_username'],
        manager_full_name=user_data['manager_full_name']
    )


@router.get("/me/permissions", response_model=List[UserPermission], 
            summary="Permisije trenutnog korisnika")
async def get_my_permissions(
    current_user: dict = Depends(get_current_active_user),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca sve permisije trenutno prijavljenog korisnika.
    
    Koristi PostgreSQL funkciju:
    - get_user_permissions()
    """
    permissions = get_user_permissions_list(conn, current_user['user_id'])
    return [UserPermission(**perm) for perm in permissions]


@router.get("/me/roles", summary="Uloge trenutnog korisnika")
async def get_my_roles(
    current_user: dict = Depends(get_current_active_user),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca sve uloge trenutno prijavljenog korisnika.
    
    Koristi PostgreSQL funkciju:
    - get_user_roles()
    """
    roles = get_user_roles_list(conn, current_user['user_id'])
    return roles


@router.post("/check-permission/{permission_code}", summary="Provjeri permisiju")
async def check_my_permission(
    permission_code: str,
    current_user: dict = Depends(get_current_active_user),
    conn = Depends(get_db_dependency)
):
    """
    Provjerava da li trenutni korisnik ima odredjenu permisiju.
    
    Koristi PostgreSQL funkciju:
    - user_has_permission()
    """
    with conn.cursor() as cur:
        cur.execute(
            "SELECT user_has_permission(%s, %s) as has_permission",
            (current_user['user_id'], permission_code)
        )
        result = cur.fetchone()
    
    return {
        "permission_code": permission_code,
        "has_permission": result['has_permission'] if result else False
    }


@router.post("/validate-password", summary="Provjeri jacinu lozinke")
async def validate_password_strength(
    password: str,
    conn = Depends(get_db_dependency)
):
    """
    Provjerava jacinu lozinke prema sigurnosnim kriterijima.
    
    Koristi PostgreSQL funkciju:
    - check_password_strength()
    """
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM check_password_strength(%s)", (password,))
        result = cur.fetchone()
    
    return {
        "is_valid": result['is_valid'],
        "message": result['message']
    }
