"""
Pydantic Modeli (Schemas)
Definicija svih request/response modela za API
"""

from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional, List
from datetime import datetime, date
from enum import Enum


# ============== ENUMS ==============

class TaskStatus(str, Enum):
    """Status zadatka - odgovara task_status ENUM tipu u bazi"""
    NEW = "NEW"
    IN_PROGRESS = "IN_PROGRESS"
    ON_HOLD = "ON_HOLD"
    PENDING_APPROVAL = "PENDING_APPROVAL"  
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"


class TaskPriority(str, Enum):
    """Prioritet zadatka - odgovara task_priority ENUM tipu u bazi"""
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    URGENT = "URGENT"


class AuditAction(str, Enum):
    """Vrsta audit akcije"""
    INSERT = "INSERT"
    UPDATE = "UPDATE"
    DELETE = "DELETE"


# ============== AUTH MODELS ==============

class Token(BaseModel):
    """JWT Token response"""
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    """Podaci dekodiranog tokena"""
    username: Optional[str] = None
    user_id: Optional[int] = None


class LoginRequest(BaseModel):
    """Request za prijavu"""
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=1)


# ============== USER MODELS ==============

class UserBase(BaseModel):
    """Bazni model korisnika"""
    username: str = Field(..., min_length=3, max_length=50, pattern=r'^[a-zA-Z0-9_]+$')
    email: EmailStr
    first_name: str = Field(..., min_length=1, max_length=50)
    last_name: str = Field(..., min_length=1, max_length=50)


class UserCreate(UserBase):
    """Model za kreiranje korisnika"""
    password: str = Field(..., min_length=8)
    manager_id: Optional[int] = None
    role_name: str = Field(default="EMPLOYEE")
    
    @field_validator('password')
    @classmethod
    def validate_password(cls, v):
        if not any(c.isupper() for c in v):
            raise ValueError('Lozinka mora sadrzavati barem jedno veliko slovo')
        if not any(c.islower() for c in v):
            raise ValueError('Lozinka mora sadrzavati barem jedno malo slovo')
        if not any(c.isdigit() for c in v):
            raise ValueError('Lozinka mora sadrzavati barem jedan broj')
        return v


class UserUpdate(BaseModel):
    """Model za azuriranje korisnika"""
    first_name: Optional[str] = Field(None, min_length=1, max_length=50)
    last_name: Optional[str] = Field(None, min_length=1, max_length=50)
    email: Optional[EmailStr] = None
    manager_id: Optional[int] = None
    is_active: Optional[bool] = None


class ChangePassword(BaseModel):
    """Model za promjenu lozinke"""
    current_password: str = Field(..., min_length=1)
    new_password: str = Field(..., min_length=8)
    
    @field_validator('new_password')
    @classmethod
    def validate_new_password(cls, v):
        if not any(c.isupper() for c in v):
            raise ValueError('Nova lozinka mora sadrzavati barem jedno veliko slovo')
        if not any(c.islower() for c in v):
            raise ValueError('Nova lozinka mora sadrzavati barem jedno malo slovo')
        if not any(c.isdigit() for c in v):
            raise ValueError('Nova lozinka mora sadrzavati barem jedan broj')
        return v


class UserResponse(UserBase):
    """Response model korisnika"""
    user_id: int
    is_active: bool
    manager_id: Optional[int] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class UserWithRoles(UserResponse):
    """Korisnik s ulogama i permisijama"""
    roles: List[str] = []
    permissions: List[str] = []
    manager_username: Optional[str] = None
    manager_full_name: Optional[str] = None


class UserStatistics(BaseModel):
    """Statistika korisnika"""
    user_id: int
    username: str
    full_name: str
    is_active: bool
    tasks_created: int
    tasks_assigned: int
    tasks_completed: int
    tasks_active: int
    successful_logins: int
    last_login: Optional[datetime] = None


# ============== ROLE MODELS ==============

class RoleBase(BaseModel):
    """Bazni model uloge"""
    name: str = Field(..., min_length=1, max_length=50)
    description: Optional[str] = None


class RoleCreate(RoleBase):
    """Model za kreiranje uloge"""
    pass


class RoleUpdate(BaseModel):
    """Model za azuriranje uloge"""
    name: Optional[str] = Field(None, min_length=1, max_length=50)
    description: Optional[str] = None


class RoleResponse(RoleBase):
    """Response model uloge"""
    role_id: int
    is_system: bool
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class RoleWithPermissions(RoleResponse):
    """Uloga s permisijama"""
    permissions: List[str] = []
    user_count: int = 0


