"""
Roles Router - Upravljanje ulogama i permisijama
CRUD operacije za uloge, dodjela/uklanjanje uloga korisnicima
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List

from ..database import get_db_dependency
from ..auth import get_current_active_user, require_permission
from ..schemas import (
    RoleResponse, RoleWithPermissions, RoleCreate,
    RoleAssignment, PermissionResponse, MessageResponse
)


router = APIRouter(prefix="/roles", tags=["Uloge i Permisije"])


@router.get("", response_model=List[RoleWithPermissions], summary="Dohvati sve uloge")
async def get_all_roles(
    current_user: dict = Depends(require_permission("ROLE_VIEW")),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca sve uloge u sustavu s njihovim permisijama.
    
    Koristi PostgreSQL view:
    - v_roles_with_permissions
    
    Potrebna permisija: ROLE_VIEW
    """
    with conn.cursor() as cur:
        cur.execute("""
            SELECT * FROM v_roles_with_permissions
            ORDER BY role_name
        """)
        roles = cur.fetchall()
    
    result = []
    for role in roles:
        result.append(RoleWithPermissions(
            role_id=role['role_id'],
            name=role['role_name'],
            description=role['role_description'],
            is_system=role['is_system'],
            created_at=None,  # Nije u view-u
            updated_at=None,
            permissions=role['permissions'] if role['permissions'] else [],
            user_count=role['user_count']
        ))
    
    return result


@router.get("/permissions", response_model=List[PermissionResponse],
            summary="Dohvati sve permisije")
async def get_all_permissions(
    current_user: dict = Depends(require_permission("ROLE_VIEW")),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca sve dostupne permisije u sustavu.
    
    Potrebna permisija: ROLE_VIEW
    """
    with conn.cursor() as cur:
        cur.execute("""
            SELECT * FROM permissions
            ORDER BY category, code
        """)
        permissions = cur.fetchall()
    
    return [PermissionResponse(**perm) for perm in permissions]


@router.get("/{role_id}", response_model=RoleWithPermissions, 
            summary="Dohvati ulogu")
async def get_role(
    role_id: int,
    current_user: dict = Depends(require_permission("ROLE_VIEW")),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca pojedinacu ulogu po ID-u.
    
    Koristi PostgreSQL view:
    - v_roles_with_permissions
    
    Potrebna permisija: ROLE_VIEW
    """
    with conn.cursor() as cur:
        cur.execute("""
            SELECT * FROM v_roles_with_permissions
            WHERE role_id = %s
        """, (role_id,))
        role = cur.fetchone()
    
    if not role:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Uloga nije pronadjena"
        )
    
    return RoleWithPermissions(
        role_id=role['role_id'],
        name=role['role_name'],
        description=role['role_description'],
        is_system=role['is_system'],
        created_at=None,
        updated_at=None,
        permissions=role['permissions'] if role['permissions'] else [],
        user_count=role['user_count']
    )


@router.get("/{role_id}/users", summary="Korisnici s ulogom")
async def get_role_users(
    role_id: int,
    current_user: dict = Depends(require_permission("ROLE_VIEW")),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca sve korisnike koji imaju odredjenu ulogu.
    
    Potrebna permisija: ROLE_VIEW
    """
    with conn.cursor() as cur:
        cur.execute("""
            SELECT u.user_id, u.username, u.email,
                   u.first_name || ' ' || u.last_name as full_name,
                   u.is_active, ur.assigned_at
            FROM user_roles ur
            JOIN users u ON ur.user_id = u.user_id
            WHERE ur.role_id = %s
            ORDER BY u.last_name, u.first_name
        """, (role_id,))
        users = cur.fetchall()
    
    return [dict(user) for user in users]


@router.post("/assign", response_model=MessageResponse, 
             summary="Dodijeli ulogu korisniku")
async def assign_role_to_user(
    assignment: RoleAssignment,
    current_user: dict = Depends(require_permission("ROLE_ASSIGN")),
    conn = Depends(get_db_dependency)
):
    """
    Dodjeljuje ulogu korisniku.
    
    Koristi PostgreSQL proceduru:
    - assign_role()
    
    Potrebna permisija: ROLE_ASSIGN
    """
    try:
        with conn.cursor() as cur:
            cur.execute("""
                CALL assign_role(%s, %s, %s)
            """, (assignment.user_id, assignment.role_name, current_user['user_id']))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    return MessageResponse(
        message=f"Uloga '{assignment.role_name}' dodijeljena korisniku ID {assignment.user_id}",
        success=True
    )


@router.delete("/revoke", response_model=MessageResponse,
               summary="Ukloni ulogu korisniku")
async def revoke_role_from_user(
    assignment: RoleAssignment,
    current_user: dict = Depends(require_permission("ROLE_ASSIGN")),
    conn = Depends(get_db_dependency)
):
    """
    Uklanja ulogu od korisnika.
    
    Koristi PostgreSQL proceduru:
    - revoke_role()
    
    Potrebna permisija: ROLE_ASSIGN
    """
    try:
        with conn.cursor() as cur:
            cur.execute("""
                CALL revoke_role(%s, %s, %s)
            """, (assignment.user_id, assignment.role_name, current_user['user_id']))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    return MessageResponse(
        message=f"Uloga '{assignment.role_name}' uklonjena od korisnika ID {assignment.user_id}",
        success=True
    )


@router.post("", response_model=MessageResponse, summary="Kreiraj novu ulogu")
async def create_role(
    role_data: RoleCreate,
    current_user: dict = Depends(require_permission("ROLE_CREATE")),
    conn = Depends(get_db_dependency)
):
    """
    Kreira novu ulogu u sustavu.
    
    Potrebna permisija: ROLE_CREATE
    """
    try:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO roles (name, description, is_system)
                VALUES (%s, %s, FALSE)
                RETURNING role_id
            """, (role_data.name, role_data.description))
            result = cur.fetchone()
    except Exception as e:
        if "uk_roles_name" in str(e):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Uloga s imenom '{role_data.name}' vec postoji"
            )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    return MessageResponse(
        message=f"Uloga '{role_data.name}' uspjesno kreirana s ID {result['role_id']}",
        success=True
    )


