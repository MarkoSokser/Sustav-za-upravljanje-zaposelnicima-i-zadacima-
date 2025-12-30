-- Migracija za višestruku dodjelu zadataka
-- Omogućuje dodjeljivanje istog zadatka više osoba

SET search_path TO employee_management;

-- ============================================================
-- 1. KREIRANJE NOVE TABLICE ZA VIŠESTRUKE DODIJELE
-- ============================================================

-- Tablica za M:N vezu između tasks i users
CREATE TABLE IF NOT EXISTS task_assignees (
    task_assignee_id SERIAL PRIMARY KEY,
    task_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by INTEGER,
    
    CONSTRAINT fk_task_assignees_task FOREIGN KEY (task_id) 
        REFERENCES tasks(task_id) ON DELETE CASCADE,
    CONSTRAINT fk_task_assignees_user FOREIGN KEY (user_id) 
        REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_task_assignees_assigned_by FOREIGN KEY (assigned_by) 
        REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_task_assignees UNIQUE (task_id, user_id)
);

COMMENT ON TABLE task_assignees IS 'Povezna tablica - dodjela zadataka korisnicima (M:N veza)';
COMMENT ON COLUMN task_assignees.task_assignee_id IS 'Jedinstveni identifikator veze';
COMMENT ON COLUMN task_assignees.task_id IS 'ID zadatka';
COMMENT ON COLUMN task_assignees.user_id IS 'ID korisnika kojem je zadatak dodijeljen';
COMMENT ON COLUMN task_assignees.assigned_at IS 'Datum i vrijeme dodjele';
COMMENT ON COLUMN task_assignees.assigned_by IS 'ID korisnika koji je dodijelio zadatak';

-- Indeksi za brže pretrazivanje
CREATE INDEX IF NOT EXISTS idx_task_assignees_task ON task_assignees(task_id);
CREATE INDEX IF NOT EXISTS idx_task_assignees_user ON task_assignees(user_id);


-- ============================================================
-- 2. MIGRACIJA POSTOJEĆIH PODATAKA
-- ============================================================

-- Prenesi postojeće dodjele iz tasks.assigned_to u task_assignees
INSERT INTO task_assignees (task_id, user_id, assigned_at, assigned_by)
SELECT task_id, assigned_to, created_at, created_by
FROM tasks 
WHERE assigned_to IS NOT NULL
ON CONFLICT (task_id, user_id) DO NOTHING;


-- ============================================================
-- 3. AŽURIRANJE VIEW-a ZA TASKS
-- ============================================================

-- Dropaj stari view
DROP VIEW IF EXISTS v_tasks_details;

-- Kreiraj novi view s podrškom za više dodijeljenih korisnika
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
    -- Backward compatibility: vraća prvog assignee-a ili iz stare kolone
    COALESCE(
        (SELECT ta.user_id FROM task_assignees ta WHERE ta.task_id = t.task_id LIMIT 1),
        t.assigned_to
    ) AS assignee_id,
    COALESCE(
        (SELECT u.username FROM task_assignees ta JOIN users u ON ta.user_id = u.user_id WHERE ta.task_id = t.task_id LIMIT 1),
        a.username
    ) AS assignee_username,
    COALESCE(
        (SELECT u.first_name || ' ' || u.last_name FROM task_assignees ta JOIN users u ON ta.user_id = u.user_id WHERE ta.task_id = t.task_id LIMIT 1),
        a.first_name || ' ' || a.last_name
    ) AS assignee_name,
    -- Novi stupci za sve dodijeljene korisnike
    (SELECT ARRAY_AGG(ta.user_id) FROM task_assignees ta WHERE ta.task_id = t.task_id) AS assignee_ids,
    (SELECT ARRAY_AGG(u.username) FROM task_assignees ta JOIN users u ON ta.user_id = u.user_id WHERE ta.task_id = t.task_id) AS assignee_usernames,
    (SELECT ARRAY_AGG(u.first_name || ' ' || u.last_name) FROM task_assignees ta JOIN users u ON ta.user_id = u.user_id WHERE ta.task_id = t.task_id) AS assignee_names,
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

COMMENT ON VIEW v_tasks_details IS 'Detaljni pregled zadataka s informacijama o kreatoru i dodijeljenim korisnicima';


-- ============================================================
-- 4. AŽURIRANJE FUNKCIJE get_user_tasks
-- ============================================================

-- NAPOMENA: Funkcija vraća is_overdue stupac i koristi eksplicitne castove za username_type -> VARCHAR
DROP FUNCTION IF EXISTS get_user_tasks(INTEGER, task_status, BOOLEAN);

