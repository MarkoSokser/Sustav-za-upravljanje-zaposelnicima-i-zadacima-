-- =====================================================
-- MIGRACIJA: Dodavanje PENDING_APPROVAL statusa
-- =====================================================
-- Ovaj status omogućuje workflow gdje:
-- 1. Employee označava zadatak kao "završen" -> PENDING_APPROVAL
-- 2. Manager/Admin pregledava i odobrava -> COMPLETED
-- =====================================================
-- POKRETANJE: Pokrenite ovu skriptu u pgAdmin Query Tool
-- ili: psql -U postgres -d employee_db -f 06_pending_approval_migration.sql
-- =====================================================

-- Prebaci se na employee_management shemu
SET search_path TO employee_management, public;

-- Dodaj novi status u ENUM tip
ALTER TYPE task_status ADD VALUE IF NOT EXISTS 'PENDING_APPROVAL' BEFORE 'COMPLETED';

-- Potvrda
SELECT unnest(enum_range(NULL::task_status)) AS available_statuses;

-- Ažuriraj proceduru update_task_status da koristi logiku odobravanja
CREATE OR REPLACE PROCEDURE update_task_status(
    p_task_id INTEGER,
    p_new_status VARCHAR(20),
    p_changed_by INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status VARCHAR(20);
    v_creator_id INTEGER;
    v_is_assignee BOOLEAN;
    v_is_manager_or_admin BOOLEAN;
BEGIN
    -- Dohvati trenutni status i kreatora
    SELECT status, created_by INTO v_current_status, v_creator_id
    FROM tasks WHERE task_id = p_task_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Zadatak ID % ne postoji', p_task_id;
    END IF;
    
    -- Provjeri je li korisnik assignee
    SELECT EXISTS (
        SELECT 1 FROM task_assignees 
        WHERE task_id = p_task_id AND user_id = p_changed_by
    ) OR EXISTS (
        SELECT 1 FROM tasks 
        WHERE task_id = p_task_id AND assigned_to = p_changed_by
    ) INTO v_is_assignee;
    
    -- Provjeri je li manager ili admin
    SELECT EXISTS (
        SELECT 1 FROM user_roles ur
        JOIN roles r ON ur.role_id = r.role_id
        WHERE ur.user_id = p_changed_by AND r.name IN ('ADMIN', 'MANAGER')
    ) INTO v_is_manager_or_admin;
    
    -- Pravila za promjenu statusa:
    
    -- 1. Završeni i otkazani zadaci se ne mogu mijenjati
    IF v_current_status IN ('COMPLETED', 'CANCELLED') THEN
        RAISE EXCEPTION 'Zadatak je već završen ili otkazan i ne može se mijenjati';
    END IF;
    
    -- 2. Employee može staviti samo na PENDING_APPROVAL (ne direktno COMPLETED)
    IF NOT v_is_manager_or_admin AND p_new_status = 'COMPLETED' THEN
        RAISE EXCEPTION 'Samo manager ili admin mogu završiti zadatak. Koristite "Predaj na odobrenje".';
    END IF;
    
    -- 3. Samo manager/admin mogu odobriti PENDING_APPROVAL -> COMPLETED
    IF v_current_status = 'PENDING_APPROVAL' AND p_new_status = 'COMPLETED' THEN
        IF NOT v_is_manager_or_admin THEN
            RAISE EXCEPTION 'Samo manager ili admin mogu odobriti završetak zadatka';
        END IF;
    END IF;
    
    -- 4. Manager/Admin mogu odbiti PENDING_APPROVAL -> vratiti na IN_PROGRESS
    -- (ovo je dozvoljeno automatski)
    
    -- Ažuriraj status
    UPDATE tasks 
    SET status = p_new_status::task_status,
        updated_at = CURRENT_TIMESTAMP,
        completed_at = CASE 
            WHEN p_new_status = 'COMPLETED' THEN CURRENT_TIMESTAMP 
            ELSE completed_at 
        END
    WHERE task_id = p_task_id;
    
    RAISE NOTICE 'Status zadatka % promijenjen iz % u %', p_task_id, v_current_status, p_new_status;
END;
$$;

-- Ažuriraj view da uključuje PENDING_APPROVAL
CREATE OR REPLACE VIEW v_tasks_details AS
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
    t.created_by AS creator_id,
    creator.username AS creator_username,
    creator.first_name || ' ' || creator.last_name AS creator_name,
    t.assigned_to AS assignee_id,
    assignee.username AS assignee_username,
    assignee.first_name || ' ' || assignee.last_name AS assignee_name,
    -- Lista svih assignee-a
    (SELECT array_agg(ta.user_id) FROM task_assignees ta WHERE ta.task_id = t.task_id) AS assignee_ids,
    (SELECT array_agg(u.first_name || ' ' || u.last_name) FROM task_assignees ta JOIN users u ON ta.user_id = u.user_id WHERE ta.task_id = t.task_id) AS assignee_names,
    -- Renamed to created_by_name for frontend compatibility
    creator.first_name || ' ' || creator.last_name AS created_by_name,
    -- Status roka
    CASE 
        WHEN t.status IN ('COMPLETED', 'CANCELLED') THEN 'DONE'
        WHEN t.due_date IS NULL THEN 'NO_DUE_DATE'
        WHEN t.due_date < CURRENT_DATE THEN 'OVERDUE'
        WHEN t.due_date = CURRENT_DATE THEN 'DUE_TODAY'
        WHEN t.due_date <= CURRENT_DATE + INTERVAL '3 days' THEN 'DUE_SOON'
        ELSE 'ON_TRACK'
    END AS due_status
FROM tasks t
LEFT JOIN users creator ON t.created_by = creator.user_id
LEFT JOIN users assignee ON t.assigned_to = assignee.user_id;

COMMIT;

SELECT 'Migracija PENDING_APPROVAL uspješno završena!' AS status;
