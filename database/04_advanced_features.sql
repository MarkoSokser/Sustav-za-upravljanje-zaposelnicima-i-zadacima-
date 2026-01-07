
SET search_path TO employee_management;


-- 1. LIKE KLAUZULA - ARHIVNA TABLICA ZA ZADATKE

-- Arhivna tablica za zadatke (za završene/otkazane zadatke)
DROP TABLE IF EXISTS tasks_archive CASCADE;
CREATE TABLE tasks_archive (
    LIKE tasks INCLUDING DEFAULTS INCLUDING COMMENTS,
    archived_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    archived_by INTEGER,
    archive_reason TEXT
);

-- Dodaj primary key (LIKE ne kopira SERIAL/IDENTITY)
ALTER TABLE tasks_archive ADD PRIMARY KEY (task_id);

COMMENT ON TABLE tasks_archive IS 'Arhiva zavrsenih/otkazanih zadataka - kreirana pomocu LIKE klauzule. Automatski se puni putem RULE auto_archive_old_completed.';


-- 2. RULES - PRAVILA ZA AUTOMATSKU ZAŠTITU



-- RULE 1: Sprijeci brisanje sistemskih uloga
-- Kada netko pokuša DELETE FROM roles WHERE is_system = TRUE, 
-- upit se jednostavno ignorira
DROP RULE IF EXISTS prevent_system_role_delete ON roles;
CREATE RULE prevent_system_role_delete AS
    ON DELETE TO roles
    WHERE OLD.is_system = TRUE
    DO INSTEAD NOTHING;

COMMENT ON RULE prevent_system_role_delete ON roles IS 
'Sprijecava brisanje sistemskih uloga (ADMIN, MANAGER, EMPLOYEE). Aktivira se automatski.';


-- RULE 2: Automatski logiraj pokusaj brisanja korisnika
-- Svaki DELETE na users tablici automatski kreira audit log zapis
DROP RULE IF EXISTS log_user_delete_attempt ON users;
CREATE RULE log_user_delete_attempt AS
    ON DELETE TO users
    DO ALSO (
        INSERT INTO audit_log (entity_name, entity_id, action, old_value, new_value)
        VALUES (
            'users', 
            OLD.user_id, 
            'DELETE',
            jsonb_build_object(
                'username', OLD.username,
                'email', OLD.email,
                'first_name', OLD.first_name,
                'last_name', OLD.last_name,
                'deleted_at', CURRENT_TIMESTAMP
            ),
            NULL
        )
    );

COMMENT ON RULE log_user_delete_attempt ON users IS 
'Automatski logira svaki pokusaj brisanja korisnika u audit_log tablicu.';


-- RULE 3: Automatski arhiviraj stare zavrsene zadatke
-- Kada se ažurira zadatak koji je COMPLETED/CANCELLED i stariji od 180 dana,
-- automatski se kopira u tasks_archive
DROP RULE IF EXISTS auto_archive_old_completed ON tasks;
CREATE RULE auto_archive_old_completed AS
    ON UPDATE TO tasks
    WHERE NEW.status IN ('COMPLETED', 'CANCELLED') 
    AND NEW.updated_at < CURRENT_TIMESTAMP - INTERVAL '180 days'
    DO ALSO (
        INSERT INTO tasks_archive (
            task_id, title, description, status, priority, due_date,
            created_by, assigned_to, created_at, updated_at, completed_at,
            archived_at, archived_by, archive_reason
        )
        SELECT 
            NEW.task_id, NEW.title, NEW.description, NEW.status, NEW.priority, NEW.due_date,
            NEW.created_by, NEW.assigned_to, NEW.created_at, NEW.updated_at, NEW.completed_at,
            CURRENT_TIMESTAMP, NULL, 'Auto-arhivirano pravilom (starije od 180 dana)'
        WHERE NOT EXISTS (SELECT 1 FROM tasks_archive WHERE task_id = NEW.task_id)
    );

COMMENT ON RULE auto_archive_old_completed ON tasks IS 
'Automatski arhivira zavrsene/otkazane zadatke starije od 180 dana u tasks_archive tablicu.';


-- RULE 4: Sprijeci izmjenu zavrsenih/otkazanih zadataka
-- Jednom kad je zadatak COMPLETED ili CANCELLED, ne može se više mijenjati
-- (osim statusa koji se može vratiti nazad ako treba)
DROP RULE IF EXISTS prevent_completed_task_edit ON tasks;
CREATE RULE prevent_completed_task_edit AS
    ON UPDATE TO tasks
    WHERE OLD.status IN ('COMPLETED', 'CANCELLED')
    AND (
        NEW.title != OLD.title OR
        NEW.description IS DISTINCT FROM OLD.description OR
        NEW.priority != OLD.priority OR
        NEW.due_date IS DISTINCT FROM OLD.due_date OR
        NEW.created_by != OLD.created_by OR
        NEW.assigned_to IS DISTINCT FROM OLD.assigned_to
    )
    DO INSTEAD NOTHING;

COMMENT ON RULE prevent_completed_task_edit ON tasks IS 
'Sprijecava izmjenu zavrsenih ili otkazanih zadataka (osim promjene statusa).';

