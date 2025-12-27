"""
Users Router - Upravljanje korisnicima
CRUD operacije, statistike, timovi
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional

from ..database import get_db_dependency
from ..auth import (
    get_current_active_user, require_permission, get_password_hash,
    check_permission, is_manager_of_user, is_admin
)
from ..schemas import (
    UserCreate, UserUpdate, UserResponse, UserWithRoles,
    UserStatistics, TeamMember, MessageResponse, TaskStatistics
)


router = APIRouter(prefix="/users", tags=["Korisnici"])


@router.get("", response_model=List[UserWithRoles], summary="Dohvati sve korisnike")
async def get_all_users(
    is_active: Optional[bool] = Query(None, description="Filter po aktivnosti"),
    current_user: dict = Depends(require_permission("USER_READ_ALL")),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca sve korisnike sustava.
    
    Koristi PostgreSQL view:
    - v_users_with_roles
    
    Potrebna permisija: USER_READ_ALL
    """
    with conn.cursor() as cur:
        if is_active is not None:
            cur.execute("""
                SELECT * FROM v_users_with_roles 
                WHERE is_active = %s
                ORDER BY last_name, first_name
            """, (is_active,))
        else:
            cur.execute("""
                SELECT * FROM v_users_with_roles 
                ORDER BY last_name, first_name
            """)
        users = cur.fetchall()
    
    result = []
    for user in users:
        result.append(UserWithRoles(
            user_id=user['user_id'],
            username=user['username'],
            email=user['email'],
            first_name=user['first_name'],
            last_name=user['last_name'],
            is_active=user['is_active'],
            manager_id=None,
            created_at=user['created_at'],
            updated_at=user['updated_at'],
            roles=user['roles'] if user['roles'] else [],
            manager_username=user['manager_username'],
            manager_full_name=user['manager_full_name']
        ))
    
    return result


@router.get("/statistics", response_model=List[UserStatistics], 
            summary="Statistike svih korisnika")
async def get_all_user_statistics(
    current_user: dict = Depends(require_permission("USER_READ_ALL")),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca statistike aktivnosti za sve korisnike.
    
    Koristi PostgreSQL view:
    - v_user_statistics
    
    Potrebna permisija: USER_READ_ALL
    """
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM v_user_statistics ORDER BY full_name")
        stats = cur.fetchall()
    
    return [UserStatistics(**stat) for stat in stats]


@router.get("/{user_id}", response_model=UserWithRoles, summary="Dohvati korisnika")
async def get_user(
    user_id: int,
    current_user: dict = Depends(get_current_active_user),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca pojedinog korisnika po ID-u.
    
    Koristi PostgreSQL view:
    - v_users_with_roles
    
    Korisnik moze vidjeti:
    - Vlastite podatke
    - Podatke clanova svog tima (ako je manager)
    - Sve korisnike (ako ima USER_READ_ALL permisiju)
    """
    # Provjera pristupa
    can_view = (
        user_id == current_user['user_id'] or  # Vlastiti podaci
        is_manager_of_user(conn, current_user['user_id'], user_id) or  # Clan tima
        check_permission(conn, current_user['user_id'], 'USER_READ_ALL')  # Permisija
    )
    
    if not can_view:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Nemate pristup podacima ovog korisnika"
        )
    
    with conn.cursor() as cur:
        cur.execute("""
            SELECT * FROM v_users_with_roles 
            WHERE user_id = %s
        """, (user_id,))
        user = cur.fetchone()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Korisnik nije pronadjen"
        )
    
    return UserWithRoles(
        user_id=user['user_id'],
        username=user['username'],
        email=user['email'],
        first_name=user['first_name'],
        last_name=user['last_name'],
        is_active=user['is_active'],
        manager_id=None,
        created_at=user['created_at'],
        updated_at=user['updated_at'],
        roles=user['roles'] if user['roles'] else [],
        manager_username=user['manager_username'],
        manager_full_name=user['manager_full_name']
    )


@router.get("/{user_id}/statistics", response_model=TaskStatistics,
            summary="Statistika zadataka korisnika")
