
-- TEST NAPREDNIH FUNKCIJA - RULES & LIKE

SET search_path TO employee_management;

-- Spremi trenutni broj error-a
DO $$ 
BEGIN 
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '  TEST 08: NAPREDNE FUNKCIJE';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
END $$;


-- =========================================
-- TEST 1: LIKE KLAUZULA - TASKS_ARCHIVE
-- =========================================

DO $$
DECLARE
    v_test_name TEXT := 'TEST 1: tasks_archive tablica kreirana pomocu LIKE';
    v_column_count INTEGER;
    v_has_pk BOOLEAN;
BEGIN
    -- Provjeri da li tablica postoji
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'employee_management' 
        AND table_name = 'tasks_archive'
    ) THEN
        RAISE NOTICE ' %: Tablica tasks_archive ne postoji!', v_test_name;
        RETURN;
    END IF;

    -- Provjeri broj kolona (trebalo bi imati sve iz tasks + 3 dodatne)
    SELECT COUNT(*) INTO v_column_count
    FROM information_schema.columns
    WHERE table_schema = 'employee_management' 
    AND table_name = 'tasks_archive';

    -- Provjeri primary key
    SELECT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_schema = 'employee_management'
        AND table_name = 'tasks_archive'
        AND constraint_type = 'PRIMARY KEY'
    ) INTO v_has_pk;

    IF v_column_count >= 13 AND v_has_pk THEN
        RAISE NOTICE ' %: OK (% kolona, PK postoji)', v_test_name, v_column_count;
    ELSE
        RAISE NOTICE ' %: Greska (kolone: %, PK: %)', v_test_name, v_column_count, v_has_pk;
    END IF;

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE ' %: Error - %', v_test_name, SQLERRM;
END $$;


-- =========================================
-- TEST 2: RULE - prevent_system_role_delete
-- =========================================

DO $$
DECLARE
    v_test_name TEXT := 'TEST 2: Zastita sistemskih uloga od brisanja';
    v_count_before INTEGER;
    v_count_after INTEGER;
BEGIN
    -- Broji sistemske uloge prije pokusaja brisanja
    SELECT COUNT(*) INTO v_count_before
    FROM roles WHERE is_system = TRUE;


    -- Pokusaj brisanja sistemske uloge (trebao bi biti ignoriran)
    DELETE FROM roles WHERE name = 'ADMIN';

    -- Broji sistemske uloge nakon pokusaja brisanja
    SELECT COUNT(*) INTO v_count_after
    FROM roles WHERE is_system = TRUE;

    IF v_count_before = v_count_after AND v_count_after >= 3 THEN
        RAISE NOTICE ' %: OK (% sistemskih uloga ostalo netaknuto)', v_test_name, v_count_after;
    ELSE
        RAISE NOTICE ' %: Sistemska uloga je obrisana! (prije: %, poslije: %)', 
                     v_test_name, v_count_before, v_count_after;
    END IF;

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE ' %: Error - %', v_test_name, SQLERRM;
END $$;


-- =========================================
-- TEST 3: RULE - log_user_delete_attempt
-- =========================================

DO $$
DECLARE
    v_test_name TEXT := 'TEST 3: Automatski audit log pri brisanju korisnika';
    v_test_user_id INTEGER;
    v_audit_count INTEGER;
    v_audit_details JSONB;
BEGIN

    -- Kreiraj test korisnika (bez role_id, jer veza ide preko user_roles)
    INSERT INTO users (username, email, password_hash, first_name, last_name)
    VALUES ('test_user_delete', 'test.delete@test.com', 'hash123', 'Test', 'DeleteUser')
    RETURNING user_id INTO v_test_user_id;

    -- Dodijeli mu ulogu EMPLOYEE
    PERFORM user_id FROM user_roles WHERE user_id = v_test_user_id AND role_id = (SELECT role_id FROM roles WHERE name = 'EMPLOYEE');
    IF NOT FOUND THEN
        INSERT INTO user_roles (user_id, role_id, assigned_by)
        VALUES (v_test_user_id, (SELECT role_id FROM roles WHERE name = 'EMPLOYEE'), v_test_user_id);
    END IF;

    -- Obrisi test korisnika (trebao bi automatski kreirati audit log)
    DELETE FROM users WHERE user_id = v_test_user_id;


    -- Provjeri da li je audit log kreiran
    SELECT COUNT(*) INTO v_audit_count
    FROM audit_log
    WHERE entity_name = 'users' 
    AND entity_id = v_test_user_id
    AND action = 'DELETE';

    SELECT old_value INTO v_audit_details
    FROM audit_log
    WHERE entity_name = 'users' 
    AND entity_id = v_test_user_id
    AND action = 'DELETE'
    LIMIT 1;

    IF v_audit_count = 1 AND v_audit_details->>'username' = 'test_user_delete' THEN
        RAISE NOTICE ' %: OK (audit log automatski kreiran)', v_test_name;
    ELSE
        RAISE NOTICE ' %: Audit log nije kreiran! (count: %)', v_test_name, v_audit_count;
    END IF;

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE ' %: Error - %', v_test_name, SQLERRM;
END $$;