CREATE FUNCTION get_user_tasks(
    p_user_id INTEGER,
    p_status task_status DEFAULT NULL,
    p_include_created BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    task_id INTEGER,
    title VARCHAR(200),
    description TEXT,
    status task_status,
    priority task_priority,
    due_date DATE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    completed_at TIMESTAMP,
    creator_id INTEGER,
    creator_username VARCHAR(50),
    creator_name TEXT,
    assignee_id INTEGER,
    assignee_username VARCHAR(50),
    assignee_name TEXT,
    assignee_ids INTEGER[],
    assignee_names TEXT[],
    due_status TEXT,
    is_overdue BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        v.task_id,
        v.title,
        v.description,
        v.status,
        v.priority,
        v.due_date,
        v.created_at,
        v.updated_at,
        v.completed_at,
        v.creator_id,
        v.creator_username::VARCHAR(50),
        v.creator_name,
        v.assignee_id,
        v.assignee_username::VARCHAR(50),
        v.assignee_name,
        v.assignee_ids,
        v.assignee_names,
        v.due_status,
        (v.due_status = 'OVERDUE') as is_overdue
    FROM v_tasks_details v
    LEFT JOIN task_assignees ta ON v.task_id = ta.task_id
    WHERE 
        (ta.user_id = p_user_id OR v.assignee_id = p_user_id OR (p_include_created AND v.creator_id = p_user_id))
        AND (p_status IS NULL OR v.status = p_status)
    ORDER BY v.priority DESC, v.due_date NULLS LAST;
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- 5. AŽURIRANJE VIEW-a v_user_statistics
-- ============================================================

DROP VIEW IF EXISTS v_user_statistics;

CREATE VIEW v_user_statistics AS
SELECT 
    u.user_id,
    u.username,
    u.first_name || ' ' || u.last_name AS full_name,
    u.is_active,
    COUNT(DISTINCT t_created.task_id) AS tasks_created,
    -- Ukljuci i zadatke iz nove tablice
    (SELECT COUNT(DISTINCT ta.task_id) FROM task_assignees ta WHERE ta.user_id = u.user_id) +
    COUNT(DISTINCT t_assigned.task_id) AS tasks_assigned,
    (SELECT COUNT(DISTINCT ta.task_id) FROM task_assignees ta 
     JOIN tasks t ON ta.task_id = t.task_id 
     WHERE ta.user_id = u.user_id AND t.status = 'COMPLETED') +
    COUNT(DISTINCT t_completed.task_id) AS tasks_completed,
    (SELECT COUNT(DISTINCT ta.task_id) FROM task_assignees ta 
     JOIN tasks t ON ta.task_id = t.task_id 
     WHERE ta.user_id = u.user_id AND t.status NOT IN ('COMPLETED', 'CANCELLED')) +
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


-- ============================================================
-- 6. PROCEDURA ZA DODJELU ZADATKA KORISNICIMA
-- ============================================================

CREATE OR REPLACE PROCEDURE assign_task_to_users(
    p_task_id INTEGER,
    p_user_ids INTEGER[],
    p_assigned_by INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id INTEGER;
BEGIN
    -- Provjera da zadatak postoji
    IF NOT EXISTS (SELECT 1 FROM tasks WHERE task_id = p_task_id) THEN
        RAISE EXCEPTION 'Zadatak s ID % ne postoji', p_task_id;
    END IF;
    
    -- Dodaj svakog korisnika
    FOREACH v_user_id IN ARRAY p_user_ids
    LOOP
        -- Provjeri da korisnik postoji i aktivan je
        IF NOT EXISTS (SELECT 1 FROM users WHERE user_id = v_user_id AND is_active = TRUE) THEN
            RAISE EXCEPTION 'Korisnik s ID % ne postoji ili nije aktivan', v_user_id;
        END IF;
        
        -- Dodaj dodjelu (ignoriraj duplikate)
        INSERT INTO task_assignees (task_id, user_id, assigned_by)
        VALUES (p_task_id, v_user_id, p_assigned_by)
        ON CONFLICT (task_id, user_id) DO NOTHING;
    END LOOP;
    
    -- Ažuriraj i staru kolonu za backward compatibility (prvi korisnik)
    UPDATE tasks 
    SET assigned_to = p_user_ids[1],
        updated_at = CURRENT_TIMESTAMP
    WHERE task_id = p_task_id;
END;
$$;


-- ============================================================
-- 7. PROCEDURA ZA UKLANJANJE DODJELE
-- ============================================================

CREATE OR REPLACE PROCEDURE unassign_task_from_user(
    p_task_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM task_assignees 
    WHERE task_id = p_task_id AND user_id = p_user_id;
    
    -- Ako je uklonjen korisnik iz stare kolone, postavi na sljedećeg
    UPDATE tasks 
    SET assigned_to = (
        SELECT user_id FROM task_assignees 
        WHERE task_id = p_task_id 
        LIMIT 1
    ),
    updated_at = CURRENT_TIMESTAMP
    WHERE task_id = p_task_id AND assigned_to = p_user_id;
END;
$$;


-- ============================================================
-- 8. TRIGGER ZA SINKRONIZACIJU (BACKWARD COMPATIBILITY)
-- ============================================================

-- Trigger koji sinkronizira staru assigned_to kolonu s novom tablicom
CREATE OR REPLACE FUNCTION sync_task_assignees()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        -- Kada se postavi assigned_to direktno, dodaj i u novu tablicu
        IF NEW.assigned_to IS NOT NULL AND NEW.assigned_to != OLD.assigned_to THEN
            INSERT INTO task_assignees (task_id, user_id, assigned_by)
            VALUES (NEW.task_id, NEW.assigned_to, NEW.created_by)
            ON CONFLICT (task_id, user_id) DO NOTHING;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Ukloni trigger ako postoji
DROP TRIGGER IF EXISTS trg_sync_task_assignees ON tasks;

-- Kreiraj trigger
CREATE TRIGGER trg_sync_task_assignees
AFTER INSERT OR UPDATE OF assigned_to ON tasks
FOR EACH ROW
EXECUTE FUNCTION sync_task_assignees();


SELECT 'Migracija za višestruku dodjelu zadataka uspješno završena!' AS status;
