"""
Tasks Router - Upravljanje zadacima
CRUD operacije, dodjela, promjena statusa
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional

from ..database import get_db_dependency
from ..auth import (
    get_current_active_user, require_permission, check_permission,
    is_manager_of_user
)
from ..schemas import (
    TaskCreate, TaskUpdate, TaskResponse, TaskDetails,
    TaskStatusUpdate, TaskAssignment, TaskStatistics,
    MessageResponse, TaskStatus, TaskPriority
)


router = APIRouter(prefix="/tasks", tags=["Zadaci"])


@router.get("", response_model=List[TaskDetails], summary="Dohvati sve zadatke")
async def get_all_tasks(
    status_filter: Optional[TaskStatus] = Query(None, alias="status"),
    priority: Optional[TaskPriority] = Query(None),
    assigned_to: Optional[int] = Query(None),
    created_by: Optional[int] = Query(None),
    current_user: dict = Depends(require_permission("TASK_READ_ALL")),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca sve zadatke s opcijama filtriranja.
    
    Koristi PostgreSQL view:
    - v_tasks_details
    
    Potrebna permisija: TASK_READ_ALL
    """
    query = "SELECT * FROM v_tasks_details WHERE 1=1"
    params = []
    
    if status_filter:
        query += " AND status = %s"
        params.append(status_filter.value)
    
    if priority:
        query += " AND priority = %s"
        params.append(priority.value)
    
    if assigned_to:
        query += " AND assignee_id = %s"
        params.append(assigned_to)
    
    if created_by:
        query += " AND creator_id = %s"
        params.append(created_by)
    
    query += " ORDER BY priority DESC, due_date NULLS LAST"
    
    with conn.cursor() as cur:
        cur.execute(query, params)
        tasks = cur.fetchall()
    
    result = []
    for task in tasks:
        result.append(TaskDetails(
            task_id=task['task_id'],
            title=task['title'],
            description=task['description'],
            status=task['status'],
            priority=task['priority'],
            due_date=task['due_date'],
            created_by=task['creator_id'],
            assigned_to=task['assignee_id'],
            created_at=task['created_at'],
            updated_at=task['updated_at'],
            completed_at=task['completed_at'],
            creator_id=task['creator_id'],
            creator_username=task['creator_username'],
            creator_name=task['creator_name'],
            assignee_id=task['assignee_id'],
            assignee_username=task['assignee_username'],
            assignee_name=task['assignee_name'],
            due_status=task['due_status'],
            is_overdue=task['due_status'] == 'OVERDUE' if task['due_status'] else False
        ))
    
    return result


@router.get("/my", response_model=List[TaskDetails], summary="Moji zadaci")
async def get_my_tasks(
    status_filter: Optional[TaskStatus] = Query(None, alias="status"),
    include_created: bool = Query(False, description="Ukljuci i zadatke koje sam kreirao"),
    current_user: dict = Depends(get_current_active_user),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca zadatke trenutnog korisnika.
    
    Koristi PostgreSQL funkciju:
    - get_user_tasks()
    """
    with conn.cursor() as cur:
        cur.execute("""
            SELECT * FROM get_user_tasks(%s, %s, %s)
        """, (
            current_user['user_id'],
            status_filter.value if status_filter else None,
            include_created
        ))
        tasks = cur.fetchall()
    
    result = []
    for task in tasks:
        result.append(TaskDetails(
            task_id=task['task_id'],
            title=task['title'],
            description=task['description'],
            status=task['status'],
            priority=task['priority'],
            due_date=task['due_date'],
            created_by=0,  # Nije u funkciji
            assigned_to=None,
            created_at=None,
            updated_at=None,
            completed_at=None,
            creator_id=0,
            creator_username="",
            creator_name=task['creator_name'],
            assignee_id=None,
            assignee_username=None,
            assignee_name=task['assignee_name'],
            due_status=None,
            is_overdue=task['is_overdue']
        ))
    
    return result


@router.get("/my/statistics", response_model=TaskStatistics,
            summary="Moja statistika zadataka")
async def get_my_task_statistics(
    current_user: dict = Depends(get_current_active_user),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca statistiku zadataka trenutnog korisnika.
    
    Koristi PostgreSQL funkciju:
    - get_task_statistics()
    """
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM get_task_statistics(%s)", 
                   (current_user['user_id'],))
        stats = cur.fetchone()
    
    if not stats:
        return TaskStatistics(
            total_tasks=0, completed_tasks=0, in_progress_tasks=0,
            overdue_tasks=0, completion_rate=0.0
        )
    
    return TaskStatistics(**stats)


