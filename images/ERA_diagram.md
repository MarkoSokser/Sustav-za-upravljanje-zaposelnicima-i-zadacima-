# ERA Dijagram - Konačni model baze podataka

## Mermaid kod za generiranje dijagrama

```mermaid
erDiagram
    USER ||--o{ USER_ROLE : "has"
    USER ||--o{ TASK : "creates"
    USER ||--o{ TASK_ASSIGNEE : "assigned_to"
    USER ||--o{ LOGIN_EVENT : "logs"
    USER ||--o{ AUDIT_LOG : "changes"
    USER ||--o{ USER_PERMISSION : "has_direct"
    USER }o--|| USER : "manager_of"
    
    ROLE ||--o{ USER_ROLE : "assigned_to"
    ROLE ||--o{ ROLE_PERMISSION : "has"
    
    PERMISSION ||--o{ ROLE_PERMISSION : "belongs_to"
    PERMISSION ||--o{ USER_PERMISSION : "granted_to"
    
    TASK ||--o{ TASK_ASSIGNEE : "has_assignees"

    USER {
        int user_id PK
        varchar username UK
        varchar email UK
        varchar password_hash
        varchar first_name
        varchar last_name
        int manager_id FK
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    ROLE {
        int role_id PK
        varchar name UK
        text description
        boolean is_system
        timestamp created_at
        timestamp updated_at
    }

    PERMISSION {
        int permission_id PK
        varchar code UK
        varchar name
        text description
        varchar category
        timestamp created_at
    }

    USER_ROLE {
        int user_role_id PK
        int user_id FK
        int role_id FK
        timestamp assigned_at
        int assigned_by FK
    }

    ROLE_PERMISSION {
        int role_permission_id PK
        int role_id FK
        int permission_id FK
        timestamp assigned_at
    }

    USER_PERMISSION {
        int user_permission_id PK
        int user_id FK
        int permission_id FK
        boolean is_granted
        timestamp assigned_at
        int assigned_by FK
    }

    TASK {
        int task_id PK
        varchar title
        text description
        enum status
        enum priority
        date due_date
        int created_by FK
        int assigned_to FK
        timestamp created_at
        timestamp updated_at
        timestamp completed_at
    }

    TASK_ASSIGNEE {
        int task_assignee_id PK
        int task_id FK
        int user_id FK
        timestamp assigned_at
        int assigned_by FK
    }

    LOGIN_EVENT {
        int login_event_id PK
        int user_id FK
        varchar username_attempted
        timestamp login_time
        inet ip_address
        text user_agent
        boolean success
        varchar failure_reason
    }

    AUDIT_LOG {
        int audit_log_id PK
        varchar entity_name
        int entity_id
        enum action
        int changed_by FK
        timestamp changed_at
        jsonb old_value
        jsonb new_value
        inet ip_address
    }
```

## Opis tablica

### Glavne tablice
| Tablica | Opis |
|---------|------|
| **users** | Korisnici sustava (zaposlenici) |
| **roles** | Uloge u sustavu (ADMIN, MANAGER, EMPLOYEE) |
| **permissions** | Pojedinačna prava pristupa |
| **tasks** | Zadaci u sustavu |

### Povezne tablice (M:N veze)
| Tablica | Veza | Opis |
|---------|------|------|
| **user_roles** | User ↔ Role | Dodjela uloga korisnicima |
| **role_permissions** | Role ↔ Permission | Dodjela prava ulogama |
| **user_permissions** | User ↔ Permission | **NOVO** - Direktna dodjela prava korisnicima |
| **task_assignees** | Task ↔ User | Višestruka dodjela zadataka |

### Audit tablice
| Tablica | Opis |
|---------|------|
| **login_events** | Evidencija prijava u sustav |
| **audit_logs** | Evidencija promjena nad podacima |

## ENUM tipovi

### task_status
| Vrijednost | Opis |
|------------|------|
| `NEW` | Novi zadatak |
| `IN_PROGRESS` | U tijeku |
| `ON_HOLD` | Na čekanju |
| `PENDING_APPROVAL` | **NOVO** - Čeka odobrenje managera |
| `COMPLETED` | Završeno |
| `CANCELLED` | Otkazano |

### task_priority
| Vrijednost | Opis |
|------------|------|
| `LOW` | Nizak prioritet |
| `MEDIUM` | Srednji prioritet |
| `HIGH` | Visok prioritet |
| `URGENT` | Hitan |

### audit_action
| Vrijednost | Opis |
|------------|------|
| `INSERT` | Kreiranje zapisa |
| `UPDATE` | Ažuriranje zapisa |
| `DELETE` | Brisanje zapisa |

## Kardinalnosti

- **User ↔ Role**: M:N (preko user_roles)
- **Role ↔ Permission**: M:N (preko role_permissions)  
- **User ↔ Permission**: M:N (preko user_permissions) - **NOVO**
- **Task ↔ User**: M:N (preko task_assignees)
- **User → User**: 1:N (manager_id self-reference)
- **User → Task**: 1:N (created_by)
- **User → LoginEvent**: 1:N
- **User → AuditLog**: 1:N

## Workflow odobravanja zadataka

```
┌─────────────┐     ┌──────────────┐     ┌───────────────────┐     ┌────────────┐
│    NEW      │ ──► │ IN_PROGRESS  │ ──► │ PENDING_APPROVAL  │ ──► │ COMPLETED  │
└─────────────┘     └──────────────┘     └───────────────────┘     └────────────┘
                          │                       │
                          ▼                       │ (Manager vraća)
                    ┌──────────┐                  │
                    │ ON_HOLD  │ ◄────────────────┘
                    └──────────┘
```

- **Employee** može: NEW → IN_PROGRESS → ON_HOLD → PENDING_APPROVAL
- **Manager/Admin** može: PENDING_APPROVAL → COMPLETED (odobravanje)
- **Manager/Admin** može: PENDING_APPROVAL → IN_PROGRESS (vraćanje na doradu)

## Promjene u odnosu na početnu verziju

1. **Nova tablica `user_permissions`** - direktna dodjela permisija korisnicima
2. **Nova tablica `task_assignees`** - višestruka dodjela zadataka
3. **Novi status `PENDING_APPROVAL`** - workflow odobravanja zadataka
4. **Ažurirani viewovi** - uključuju nove tablice i relacije
4. **Backward compatibility** - `tasks.assigned_to` kolona ostaje za kompatibilnost
