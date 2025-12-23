
-- Interni sustav za upravljanje zaposlenicima i zadacima
-- PostgreSQL 14+

DROP SCHEMA IF EXISTS employee_management CASCADE;


CREATE SCHEMA employee_management;
SET search_path TO employee_management;

 

CREATE TYPE task_status AS ENUM (
    'NEW',           
    'IN_PROGRESS',   
    'ON_HOLD',       
    'COMPLETED',     
    'CANCELLED'      
);


CREATE TYPE task_priority AS ENUM (
    'LOW',           
    'MEDIUM',        
    'HIGH',          
    'URGENT'         
);


CREATE TYPE audit_action AS ENUM (
    'INSERT',        
    'UPDATE',        
    'DELETE'         
);


-- COMPOSITE TIPOVI 

CREATE TYPE timestamp_metadata AS (
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TYPE address_info AS (
    street VARCHAR(200),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100)
);


-- DOMENE (za validaciju podataka)

CREATE DOMAIN email_address AS VARCHAR(100)
    CHECK (VALUE ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

CREATE DOMAIN username_type AS VARCHAR(50)
    CHECK (VALUE ~* '^[a-zA-Z0-9_]{3,50}$');



CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username username_type NOT NULL,
    email email_address NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    manager_id INTEGER,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    

    CONSTRAINT uk_users_username UNIQUE (username),
    CONSTRAINT uk_users_email UNIQUE (email),
    CONSTRAINT fk_users_manager FOREIGN KEY (manager_id) 
        REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_users_manager_not_self CHECK (manager_id != user_id)
);


COMMENT ON TABLE users IS 'Korisnici sustava - zaposlenici organizacije';
COMMENT ON COLUMN users.user_id IS 'Jedinstveni identifikator korisnika';
COMMENT ON COLUMN users.username IS 'Korisnicko ime za prijavu (jedinstveno)';
COMMENT ON COLUMN users.email IS 'E-mail adresa korisnika (jedinstvena)';
COMMENT ON COLUMN users.password_hash IS 'Hash lozinke (bcrypt)';
COMMENT ON COLUMN users.first_name IS 'Ime korisnika';
COMMENT ON COLUMN users.last_name IS 'Prezime korisnika';
COMMENT ON COLUMN users.manager_id IS 'ID nadjredjenog managera (hijerarhija tima)';
COMMENT ON COLUMN users.is_active IS 'Status racuna (TRUE=aktivan, FALSE=deaktiviran)';
COMMENT ON COLUMN users.created_at IS 'Datum i vrijeme kreiranja racuna';
COMMENT ON COLUMN users.updated_at IS 'Datum i vrijeme zadnje izmjene';


CREATE TABLE roles (
    role_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    is_system BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
  
    CONSTRAINT uk_roles_name UNIQUE (name),
    CONSTRAINT chk_roles_name_not_empty CHECK (LENGTH(TRIM(name)) > 0)
);

COMMENT ON TABLE roles IS 'Uloge korisnika u sustavu (RBAC)';
COMMENT ON COLUMN roles.role_id IS 'Jedinstveni identifikator uloge';
COMMENT ON COLUMN roles.name IS 'Naziv uloge (ADMIN, MANAGER, EMPLOYEE)';
COMMENT ON COLUMN roles.description IS 'Opis uloge i njenih ovlasti';
COMMENT ON COLUMN roles.is_system IS 'Sistemska uloga koja se ne može obrisati';
COMMENT ON COLUMN roles.created_at IS 'Datum kreiranja uloge';
COMMENT ON COLUMN roles.updated_at IS 'Datum zadnje izmjene uloge';


CREATE TABLE permissions (
    permission_id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
   
    CONSTRAINT uk_permissions_code UNIQUE (code),
    CONSTRAINT chk_permissions_code_format CHECK (code ~* '^[A-Z_]+$'),
    CONSTRAINT chk_permissions_category CHECK (category IN ('USER', 'ROLE', 'TASK', 'AUDIT'))
);

