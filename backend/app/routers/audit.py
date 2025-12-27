"""
Audit Router - Pregled audit logova i login evenata
Omogucuje administratorima praćenje svih promjena u sustavu
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from datetime import datetime, date

from ..database import get_db_dependency
from ..auth import require_permission
from ..schemas import AuditLogResponse, LoginEventResponse, MessageResponse


router = APIRouter(prefix="/audit", tags=["Audit i Logging"])


@router.get("/logs", response_model=List[AuditLogResponse],
            summary="Dohvati audit logove")
async def get_audit_logs(
    entity_name: Optional[str] = Query(None, description="Filter po entitetu (users, tasks, roles...)"),
    entity_id: Optional[int] = Query(None, description="Filter po ID entiteta"),
    action: Optional[str] = Query(None, description="Filter po akciji (INSERT, UPDATE, DELETE)"),
    changed_by: Optional[int] = Query(None, description="Filter po korisniku koji je napravio promjenu"),
    from_date: Optional[date] = Query(None, description="Od datuma"),
    to_date: Optional[date] = Query(None, description="Do datuma"),
    limit: int = Query(100, ge=1, le=1000),
    current_user: dict = Depends(require_permission("AUDIT_VIEW")),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca audit log zapise s opcijama filtriranja.
    
    Koristi PostgreSQL tablicu:
    - audit_log
    
    Potrebna permisija: AUDIT_VIEW
    
    Audit log automatski bilježi sve promjene putem trigger-a:
    - trg_audit_users
    - trg_audit_tasks
    - trg_audit_user_roles
    """
    query = "SELECT * FROM audit_log WHERE 1=1"
    params = []
    
    if entity_name:
        query += " AND entity_name = %s"
        params.append(entity_name)
    
    if entity_id:
        query += " AND entity_id = %s"
        params.append(entity_id)
    
    if action:
        query += " AND action = %s"
        params.append(action)
    
    if changed_by:
        query += " AND changed_by = %s"
        params.append(changed_by)
    
    if from_date:
        query += " AND changed_at >= %s"
        params.append(from_date)
    
    if to_date:
        query += " AND changed_at <= %s"
        params.append(to_date)
    
    query += " ORDER BY changed_at DESC LIMIT %s"
    params.append(limit)
    
    with conn.cursor() as cur:
        cur.execute(query, params)
        logs = cur.fetchall()
    
    result = []
    for log in logs:
        result.append(AuditLogResponse(
            audit_log_id=log['audit_log_id'],
            entity_name=log['entity_name'],
            entity_id=log['entity_id'],
            action=log['action'],
            changed_by=log['changed_by'],
            changed_at=log['changed_at'],
            old_value=log['old_value'],
            new_value=log['new_value'],
            ip_address=str(log['ip_address']) if log['ip_address'] else None
        ))
    
    return result


@router.get("/logs/entity/{entity_name}/{entity_id}",
            response_model=List[AuditLogResponse],
            summary="Povijest promjena entiteta")