@router.get("/{task_id}", response_model=TaskDetails, summary="Dohvati zadatak")
async def get_task(
    task_id: int,
    current_user: dict = Depends(get_current_active_user),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca pojedinacan zadatak po ID-u.
    
    Koristi PostgreSQL view:
    - v_tasks_details
    """
    with conn.cursor() as cur:
        cur.execute("""
            SELECT * FROM v_tasks_details 
            WHERE task_id = %s
        """, (task_id,))
        task = cur.fetchone()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Zadatak nije pronadjen"
        )
    
    # Provjera pristupa
    can_view = (
        task['assignee_id'] == current_user['user_id'] or
        task['creator_id'] == current_user['user_id'] or
        check_permission(conn, current_user['user_id'], 'TASK_READ_ALL')
    )
    
    if not can_view:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Nemate pristup ovom zadatku"
        )
    
    return TaskDetails(
        task_id=task['task_id'],
        title=task['title'],
        description=task['description'],
        status=task['status'],
        priority=task['priority'],
        due_date=task['due_date'],
        created_by=task['creator_id'],
        assigned_to=task['assignee_id'],
        created_at=task['created_at'],
        updated_at=task['updated_at'],
        completed_at=task['completed_at'],
        creator_id=task['creator_id'],
        creator_username=task['creator_username'],
        creator_name=task['creator_name'],
        assignee_id=task['assignee_id'],
        assignee_username=task['assignee_username'],
        assignee_name=task['assignee_name'],
        due_status=task['due_status'],
        is_overdue=task['due_status'] == 'OVERDUE' if task['due_status'] else False
    )


@router.post("", response_model=MessageResponse, summary="Kreiraj zadatak")
async def create_task(
    task_data: TaskCreate,
    current_user: dict = Depends(require_permission("TASK_CREATE")),
    conn = Depends(get_db_dependency)
):
    """
    Kreira novi zadatak.
    
    Koristi PostgreSQL proceduru:
    - create_task()
    
    Potrebna permisija: TASK_CREATE
    """
    try:
        with conn.cursor() as cur:
            cur.execute("""
                CALL create_task(%s, %s, %s, %s, %s, %s, NULL)
            """, (
                task_data.title,
                task_data.description,
                task_data.priority.value,
                task_data.due_date,
                current_user['user_id'],
                task_data.assigned_to
            ))
            
            # Dohvati ID novog zadatka
            cur.execute("""
                SELECT task_id FROM tasks 
                WHERE title = %s AND created_by = %s
                ORDER BY created_at DESC LIMIT 1
            """, (task_data.title, current_user['user_id']))
            new_task = cur.fetchone()
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    task_id = new_task['task_id'] if new_task else "unknown"
    return MessageResponse(
        message=f"Zadatak '{task_data.title}' uspjesno kreiran s ID {task_id}",
        success=True
    )


@router.put("/{task_id}/status", response_model=MessageResponse,
            summary="Promijeni status zadatka")
async def update_task_status(
    task_id: int,
    status_data: TaskStatusUpdate,
    current_user: dict = Depends(get_current_active_user),
    conn = Depends(get_db_dependency)
):
    """
    Mijenja status zadatka.
    
    Koristi PostgreSQL proceduru:
    - update_task_status()
    
    Pravila:
    - Korisnik mora biti assignee, kreator, ili imati TASK_UPDATE_ANY permisiju
    - Zavrseni zadaci se ne mogu ponovo otvoriti
    - Otkazani zadaci se ne mogu mijenjati
    """
    try:
        with conn.cursor() as cur:
            cur.execute("""
                CALL update_task_status(%s, %s, %s)
            """, (task_id, status_data.status.value, current_user['user_id']))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    return MessageResponse(
        message=f"Status zadatka ID {task_id} promijenjen u {status_data.status.value}",
        success=True
    )


@router.put("/{task_id}/assign", response_model=MessageResponse,
            summary="Dodijeli zadatak")
async def assign_task(
    task_id: int,
    assignment: TaskAssignment,
    current_user: dict = Depends(require_permission("TASK_ASSIGN")),
    conn = Depends(get_db_dependency)
):
    """
    Dodjeljuje zadatak korisniku.
    
    Koristi PostgreSQL proceduru:
    - assign_task()
    
    Potrebna permisija: TASK_ASSIGN
    """
    try:
        with conn.cursor() as cur:
            cur.execute("""
                CALL assign_task(%s, %s, %s)
            """, (task_id, assignment.assignee_id, current_user['user_id']))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    return MessageResponse(
        message=f"Zadatak ID {task_id} dodijeljen korisniku ID {assignment.assignee_id}",
        success=True
    )


@router.put("/{task_id}", response_model=MessageResponse, summary="Azuriraj zadatak")
async def update_task(
    task_id: int,
    task_data: TaskUpdate,
    current_user: dict = Depends(get_current_active_user),
    conn = Depends(get_db_dependency)
):
    """
    Azurira podatke zadatka (naslov, opis, prioritet, rok).
    
    Koristi direktni SQL UPDATE s provjerom permisija.
    """
    # Provjera da zadatak postoji i provjera pristupa
    with conn.cursor() as cur:
        cur.execute("""
            SELECT task_id, created_by, assigned_to, status
            FROM tasks WHERE task_id = %s
        """, (task_id,))
        task = cur.fetchone()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Zadatak nije pronadjen"
        )
    
    # Provjera permisija
    can_update = (
        task['created_by'] == current_user['user_id'] or
        task['assigned_to'] == current_user['user_id'] or
        check_permission(conn, current_user['user_id'], 'TASK_UPDATE_ANY')
    )
    
    if not can_update:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Nemate dozvolu za azuriranje ovog zadatka"
        )
    
    if task['status'] in ('COMPLETED', 'CANCELLED'):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ne mozete azurirati zavrsen ili otkaazan zadatak"
        )
    
    # Azuriraj
    try:
        with conn.cursor() as cur:
            update_parts = []
            params = []
            
            if task_data.title is not None:
                update_parts.append("title = %s")
                params.append(task_data.title)
            
            if task_data.description is not None:
                update_parts.append("description = %s")
                params.append(task_data.description)
            
            if task_data.priority is not None:
                update_parts.append("priority = %s")
                params.append(task_data.priority.value)
            
            if task_data.due_date is not None:
                update_parts.append("due_date = %s")
                params.append(task_data.due_date)
            
            if update_parts:
                update_parts.append("updated_at = CURRENT_TIMESTAMP")
                params.append(task_id)
                
                cur.execute(f"""
                    UPDATE tasks SET {', '.join(update_parts)}
                    WHERE task_id = %s
                """, params)
                
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    return MessageResponse(
        message=f"Zadatak ID {task_id} uspjesno azuriran",
        success=True
    )


@router.delete("/{task_id}", response_model=MessageResponse, summary="Obrisi zadatak")
async def delete_task(
    task_id: int,
    current_user: dict = Depends(require_permission("TASK_DELETE")),
    conn = Depends(get_db_dependency)
):
    """
    Brise zadatak iz sustava.
    
    Potrebna permisija: TASK_DELETE
    """
    with conn.cursor() as cur:
        cur.execute("SELECT task_id FROM tasks WHERE task_id = %s", (task_id,))
        if not cur.fetchone():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Zadatak nije pronadjen"
            )
        
        cur.execute("DELETE FROM tasks WHERE task_id = %s", (task_id,))
    
    return MessageResponse(
        message=f"Zadatak ID {task_id} uspjesno obrisan",
        success=True
    )