COMMENT ON TABLE permissions IS 'Pojedinacna prava pristupa funkcionalnostima';
COMMENT ON COLUMN permissions.permission_id IS 'Jedinstveni identifikator prava';
COMMENT ON COLUMN permissions.code IS 'Jedinstveni kod prava (npr. TASK_CREATE)';
COMMENT ON COLUMN permissions.name IS 'Citljiv naziv prava';
COMMENT ON COLUMN permissions.description IS 'Detaljan opis prava';
COMMENT ON COLUMN permissions.category IS 'Kategorija prava (USER, ROLE, TASK, AUDIT)';


CREATE TABLE tasks (
    task_id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    status task_status NOT NULL DEFAULT 'NEW',
    priority task_priority NOT NULL DEFAULT 'MEDIUM',
    due_date DATE,
    created_by INTEGER NOT NULL,
    assigned_to INTEGER,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    
 
    CONSTRAINT fk_tasks_created_by FOREIGN KEY (created_by) 
        REFERENCES users(user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_tasks_assigned_to FOREIGN KEY (assigned_to) 
        REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_tasks_title_not_empty CHECK (LENGTH(TRIM(title)) > 0),
    CONSTRAINT chk_tasks_due_date CHECK (due_date IS NULL OR due_date >= DATE(created_at)),
    CONSTRAINT chk_tasks_completed_at CHECK (
        (status != 'COMPLETED' AND completed_at IS NULL) OR
        (status = 'COMPLETED' AND completed_at IS NOT NULL)
    )
);

COMMENT ON TABLE tasks IS 'Zadaci dodijeljeni zaposlenicima';
COMMENT ON COLUMN tasks.task_id IS 'Jedinstveni identifikator zadatka';
COMMENT ON COLUMN tasks.title IS 'Naziv zadatka';
COMMENT ON COLUMN tasks.description IS 'Detaljan opis zadatka';
COMMENT ON COLUMN tasks.status IS 'Status zadatka (NEW, IN_PROGRESS, ON_HOLD, COMPLETED, CANCELLED)';
COMMENT ON COLUMN tasks.priority IS 'Prioritet zadatka (LOW, MEDIUM, HIGH, URGENT)';
COMMENT ON COLUMN tasks.due_date IS 'Rok zavr\u0161etka zadatka';
COMMENT ON COLUMN tasks.created_by IS 'ID korisnika koji je kreirao zadatak';
COMMENT ON COLUMN tasks.assigned_to IS 'ID korisnika kojem je zadatak dodijeljen';
COMMENT ON COLUMN tasks.completed_at IS 'Datum i vrijeme zavr\u0161etka zadatka';




CREATE TABLE user_roles (
    user_role_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    role_id INTEGER NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by INTEGER,
    
    
    CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) 
        REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) 
        REFERENCES roles(role_id) ON DELETE RESTRICT,
    CONSTRAINT fk_user_roles_assigned_by FOREIGN KEY (assigned_by) 
        REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_user_roles UNIQUE (user_id, role_id)
);

COMMENT ON TABLE user_roles IS 'Povezna tablica - dodjela uloga korisnicima';
COMMENT ON COLUMN user_roles.user_role_id IS 'Jedinstveni identifikator veze';
COMMENT ON COLUMN user_roles.user_id IS 'ID korisnika';
COMMENT ON COLUMN user_roles.role_id IS 'ID uloge';
COMMENT ON COLUMN user_roles.assigned_at IS 'Datum dodjele uloge';
COMMENT ON COLUMN user_roles.assigned_by IS 'ID korisnika koji je dodijelio ulogu';