@router.delete("/{role_id}", response_model=MessageResponse, summary="Obrisi ulogu")
async def delete_role(
    role_id: int,
    current_user: dict = Depends(require_permission("ROLE_DELETE")),
    conn = Depends(get_db_dependency)
):
    """
    Brise ulogu iz sustava.
    Sistemske uloge se ne mogu obrisati.
    
    Potrebna permisija: ROLE_DELETE
    """
    with conn.cursor() as cur:
        # Provjeri da li uloga postoji i da li je sistemska
        cur.execute("""
            SELECT role_id, name, is_system FROM roles WHERE role_id = %s
        """, (role_id,))
        role = cur.fetchone()
        
        if not role:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Uloga nije pronadjena"
            )
        
        if role['is_system']:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Sistemska uloga se ne moze obrisati"
            )
        
        # Obrisi ulogu
        cur.execute("DELETE FROM roles WHERE role_id = %s", (role_id,))
    
    return MessageResponse(
        message=f"Uloga '{role['name']}' uspjesno obrisana",
        success=True
    )


@router.post("/{role_id}/permissions/{permission_code}", 
             response_model=MessageResponse,
             summary="Dodaj permisiju ulozi")
async def add_permission_to_role(
    role_id: int,
    permission_code: str,
    current_user: dict = Depends(require_permission("ROLE_UPDATE")),
    conn = Depends(get_db_dependency)
):
    """
    Dodaje permisiju ulozi.
    
    Potrebna permisija: ROLE_UPDATE
    """
    try:
        with conn.cursor() as cur:
            # Dohvati permission_id
            cur.execute("""
                SELECT permission_id FROM permissions WHERE code = %s
            """, (permission_code,))
            perm = cur.fetchone()
            
            if not perm:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Permisija '{permission_code}' nije pronadjena"
                )
            
            # Dodaj permisiju ulozi
            cur.execute("""
                INSERT INTO role_permissions (role_id, permission_id)
                VALUES (%s, %s)
                ON CONFLICT (role_id, permission_id) DO NOTHING
            """, (role_id, perm['permission_id']))
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    return MessageResponse(
        message=f"Permisija '{permission_code}' dodana ulozi ID {role_id}",
        success=True
    )


@router.delete("/{role_id}/permissions/{permission_code}",
               response_model=MessageResponse,
               summary="Ukloni permisiju s uloge")
async def remove_permission_from_role(
    role_id: int,
    permission_code: str,
    current_user: dict = Depends(require_permission("ROLE_UPDATE")),
    conn = Depends(get_db_dependency)
):
    """
    Uklanja permisiju s uloge.
    
    Potrebna permisija: ROLE_UPDATE
    """
    with conn.cursor() as cur:
        cur.execute("""
            DELETE FROM role_permissions 
            WHERE role_id = %s 
            AND permission_id = (SELECT permission_id FROM permissions WHERE code = %s)
        """, (role_id, permission_code))
    
    return MessageResponse(
        message=f"Permisija '{permission_code}' uklonjena s uloge ID {role_id}",
        success=True
    )