async def get_user_task_statistics(
    user_id: int,
    current_user: dict = Depends(get_current_active_user),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca statistiku zadataka za korisnika.
    
    Koristi PostgreSQL funkciju:
    - get_task_statistics()
    """
    # Provjera pristupa
    can_view = (
        user_id == current_user['user_id'] or
        is_manager_of_user(conn, current_user['user_id'], user_id) or
        check_permission(conn, current_user['user_id'], 'USER_READ_ALL')
    )
    
    if not can_view:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Nemate pristup statistikama ovog korisnika"
        )
    
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM get_task_statistics(%s)", (user_id,))
        stats = cur.fetchone()
    
    if not stats:
        return TaskStatistics(
            total_tasks=0, completed_tasks=0, in_progress_tasks=0,
            overdue_tasks=0, completion_rate=0.0
        )
    
    return TaskStatistics(**stats)


@router.get("/{user_id}/team", response_model=List[TeamMember],
            summary="Clanovi tima")
async def get_team_members(
    user_id: int,
    current_user: dict = Depends(get_current_active_user),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca clanove tima za managera.
    
    Koristi PostgreSQL funkciju:
    - get_team_members()
    """
    # Samo manager ili admin moze vidjeti tim
    if user_id != current_user['user_id'] and not is_admin(conn, current_user['user_id']):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Nemate pristup ovom timu"
        )
    
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM get_team_members(%s)", (user_id,))
        members = cur.fetchall()
    
    return [TeamMember(**member) for member in members]


@router.post("", response_model=MessageResponse, summary="Kreiraj korisnika")
async def create_user(
    user_data: UserCreate,
    current_user: dict = Depends(require_permission("USER_CREATE")),
    conn = Depends(get_db_dependency)
):
    """
    Kreira novog korisnika.
    
    Koristi PostgreSQL proceduru:
    - create_user()
    
    Potrebna permisija: USER_CREATE
    """
    password_hash = get_password_hash(user_data.password)
    
    try:
        with conn.cursor() as cur:
            cur.execute("""
                CALL create_user(
                    %s, %s, %s, %s, %s, %s, %s, %s, NULL
                )
            """, (
                user_data.username,
                user_data.email,
                password_hash,
                user_data.first_name,
                user_data.last_name,
                user_data.manager_id,
                user_data.role_name,
                current_user['user_id']
            ))
            
            # Dohvati ID novog korisnika
            cur.execute("""
                SELECT user_id FROM users 
                WHERE username = %s
            """, (user_data.username,))
            new_user = cur.fetchone()
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    return MessageResponse(
        message=f"Korisnik '{user_data.username}' uspjesno kreiran s ID {new_user['user_id']}",
        success=True
    )


@router.put("/{user_id}", response_model=MessageResponse, summary="Azuriraj korisnika")
async def update_user(
    user_id: int,
    user_data: UserUpdate,
    current_user: dict = Depends(get_current_active_user),
    conn = Depends(get_db_dependency)
):
    """
    Azurira podatke korisnika.
    
    Koristi PostgreSQL proceduru:
    - update_user()
    
    Korisnik moze azurirati:
    - Vlastite podatke (osim is_active i manager_id)
    - Sve podatke (ako ima USER_UPDATE permisiju)
    """
    is_self = user_id == current_user['user_id']
    has_permission = check_permission(conn, current_user['user_id'], 'USER_UPDATE')
    
    if not is_self and not has_permission:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Nemate dozvolu za azuriranje ovog korisnika"
        )
    
    # Ako korisnik azurira sebe, ne moze promijeniti is_active i manager_id
    if is_self and not has_permission:
        if user_data.is_active is not None or user_data.manager_id is not None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Ne mozete promijeniti vlastiti status ili managera"
            )
    
    try:
        with conn.cursor() as cur:
            cur.execute("""
                CALL update_user(%s, %s, %s, %s, %s, %s, %s)
            """, (
                user_id,
                user_data.first_name,
                user_data.last_name,
                user_data.email,
                user_data.manager_id,
                user_data.is_active,
                current_user['user_id']
            ))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    return MessageResponse(
        message=f"Korisnik ID {user_id} uspjesno azuriran",
        success=True
    )


@router.delete("/{user_id}", response_model=MessageResponse, 
               summary="Deaktiviraj korisnika")
async def deactivate_user(
    user_id: int,
    current_user: dict = Depends(require_permission("USER_DEACTIVATE")),
    conn = Depends(get_db_dependency)
):
    """
    Deaktivira korisnika i ponistava njegove nezavrsene zadatke.
    
    Koristi PostgreSQL proceduru:
    - deactivate_user()
    
    Potrebna permisija: USER_DEACTIVATE
    """
    if user_id == current_user['user_id']:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ne mozete deaktivirati vlastiti racun"
        )
    
    try:
        with conn.cursor() as cur:
            cur.execute("""
                CALL deactivate_user(%s, %s)
            """, (user_id, current_user['user_id']))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    return MessageResponse(
        message=f"Korisnik ID {user_id} uspjesno deaktiviran",
        success=True
    )