-- =========================================
-- TEST 4: RULE - auto_archive_old_completed
-- =========================================

DO $$
DECLARE
    v_test_name TEXT := 'TEST 4: Automatska arhivacija starih zavrsenih zadataka';
    v_test_task_id INTEGER;
    v_archive_count INTEGER;
BEGIN

    -- Kreiraj stari zavrseni zadatak (simuliraj da je stariji od 180 dana, completed_at je obavezan!)
    INSERT INTO tasks (title, description, status, priority, created_by, updated_at, completed_at)
    VALUES (
        'Stari zadatak za arhiviranje',
        'Test zadatak stariji od 180 dana',
        'COMPLETED',
        'LOW',
        (SELECT user_id FROM users WHERE username = 'admin' LIMIT 1),
        CURRENT_TIMESTAMP - INTERVAL '181 days',
        CURRENT_TIMESTAMP - INTERVAL '181 days'
    )
    RETURNING task_id INTO v_test_task_id;

    -- Azuriraj zadatak da triggeruje RULE
    UPDATE tasks 
    SET status = 'COMPLETED', 
        updated_at = CURRENT_TIMESTAMP - INTERVAL '181 days'
    WHERE task_id = v_test_task_id;

    -- Provjeri da li je zadatak arhiviran
    SELECT COUNT(*) INTO v_archive_count
    FROM tasks_archive
    WHERE task_id = v_test_task_id;

    IF v_archive_count >= 1 THEN
        RAISE NOTICE ' %: OK (zadatak automatski arhiviran)', v_test_name;
        -- Cleanup
        DELETE FROM tasks_archive WHERE task_id = v_test_task_id;
    ELSE
        RAISE NOTICE '  %: Zadatak nije arhiviran (RULE se aktivira samo za UPDATE na vec starima)', v_test_name;
    END IF;

    -- Cleanup
    DELETE FROM tasks WHERE task_id = v_test_task_id;

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE ' %: Error - %', v_test_name, SQLERRM;
END $$;


-- =========================================
-- TEST 5: RULE - prevent_completed_task_edit
-- =========================================

DO $$
DECLARE
    v_test_name TEXT := 'TEST 5: Zastita zavrsenih zadataka od izmjena';
    v_test_task_id INTEGER;
    v_title_before TEXT;
    v_title_after TEXT;
BEGIN

    -- Kreiraj i odmah zavrsi zadatak (completed_at je obavezan!)
    INSERT INTO tasks (title, description, status, priority, created_by, completed_at)
    VALUES (
        'Zavrseni zadatak',
        'Ne bi trebao biti izmjenjiv',
        'COMPLETED',
        'MEDIUM',
        (SELECT user_id FROM users WHERE username = 'admin' LIMIT 1),
        CURRENT_TIMESTAMP
    )
    RETURNING task_id, title INTO v_test_task_id, v_title_before;

    -- Pokusaj izmjene naslova (trebao bi biti ignoriran)
    UPDATE tasks
    SET title = 'IZMIJENJENI NASLOV'
    WHERE task_id = v_test_task_id;

    -- Provjeri je li naslov ostao isti
    SELECT title INTO v_title_after
    FROM tasks
    WHERE task_id = v_test_task_id;

    IF v_title_before = v_title_after THEN
        RAISE NOTICE ' %: OK (zavrseni zadatak zasticen od izmjena)', v_test_name;
    ELSE
        RAISE NOTICE ' %: Zavrseni zadatak je izmjenjen! (prije: "%", poslije: "%")', 
                     v_test_name, v_title_before, v_title_after;
    END IF;

    -- Cleanup
    DELETE FROM tasks WHERE task_id = v_test_task_id;

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE ' %: Error - %', v_test_name, SQLERRM;
END $$;


-- =========================================
-- TEST 6: Provjera svih RULES
-- =========================================

DO $$
DECLARE
    v_test_name TEXT := 'TEST 6: Provjera da su svi RULES kreirani';
    v_rule_count INTEGER;
    v_rules TEXT[];
BEGIN
    SELECT COUNT(*), array_agg(rulename ORDER BY rulename)
    INTO v_rule_count, v_rules
    FROM pg_rules
    WHERE schemaname = 'employee_management'
    AND rulename IN (
        'prevent_system_role_delete',
        'log_user_delete_attempt',
        'auto_archive_old_completed',
        'prevent_completed_task_edit'
    );

    IF v_rule_count = 4 THEN
        RAISE NOTICE ' %: OK (svi 4 RULES kreirani)', v_test_name;
        RAISE NOTICE '   Aktivna pravila: %', array_to_string(v_rules, ', ');
    ELSE
        RAISE NOTICE ' %: Nedostaju RULES! (pronadeno: %, ocekivano: 4)', 
                     v_test_name, v_rule_count;
        IF v_rules IS NOT NULL THEN
            RAISE NOTICE '   Pronadeni: %', array_to_string(v_rules, ', ');
        END IF;
    END IF;

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE ' %: Error - %', v_test_name, SQLERRM;
END $$;


