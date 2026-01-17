"""
Roles Router - Upravljanje ulogama i permisijama
CRUD operacije za uloge, dodjela/uklanjanje uloga korisnicima
Upravljanje direktnim permisijama korisnika
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List

from ..database import get_db_dependency
from ..auth import get_current_active_user, require_permission
from ..schemas import (
    RoleResponse, RoleWithPermissions, RoleCreate, RoleUpdate,
    RoleAssignment, PermissionResponse, MessageResponse,
    UserDirectPermission, UserDirectPermissionAssign, UserEffectivePermission
)


router = APIRouter(prefix="/roles", tags=["Uloge i Permisije"])


@router.get("", response_model=List[RoleWithPermissions], summary="Dohvati sve uloge")
async def get_all_roles(
    current_user: dict = Depends(require_permission("ROLE_READ")),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca sve uloge u sustavu s njihovim permisijama.
    
    Koristi PostgreSQL view:
    - v_roles_with_permissions
    
    Potrebna permisija: ROLE_READ
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
    current_user: dict = Depends(require_permission("ROLE_READ")),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca sve dostupne permisije u sustavu.
    
    Potrebna permisija: ROLE_READ
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
    current_user: dict = Depends(require_permission("ROLE_READ")),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca pojedinacu ulogu po ID-u.
    
    Koristi PostgreSQL view:
    - v_roles_with_permissions
    
    Potrebna permisija: ROLE_READ
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
    current_user: dict = Depends(require_permission("ROLE_READ")),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca sve korisnike koji imaju odredjenu ulogu.
    
    Potrebna permisija: ROLE_READ
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


@router.put("/{role_id}", response_model=MessageResponse, summary="Azuriraj ulogu")
async def update_role(
    role_id: int,
    role_data: RoleUpdate,
    current_user: dict = Depends(require_permission("ROLE_UPDATE")),
    conn = Depends(get_db_dependency)
):
    """
    Azurira postojecu ulogu.
    Sistemske uloge mogu imati samo azuriran opis.
    
    Potrebna permisija: ROLE_UPDATE
    """
    with conn.cursor() as cur:
        # Provjeri da li uloga postoji
        cur.execute("SELECT * FROM roles WHERE role_id = %s", (role_id,))
        role = cur.fetchone()
        
        if not role:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Uloga nije pronadjena"
            )
        
        # Sistemske uloge ne mogu mijenjati ime
        if role['is_system'] and role_data.name and role_data.name != role['name']:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Sistemska uloga ne moze promijeniti ime"
            )
        
        # Pripremi UPDATE
        updates = []
        values = []
        
        if role_data.name is not None:
            updates.append("name = %s")
            values.append(role_data.name)
        if role_data.description is not None:
            updates.append("description = %s")
            values.append(role_data.description)
        
        if updates:
            updates.append("updated_at = CURRENT_TIMESTAMP")
            values.append(role_id)
            
            try:
                cur.execute(f"""
                    UPDATE roles SET {', '.join(updates)}
                    WHERE role_id = %s
                """, values)
            except Exception as e:
                if "uk_roles_name" in str(e):
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"Uloga s imenom '{role_data.name}' vec postoji"
                    )
                raise
    
    return MessageResponse(
        message=f"Uloga uspjesno azurirana",
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


# ==================== DIREKTNE PERMISIJE KORISNIKA ====================

@router.get("/users/{user_id}/permissions", 
            response_model=List[UserDirectPermission],
            summary="Dohvati direktne permisije korisnika")
async def get_user_direct_permissions(
    user_id: int,
    current_user: dict = Depends(require_permission("ROLE_READ")),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca sve direktno dodijeljene/zabranjene permisije korisnika.
    
    Potrebna permisija: ROLE_READ
    """
    with conn.cursor() as cur:
        # Provjeri da korisnik postoji
        cur.execute("SELECT user_id FROM users WHERE user_id = %s", (user_id,))
        if not cur.fetchone():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Korisnik s ID {user_id} ne postoji"
            )
        
        # Provjeri postoji li tablica user_permissions
        cur.execute("""
            SELECT EXISTS (
                SELECT 1 FROM information_schema.tables 
                WHERE table_schema = 'employee_management' 
                AND table_name = 'user_permissions'
            ) as exists
        """)
        result = cur.fetchone()
        table_exists = result['exists'] if result else False
        
        if table_exists:
            cur.execute("""
                SELECT 
                    p.code as permission_code,
                    p.name as permission_name,
                    p.category,
                    up.granted,
                    up.assigned_at,
                    (SELECT first_name || ' ' || last_name FROM users WHERE user_id = up.assigned_by) as assigned_by_name,
                    up.notes
                FROM user_permissions up
                JOIN permissions p ON up.permission_id = p.permission_id
                WHERE up.user_id = %s
                ORDER BY p.category, p.code
            """, (user_id,))
            permissions = cur.fetchall()
            return [UserDirectPermission(**perm) for perm in permissions]
        else:
            # Tablica ne postoji - vrati prazan popis
            return []


@router.get("/users/{user_id}/effective-permissions", 
            response_model=List[UserEffectivePermission],
            summary="Dohvati efektivne permisije korisnika")