CREATE TABLE role_permissions (
    role_permission_id SERIAL PRIMARY KEY,
    role_id INTEGER NOT NULL,
    permission_id INTEGER NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    
    CONSTRAINT fk_role_permissions_role FOREIGN KEY (role_id) 
        REFERENCES roles(role_id) ON DELETE CASCADE,
    CONSTRAINT fk_role_permissions_permission FOREIGN KEY (permission_id) 
        REFERENCES permissions(permission_id) ON DELETE CASCADE,
    CONSTRAINT uk_role_permissions UNIQUE (role_id, permission_id)
);

COMMENT ON TABLE role_permissions IS 'Povezna tablica - dodjela prava ulogama';
COMMENT ON COLUMN role_permissions.role_permission_id IS 'Jedinstveni identifikator veze';
COMMENT ON COLUMN role_permissions.role_id IS 'ID uloge';
COMMENT ON COLUMN role_permissions.permission_id IS 'ID prava';
COMMENT ON COLUMN role_permissions.assigned_at IS 'Datum dodjele prava ulozi';


CREATE TABLE login_events (
    login_event_id SERIAL PRIMARY KEY,
    user_id INTEGER,
    username_attempted VARCHAR(50) NOT NULL,
    login_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address INET NOT NULL,
    user_agent TEXT,
    success BOOLEAN NOT NULL,
    failure_reason VARCHAR(100),
    
    
    CONSTRAINT fk_login_events_user FOREIGN KEY (user_id) 
        REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_login_events_failure CHECK (
        (success = TRUE AND failure_reason IS NULL) OR
        (success = FALSE)
    )
);

COMMENT ON TABLE login_events IS 'Evidencija pokusaja prijave u sustav';
COMMENT ON COLUMN login_events.login_event_id IS 'Jedinstveni identifikator prijave';
COMMENT ON COLUMN login_events.user_id IS 'ID korisnika (NULL ako korisnik ne postoji)';
COMMENT ON COLUMN login_events.username_attempted IS 'Korisnicko ime koristeno pri prijavi';
COMMENT ON COLUMN login_events.login_time IS 'Vrijeme pokusaja prijave';
COMMENT ON COLUMN login_events.ip_address IS 'IP adresa klijenta';
COMMENT ON COLUMN login_events.user_agent IS 'Informacije o pregledniku/klijentu';
COMMENT ON COLUMN login_events.success IS 'Uspjesnost prijave (TRUE/FALSE)';
COMMENT ON COLUMN login_events.failure_reason IS 'Razlog neuspjeha (INVALID_CREDENTIALS, ACCOUNT_INACTIVE, ACCOUNT_LOCKED)';


CREATE TABLE audit_log (
    audit_log_id SERIAL PRIMARY KEY,
    entity_name VARCHAR(50) NOT NULL,
    entity_id INTEGER NOT NULL,
    action audit_action NOT NULL,
    changed_by INTEGER,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    old_value JSONB,
    new_value JSONB,
    ip_address INET,
    
 
    CONSTRAINT fk_audit_log_changed_by FOREIGN KEY (changed_by) 
        REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_audit_log_entity CHECK (entity_name IN ('users', 'roles', 'tasks', 'user_roles', 'role_permissions')),
    CONSTRAINT chk_audit_log_values CHECK (
        (action = 'INSERT' AND old_value IS NULL AND new_value IS NOT NULL) OR
        (action = 'UPDATE' AND old_value IS NOT NULL AND new_value IS NOT NULL) OR
        (action = 'DELETE' AND old_value IS NOT NULL AND new_value IS NULL)
    )
);

