"""
Autentikacija i Autorizacija Modul
JWT token bazirana autentikacija s RBAC provjerama
"""

from datetime import datetime, timedelta
from typing import Optional
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
import bcrypt
from .config import get_settings
from .database import get_db_dependency
from .schemas import TokenData


settings = get_settings()

# OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/login")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verificira lozinku protiv hash-a"""
    password_bytes = plain_password.encode('utf-8')
    hash_bytes = hashed_password.encode('utf-8')
    return bcrypt.checkpw(password_bytes, hash_bytes)


def get_password_hash(password: str) -> str:
    """Generira bcrypt hash lozinke"""
    password_bytes = password.encode('utf-8')
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password_bytes, salt).decode('utf-8')


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Kreira JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.access_token_expire_minutes)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)
    return encoded_jwt


def decode_token(token: str) -> Optional[TokenData]:
    """Dekodira JWT token"""
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        username: str = payload.get("sub")
        user_id: int = payload.get("user_id")
        if username is None:
            return None
        return TokenData(username=username, user_id=user_id)
    except JWTError:
        return None


def authenticate_user(conn, username: str, password: str) -> Optional[dict]:
    """
    Autenticira korisnika iz baze podataka
    Koristi funkcije iz baze za provjeru
    """
    with conn.cursor() as cur:
        # Dohvati korisnika
        cur.execute("""
            SELECT user_id, username, email, password_hash, 
                   first_name, last_name, is_active
            FROM users 
            WHERE username = %s
        """, (username,))
        user = cur.fetchone()
        
        if not user:
            return None
        
        if not user['is_active']:
            return None
            
        if not verify_password(password, user['password_hash']):
            return None
            
        return dict(user)


def log_login_attempt(conn, username: str, ip_address: str, 
                      user_agent: str, success: bool, 
                      failure_reason: str = None, user_id: int = None):
    """Logira pokusaj prijave u bazu (koristi log_login_attempt funkciju iz baze)"""
    with conn.cursor() as cur:
        cur.execute("""
            SELECT log_login_attempt(%s, %s::INET, %s, %s, %s)
        """, (username, ip_address, user_agent, success, failure_reason))


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    conn = Depends(get_db_dependency)
) -> dict:
    """
    Dependency za dohvacanje trenutnog korisnika iz tokena
    Koristi se u protected rutama
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Nevazece autentikacijske vjerodajnice",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    token_data = decode_token(token)
    if token_data is None:
        raise credentials_exception
    
    with conn.cursor() as cur:
        cur.execute("""
            SELECT user_id, username, email, first_name, last_name, 
                   is_active, manager_id, created_at, updated_at
            FROM users 
            WHERE username = %s AND is_active = TRUE
        """, (token_data.username,))
        user = cur.fetchone()
    
    if user is None:
        raise credentials_exception
    
    return dict(user)


async def get_current_active_user(
    current_user: dict = Depends(get_current_user)
) -> dict:
    """Osigurava da je korisnik aktivan"""
    if not current_user.get('is_active', False):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Korisnik je deaktiviran"
        )
    return current_user


def check_permission(conn, user_id: int, permission_code: str) -> bool:
    """
    Provjerava da li korisnik ima odredjenu permisiju
    Koristi user_has_permission funkciju iz baze
    """
    with conn.cursor() as cur:
        cur.execute(
            "SELECT user_has_permission(%s, %s) as has_permission",
            (user_id, permission_code)
        )
        result = cur.fetchone()
        return result['has_permission'] if result else False


def require_permission(permission_code: str):
    """
    Dependency factory za provjeru permisija
    Koristi se kao: Depends(require_permission("TASK_CREATE"))
    """
    async def permission_checker(
        current_user: dict = Depends(get_current_active_user),
        conn = Depends(get_db_dependency)
    ) -> dict:
        if not check_permission(conn, current_user['user_id'], permission_code):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Nemate dozvolu za ovu akciju (potrebno: {permission_code})"
            )
        return current_user
    return permission_checker


def get_user_permissions_list(conn, user_id: int) -> list:
    """Dohvaca sve permisije korisnika koristeci funkciju iz baze"""
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM get_user_permissions(%s)", (user_id,))
        return [dict(row) for row in cur.fetchall()]


def get_user_roles_list(conn, user_id: int) -> list:
    """Dohvaca sve uloge korisnika koristeci funkciju iz baze"""
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM get_user_roles(%s)", (user_id,))
        return [dict(row) for row in cur.fetchall()]


def is_admin(conn, user_id: int) -> bool:
    """Provjerava da li je korisnik admin"""
    roles = get_user_roles_list(conn, user_id)
    return any(role['role_name'] == 'ADMIN' for role in roles)


def is_manager_of_user(conn, manager_id: int, employee_id: int) -> bool:
    """Provjerava da li je prvi korisnik manager drugog (koristi funkciju iz baze)"""
    with conn.cursor() as cur:
        cur.execute(
            "SELECT is_manager_of(%s, %s) as is_manager",
            (manager_id, employee_id)
        )
        result = cur.fetchone()
        return result['is_manager'] if result else False