async def get_user_effective_permissions(
    user_id: int,
    current_user: dict = Depends(get_current_active_user),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca sve efektivne permisije korisnika (iz uloga + direktno dodijeljene).
    
    Korisnik moze vidjeti vlastite permisije ili ako ima ROLE_READ permisiju.
    """
    from ..auth import check_permission
    
    # Provjeri da li korisnik gleda vlastite permisije ili ima ROLE_READ
    if current_user['user_id'] != user_id:
        if not check_permission(conn, current_user['user_id'], 'ROLE_READ'):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Nemate pristup permisijama ovog korisnika"
            )
    
    with conn.cursor() as cur:
        cur.execute("SELECT user_id FROM users WHERE user_id = %s", (user_id,))
        if not cur.fetchone():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Korisnik s ID {user_id} ne postoji"
            )
        
        # Provjeri postoji li nova funkcija s source
        try:
            cur.execute("SELECT * FROM get_user_permissions(%s) LIMIT 1", (user_id,))
            test_row = cur.fetchone()
            has_source = test_row is not None and 'source' in dict(test_row).keys() if test_row else False
        except:
            has_source = False
        
        if has_source:
            cur.execute("SELECT * FROM get_user_permissions(%s)", (user_id,))
            permissions = cur.fetchall()
            return [UserEffectivePermission(**perm) for perm in permissions]
        else:
            # Fallback - koristi staru funkciju i dodaj source='ROLE'
            cur.execute("SELECT * FROM get_user_permissions(%s)", (user_id,))
            permissions = cur.fetchall()
            result = []
            for perm in permissions:
                perm_dict = dict(perm)
                if 'source' not in perm_dict:
                    perm_dict['source'] = 'ROLE'
                result.append(UserEffectivePermission(**perm_dict))
            return result


@router.post("/users/{user_id}/permissions/{permission_code}",
             response_model=MessageResponse,
             summary="Dodijeli direktnu permisiju korisniku")
async def assign_permission_to_user(
    user_id: int,
    permission_code: str,
    data: UserDirectPermissionAssign,
    current_user: dict = Depends(require_permission("ROLE_ASSIGN")),
    conn = Depends(get_db_dependency)
):
    """
    Dodjeljuje ili zabranjuje direktnu permisiju korisniku.
    
    - granted=True: Korisnik dobiva permisiju (čak i ako nema ulogu s tom permisijom)
    - granted=False: Korisniku je zabranjena permisija (čak i ako ima ulogu s tom permisijom)
    
    Koristi PostgreSQL proceduru:
    - assign_user_permission()
    
    Potrebna permisija: ROLE_ASSIGN
    """
    try:
        with conn.cursor() as cur:
            # Provjeri da korisnik postoji
            cur.execute("SELECT user_id FROM users WHERE user_id = %s", (user_id,))
            if not cur.fetchone():
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Korisnik s ID {user_id} ne postoji"
                )
            
            # Dohvati permission_id
            cur.execute("SELECT permission_id FROM permissions WHERE code = %s", (permission_code,))
            perm = cur.fetchone()
            if not perm:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Permisija '{permission_code}' ne postoji"
                )
            
            # Kreiraj tablicu user_permissions ako ne postoji
            cur.execute("""
                CREATE TABLE IF NOT EXISTS user_permissions (
                    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                    permission_id INTEGER NOT NULL REFERENCES permissions(permission_id) ON DELETE CASCADE,
                    granted BOOLEAN NOT NULL DEFAULT TRUE,
                    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    assigned_by INTEGER REFERENCES users(user_id),
                    notes TEXT,
                    PRIMARY KEY (user_id, permission_id)
                )
            """)
            
            # Umetni ili ažuriraj permisiju
            cur.execute("""
                INSERT INTO user_permissions (user_id, permission_id, granted, assigned_by, notes)
                VALUES (%s, %s, %s, %s, %s)
                ON CONFLICT (user_id, permission_id) DO UPDATE SET
                    granted = EXCLUDED.granted,
                    assigned_at = CURRENT_TIMESTAMP,
                    assigned_by = EXCLUDED.assigned_by,
                    notes = EXCLUDED.notes
            """, (user_id, perm['permission_id'], data.granted, current_user['user_id'], data.notes))
    except HTTPException:
        raise
    except Exception as e:
        error_msg = str(e)
        if "ne postoji" in error_msg.lower():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=error_msg
            )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error_msg
        )
    
    action = "dodijeljena" if data.granted else "zabranjena"
    return MessageResponse(
        message=f"Permisija '{permission_code}' {action} korisniku ID {user_id}",
        success=True
    )


@router.delete("/users/{user_id}/permissions/{permission_code}",
               response_model=MessageResponse,
               summary="Ukloni direktnu permisiju korisnika")
async def remove_permission_from_user(
    user_id: int,
    permission_code: str,
    current_user: dict = Depends(require_permission("ROLE_ASSIGN")),
    conn = Depends(get_db_dependency)
):
    """
    Uklanja direktnu permisiju korisnika (vraća na default iz uloge).
    
    Potrebna permisija: ROLE_ASSIGN
    """
    try:
        with conn.cursor() as cur:
            # Dohvati permission_id
            cur.execute("SELECT permission_id FROM permissions WHERE code = %s", (permission_code,))
            perm = cur.fetchone()
            if not perm:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Permisija '{permission_code}' ne postoji"
                )
            
            # Provjeri postoji li tablica - ako ne postoji, ništa za brisati
            cur.execute("""
                SELECT EXISTS (
                    SELECT 1 FROM information_schema.tables 
                    WHERE table_schema = 'employee_management' 
                    AND table_name = 'user_permissions'
                ) as exists
            """)
            result = cur.fetchone()
            table_exists = result['exists'] if result else False
            
            if table_exists:
                cur.execute("""
                    DELETE FROM user_permissions 
                    WHERE user_id = %s AND permission_id = %s
                """, (user_id, perm['permission_id']))
            # Ako tablica ne postoji, nema što za brisati - to je OK
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    return MessageResponse(
        message=f"Direktna permisija '{permission_code}' uklonjena od korisnika ID {user_id}",
        success=True
    )