COMMENT ON TABLE audit_log IS 'Evidencija svih promjena nad osjetljivim podacima';
COMMENT ON COLUMN audit_log.audit_log_id IS 'Jedinstveni identifikator audit zapisa';
COMMENT ON COLUMN audit_log.entity_name IS 'Naziv tablice koja je promijenjena';
COMMENT ON COLUMN audit_log.entity_id IS 'ID zapisa koji je promijenjen';
COMMENT ON COLUMN audit_log.action IS 'Vrsta akcije (INSERT, UPDATE, DELETE)';
COMMENT ON COLUMN audit_log.changed_by IS 'ID korisnika koji je izvršio promjenu';
COMMENT ON COLUMN audit_log.changed_at IS 'Vrijeme promjene';
COMMENT ON COLUMN audit_log.old_value IS 'Prethodno stanje (JSONB)';
COMMENT ON COLUMN audit_log.new_value IS 'Novo stanje (JSONB)';
COMMENT ON COLUMN audit_log.ip_address IS 'IP adresa korisnika';




CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_manager ON users(manager_id) WHERE manager_id IS NOT NULL;
CREATE INDEX idx_users_active ON users(is_active);
CREATE INDEX idx_users_full_name ON users(last_name, first_name);


CREATE INDEX idx_roles_name ON roles(name);
CREATE INDEX idx_roles_system ON roles(is_system);


CREATE INDEX idx_permissions_code ON permissions(code);
CREATE INDEX idx_permissions_category ON permissions(category);


CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to) WHERE assigned_to IS NOT NULL;
CREATE INDEX idx_tasks_created_by ON tasks(created_by);
CREATE INDEX idx_tasks_due_date ON tasks(due_date) WHERE due_date IS NOT NULL;
CREATE INDEX idx_tasks_active ON tasks(status) WHERE status NOT IN ('COMPLETED', 'CANCELLED');


CREATE INDEX idx_user_roles_user ON user_roles(user_id);
CREATE INDEX idx_user_roles_role ON user_roles(role_id);


CREATE INDEX idx_role_permissions_role ON role_permissions(role_id);
CREATE INDEX idx_role_permissions_permission ON role_permissions(permission_id);