async def get_entity_history(
    entity_name: str,
    entity_id: int,
    current_user: dict = Depends(require_permission("AUDIT_VIEW")),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca kompletnu povijest promjena za odredjeni entitet.
    
    Koristi PostgreSQL tablicu:
    - audit_log
    
    Potrebna permisija: AUDIT_VIEW
    """
    with conn.cursor() as cur:
        cur.execute("""
            SELECT * FROM audit_log 
            WHERE entity_name = %s AND entity_id = %s
            ORDER BY changed_at DESC
        """, (entity_name, entity_id))
        logs = cur.fetchall()
    
    result = []
    for log in logs:
        result.append(AuditLogResponse(
            audit_log_id=log['audit_log_id'],
            entity_name=log['entity_name'],
            entity_id=log['entity_id'],
            action=log['action'],
            changed_by=log['changed_by'],
            changed_at=log['changed_at'],
            old_value=log['old_value'],
            new_value=log['new_value'],
            ip_address=str(log['ip_address']) if log['ip_address'] else None
        ))
    
    return result


@router.get("/logins", response_model=List[LoginEventResponse],
            summary="Dohvati login evente")
async def get_login_events(
    user_id: Optional[int] = Query(None, description="Filter po korisniku"),
    username: Optional[str] = Query(None, description="Filter po korisnickom imenu"),
    success: Optional[bool] = Query(None, description="Filter po uspjehu prijave"),
    from_date: Optional[date] = Query(None, description="Od datuma"),
    to_date: Optional[date] = Query(None, description="Do datuma"),
    limit: int = Query(100, ge=1, le=1000),
    current_user: dict = Depends(require_permission("AUDIT_VIEW")),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca evente prijave u sustav.
    
    Koristi PostgreSQL tablicu:
    - login_events
    
    Potrebna permisija: AUDIT_VIEW
    
    Login eventi se bilježe putem funkcije:
    - log_login_attempt()
    """
    query = "SELECT * FROM login_events WHERE 1=1"
    params = []
    
    if user_id:
        query += " AND user_id = %s"
        params.append(user_id)
    
    if username:
        query += " AND username_attempted ILIKE %s"
        params.append(f"%{username}%")
    
    if success is not None:
        query += " AND success = %s"
        params.append(success)
    
    if from_date:
        query += " AND login_time >= %s"
        params.append(from_date)
    
    if to_date:
        query += " AND login_time <= %s"
        params.append(to_date)
    
    query += " ORDER BY login_time DESC LIMIT %s"
    params.append(limit)
    
    with conn.cursor() as cur:
        cur.execute(query, params)
        events = cur.fetchall()
    
    result = []
    for event in events:
        result.append(LoginEventResponse(
            login_event_id=event['login_event_id'],
            user_id=event['user_id'],
            username_attempted=event['username_attempted'],
            login_time=event['login_time'],
            ip_address=str(event['ip_address']) if event['ip_address'] else "0.0.0.0",
            user_agent=event['user_agent'],
            success=event['success'],
            failure_reason=event['failure_reason']
        ))
    
    return result


@router.get("/logins/failed", response_model=List[LoginEventResponse],
            summary="Neuspjeli pokusaji prijave")
async def get_failed_logins(
    limit: int = Query(50, ge=1, le=500),
    current_user: dict = Depends(require_permission("AUDIT_VIEW")),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca neuspjele pokusaje prijave.
    Korisno za sigurnosni monitoring.
    
    Potrebna permisija: AUDIT_VIEW
    """
    with conn.cursor() as cur:
        cur.execute("""
            SELECT * FROM login_events 
            WHERE success = FALSE
            ORDER BY login_time DESC
            LIMIT %s
        """, (limit,))
        events = cur.fetchall()
    
    result = []
    for event in events:
        result.append(LoginEventResponse(
            login_event_id=event['login_event_id'],
            user_id=event['user_id'],
            username_attempted=event['username_attempted'],
            login_time=event['login_time'],
            ip_address=str(event['ip_address']) if event['ip_address'] else "0.0.0.0",
            user_agent=event['user_agent'],
            success=event['success'],
            failure_reason=event['failure_reason']
        ))
    
    return result


@router.get("/statistics", summary="Statistike audita")
async def get_audit_statistics(
    current_user: dict = Depends(require_permission("AUDIT_VIEW")),
    conn = Depends(get_db_dependency)
):
    """
    Dohvaca statistike audit logova i login evenata.
    
    Potrebna permisija: AUDIT_VIEW
    """
    with conn.cursor() as cur:
        # Broj audit zapisa po entitetu
        cur.execute("""
            SELECT entity_name, action, COUNT(*) as count
            FROM audit_log
            GROUP BY entity_name, action
            ORDER BY entity_name, action
        """)
        audit_by_entity = cur.fetchall()
        
        # Login statistike
        cur.execute("""
            SELECT 
                COUNT(*) FILTER (WHERE success = TRUE) as successful_logins,
                COUNT(*) FILTER (WHERE success = FALSE) as failed_logins,
                COUNT(DISTINCT user_id) FILTER (WHERE success = TRUE) as unique_users,
                MAX(login_time) as last_login
            FROM login_events
        """)
        login_stats = cur.fetchone()
        
        # Zadnjih 24 sata
        cur.execute("""
            SELECT 
                COUNT(*) as total_changes,
                COUNT(*) FILTER (WHERE action = 'INSERT') as inserts,
                COUNT(*) FILTER (WHERE action = 'UPDATE') as updates,
                COUNT(*) FILTER (WHERE action = 'DELETE') as deletes
            FROM audit_log
            WHERE changed_at >= NOW() - INTERVAL '24 hours'
        """)
        last_24h = cur.fetchone()
    
    return {
        "audit_by_entity": [dict(row) for row in audit_by_entity],
        "login_statistics": dict(login_stats) if login_stats else {},
        "last_24_hours": dict(last_24h) if last_24h else {}
    }


@router.post("/cleanup/logs", response_model=MessageResponse,
             summary="Ocisti stare audit logove")
async def cleanup_audit_logs(
    days_to_keep: int = Query(365, ge=30, le=3650, description="Broj dana za zadrzati"),
    current_user: dict = Depends(require_permission("AUDIT_DELETE")),
    conn = Depends(get_db_dependency)
):
    """
    Brise audit zapise starije od zadanog broja dana.
    
    Koristi PostgreSQL proceduru:
    - cleanup_old_audit_logs()
    
    Potrebna permisija: AUDIT_DELETE
    """
    try:
        with conn.cursor() as cur:
            cur.execute("CALL cleanup_old_audit_logs(%s)", (days_to_keep,))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    
    return MessageResponse(
        message=f"Audit logovi stariji od {days_to_keep} dana uspjesno obrisani",
        success=True
    )


@router.post("/cleanup/logins", response_model=MessageResponse,
             summary="Ocisti stare login evente")
async def cleanup_login_events(
    days_to_keep: int = Query(90, ge=7, le=365, description="Broj dana za zadrzati"),
    current_user: dict = Depends(require_permission("AUDIT_DELETE")),
    conn = Depends(get_db_dependency)
):
    """
    Brise login evente starije od zadanog broja dana.
    
    Koristi PostgreSQL proceduru:
    - cleanup_old_login_events()
    
    Potrebna permisija: AUDIT_DELETE
    """
    try:
        with conn.cursor() as cur:
            cur.execute("CALL cleanup_old_login_events(%s)", (days_to_keep,))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    
    return MessageResponse(
        message=f"Login eventi stariji od {days_to_keep} dana uspjesno obrisani",
        success=True
    )
