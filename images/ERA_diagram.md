# ERA Dijagram - Ažurirani model s višestrukom dodjelom zadataka

## Mermaid kod za generiranje dijagrama

```mermaid
erDiagram
    USER ||--o{ USER_ROLE : "has"
    USER ||--o{ TASK : "creates"
    USER ||--o{ TASK_ASSIGNEE : "assigned_to"
    USER ||--o{ LOGIN_EVENT : "logs"
    USER ||--o{ AUDIT_LOG : "changes"
    USER }o--|| USER : "manager_of"
    
    ROLE ||--o{ USER_ROLE : "assigned_to"
    ROLE ||--o{ ROLE_PERMISSION : "has"
    
    PERMISSION ||--o{ ROLE_PERMISSION : "belongs_to"
    
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
| **task_assignees** | Task ↔ User | **NOVO** - Višestruka dodjela zadataka |

### Audit tablice
| Tablica | Opis |
|---------|------|
| **login_events** | Evidencija prijava u sustav |
| **audit_logs** | Evidencija promjena nad podacima |

## Kardinalnosti

- **User ↔ Role**: M:N (preko user_roles)
- **Role ↔ Permission**: M:N (preko role_permissions)  
- **Task ↔ User**: M:N (preko task_assignees) - **NOVO**
- **User → User**: 1:N (manager_id self-reference)
- **User → Task**: 1:N (created_by)
- **User → LoginEvent**: 1:N
- **User → AuditLog**: 1:N

## Promjene u odnosu na prethodnu verziju

1. **Nova tablica `task_assignees`** - omogućuje dodjelu istog zadatka više korisnika
2. **Ažuriran view `v_tasks_details`** - uključuje `assignee_ids` i `assignee_names` array-e
3. **Ažurirana funkcija `get_user_tasks`** - vraća zadatke iz nove tablice
4. **Backward compatibility** - `tasks.assigned_to` kolona ostaje za kompatibilnost