CREATE INDEX idx_login_events_user ON login_events(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_login_events_time ON login_events(login_time DESC);
CREATE INDEX idx_login_events_success ON login_events(success);
CREATE INDEX idx_login_events_ip ON login_events(ip_address);


CREATE INDEX idx_audit_log_entity ON audit_log(entity_name, entity_id);
CREATE INDEX idx_audit_log_changed_by ON audit_log(changed_by) WHERE changed_by IS NOT NULL;
CREATE INDEX idx_audit_log_time ON audit_log(changed_at DESC);
CREATE INDEX idx_audit_log_action ON audit_log(action);


-- POGLEDI (VIEWS)
-- Pogled: Korisnici s njihovim ulogama

CREATE VIEW v_users_with_roles AS
SELECT 
    u.user_id,
    u.username,
    u.email,
    u.first_name,
    u.last_name,
    u.is_active,
    m.username AS manager_username,
    m.first_name || ' ' || m.last_name AS manager_full_name,
    ARRAY_AGG(r.name ORDER BY r.name) AS roles,
    u.created_at,
    u.updated_at
FROM users u
LEFT JOIN users m ON u.manager_id = m.user_id
LEFT JOIN user_roles ur ON u.user_id = ur.user_id
LEFT JOIN roles r ON ur.role_id = r.role_id
GROUP BY u.user_id, u.username, u.email, u.first_name, u.last_name, 
         u.is_active, m.username, m.first_name, m.last_name, u.created_at, u.updated_at;

COMMENT ON VIEW v_users_with_roles IS 'Pregled korisnika s njihovim ulogama i managerom';


-- Pogled: Uloge s pravima
CREATE VIEW v_roles_with_permissions AS
SELECT 
    r.role_id,
    r.name AS role_name,
    r.description AS role_description,
    r.is_system,
    ARRAY_AGG(p.code ORDER BY p.category, p.code) AS permissions,
    COUNT(DISTINCT ur.user_id) AS user_count
FROM roles r
LEFT JOIN role_permissions rp ON r.role_id = rp.role_id
LEFT JOIN permissions p ON rp.permission_id = p.permission_id
LEFT JOIN user_roles ur ON r.role_id = ur.role_id
GROUP BY r.role_id, r.name, r.description, r.is_system;

COMMENT ON VIEW v_roles_with_permissions IS 'Pregled uloga s dodijeljenim pravima';


-- Pogled: Zadaci s detaljima

CREATE VIEW v_tasks_details AS
SELECT 
    t.task_id,
    t.title,
    t.description,
    t.status,
    t.priority,
    t.due_date,
    t.created_at,
    t.updated_at,
    t.completed_at,
    c.user_id AS creator_id,
    c.username AS creator_username,
    c.first_name || ' ' || c.last_name AS creator_name,
    a.user_id AS assignee_id,
    a.username AS assignee_username,
    a.first_name || ' ' || a.last_name AS assignee_name,
    CASE 
        WHEN t.due_date IS NULL THEN NULL
        WHEN t.status IN ('COMPLETED', 'CANCELLED') THEN NULL
        WHEN t.due_date < CURRENT_DATE THEN 'OVERDUE'
        WHEN t.due_date = CURRENT_DATE THEN 'DUE_TODAY'
        WHEN t.due_date <= CURRENT_DATE + INTERVAL '3 days' THEN 'DUE_SOON'
        ELSE 'ON_TRACK'
    END AS due_status
FROM tasks t
JOIN users c ON t.created_by = c.user_id
LEFT JOIN users a ON t.assigned_to = a.user_id;

COMMENT ON VIEW v_tasks_details IS 'Detaljni pregled zadataka s informacijama o kreatoru i dodijeljenom korisniku';


-- Pogled: Statistika korisnika

CREATE VIEW v_user_statistics AS
SELECT 
    u.user_id,
    u.username,
    u.first_name || ' ' || u.last_name AS full_name,
    u.is_active,
    COUNT(DISTINCT t_created.task_id) AS tasks_created,
    COUNT(DISTINCT t_assigned.task_id) AS tasks_assigned,
    COUNT(DISTINCT t_completed.task_id) AS tasks_completed,
    COUNT(DISTINCT t_active.task_id) AS tasks_active,
    (SELECT COUNT(*) FROM login_events le WHERE le.user_id = u.user_id AND le.success = TRUE) AS successful_logins,
    (SELECT MAX(login_time) FROM login_events le WHERE le.user_id = u.user_id AND le.success = TRUE) AS last_login
FROM users u
LEFT JOIN tasks t_created ON u.user_id = t_created.created_by
LEFT JOIN tasks t_assigned ON u.user_id = t_assigned.assigned_to
LEFT JOIN tasks t_completed ON u.user_id = t_completed.assigned_to AND t_completed.status = 'COMPLETED'
LEFT JOIN tasks t_active ON u.user_id = t_active.assigned_to AND t_active.status NOT IN ('COMPLETED', 'CANCELLED')
GROUP BY u.user_id, u.username, u.first_name, u.last_name, u.is_active;

COMMENT ON VIEW v_user_statistics IS 'Statistika aktivnosti korisnika';


-- Pogled: Tim managera

CREATE VIEW v_manager_team AS
SELECT 
    m.user_id AS manager_id,
    m.username AS manager_username,
    m.first_name || ' ' || m.last_name AS manager_name,
    e.user_id AS employee_id,
    e.username AS employee_username,
    e.first_name || ' ' || e.last_name AS employee_name,
    e.email AS employee_email,
    e.is_active AS employee_active,
    ARRAY_AGG(DISTINCT r.name) AS employee_roles
FROM users m
JOIN users e ON e.manager_id = m.user_id
LEFT JOIN user_roles ur ON e.user_id = ur.user_id
LEFT JOIN roles r ON ur.role_id = r.role_id
GROUP BY m.user_id, m.username, m.first_name, m.last_name,
         e.user_id, e.username, e.first_name, e.last_name, e.email, e.is_active;

COMMENT ON VIEW v_manager_team IS 'Pregled clanova tima za svakog managera';