class RoleAssignment(BaseModel):
    """Model za dodjelu uloge"""
    user_id: int
    role_name: str


# ============== PERMISSION MODELS ==============

class PermissionBase(BaseModel):
    """Bazni model permisije"""
    code: str = Field(..., pattern=r'^[A-Z_]+$')
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = None
    category: str = Field(..., pattern=r'^(USER|ROLE|TASK|AUDIT)$')


class PermissionResponse(PermissionBase):
    """Response model permisije"""
    permission_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True


class UserPermission(BaseModel):
    """Permisija korisnika"""
    permission_code: str
    permission_name: str
    category: str


class UserDirectPermission(BaseModel):
    """Direktno dodijeljena permisija korisniku"""
    permission_code: str
    permission_name: str
    category: str
    granted: bool
    assigned_at: Optional[datetime] = None
    assigned_by_name: Optional[str] = None
    notes: Optional[str] = None


class UserDirectPermissionAssign(BaseModel):
    """Model za dodjelu direktne permisije korisniku"""
    granted: bool = True
    notes: Optional[str] = None


class UserEffectivePermission(BaseModel):
    """Efektivna permisija korisnika (iz uloge ili direktno)"""
    permission_code: str
    permission_name: str
    category: str
    source: str = 'ROLE'  


# ============== TASK MODELS ==============

class TaskBase(BaseModel):
    """Bazni model zadatka"""
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = None
    priority: TaskPriority = TaskPriority.MEDIUM
    due_date: Optional[date] = None


class TaskCreate(TaskBase):
    """Model za kreiranje zadatka"""
    assigned_to: Optional[int] = None  
    assigned_to_ids: Optional[List[int]] = None  


class TaskUpdate(BaseModel):
    """Model za azuriranje zadatka"""
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = None
    priority: Optional[TaskPriority] = None
    due_date: Optional[date] = None
    assigned_to: Optional[int] = None  
    assigned_to_ids: Optional[List[int]] = None 


class TaskStatusUpdate(BaseModel):
    """Model za promjenu statusa zadatka"""
    status: TaskStatus


class TaskAssignment(BaseModel):
    """Model za dodjelu zadatka"""
    assignee_id: Optional[int] = None  
    assignee_ids: Optional[List[int]] = None  


class TaskResponse(TaskBase):
    """Response model zadatka"""
    task_id: int
    status: TaskStatus
    created_by: int
    assigned_to: Optional[int] = None
    created_at: datetime
    updated_at: datetime
    completed_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class TaskDetails(TaskBase):
    """Detaljni prikaz zadatka"""
    task_id: int
    status: TaskStatus
    created_by: int
    assigned_to: Optional[int] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    creator_id: int
    creator_username: str
    creator_name: str
    assignee_id: Optional[int] = None
    assignee_username: Optional[str] = None
    assignee_name: Optional[str] = None
    assignee_ids: Optional[List[int]] = None
    assignee_names: Optional[List[str]] = None
    due_status: Optional[str] = None
    is_overdue: bool = False


class TaskStatistics(BaseModel):
    """Statistika zadataka korisnika"""
    total_tasks: int
    completed_tasks: int
    in_progress_tasks: int
    overdue_tasks: int
    completion_rate: float


# ============== TEAM MODELS ==============

class TeamMember(BaseModel):
    """Clan tima"""
    user_id: int
    username: str
    full_name: str
    email: str
    is_active: bool


# ============== AUDIT MODELS ==============

class AuditLogResponse(BaseModel):
    """Response model audit log zapisa"""
    audit_log_id: int
    entity_name: str
    entity_id: int
    action: AuditAction
    changed_by: Optional[int] = None
    changed_at: datetime
    old_value: Optional[dict] = None
    new_value: Optional[dict] = None
    ip_address: Optional[str] = None
    
    class Config:
        from_attributes = True


class LoginEventResponse(BaseModel):
    """Response model login eventa"""
    login_event_id: int
    user_id: Optional[int] = None
    username_attempted: str
    login_time: datetime
    ip_address: str
    user_agent: Optional[str] = None
    success: bool
    failure_reason: Optional[str] = None
    
    class Config:
        from_attributes = True


# ============== GENERIC MODELS ==============

class MessageResponse(BaseModel):
    """Genericki response s porukom"""
    message: str
    success: bool = True


class PaginatedResponse(BaseModel):
    """Paginirani response"""
    items: List
    total: int
    page: int
    per_page: int
    pages: int
