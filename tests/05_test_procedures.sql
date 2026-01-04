-- ============================================================================
-- TEST 5: Procedures - CRUD Operations
-- ============================================================================
-- Testira sve procedure za kreiranje, azuriranje i brisanje podataka
-- ============================================================================

SET search_path TO employee_management;

\echo '--- Test 5.1: create_user() - kreiranje novog korisnika'
DO $$
DECLARE
    new_user_id INTEGER;
    user_exists BOOLEAN;
BEGIN
    CALL create_user(
        'test_user_proc',
        'testproc@example.com',
        '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewiAlL3x7WjF8sJ2',
        'Test',
        'Procedure',
        NULL,
        'EMPLOYEE',
        1,
        new_user_id
    );
    
    SELECT EXISTS(SELECT 1 FROM users WHERE user_id = new_user_id) INTO user_exists;
    
    IF user_exists THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'create_user', 'PASS', 
                FORMAT('Korisnik kreiran s ID: %s', new_user_id));
        RAISE NOTICE ' PASS: create_user() uspjesno kreirao korisnika ID: %', new_user_id;
        
        -- Cleanup (audit_log prvo)
        UPDATE audit_log SET changed_by = NULL WHERE changed_by = new_user_id;
        DELETE FROM audit_log WHERE entity_name = 'users' AND entity_id = new_user_id;
        DELETE FROM audit_log WHERE entity_name = 'user_roles' AND (new_value->>'user_id')::INTEGER = new_user_id;
        DELETE FROM user_roles WHERE user_id = new_user_id;
        DELETE FROM users WHERE user_id = new_user_id;
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'create_user', 'FAIL', 
                'Korisnik nije kreiran');
        RAISE NOTICE ' FAIL: create_user() nije kreirao korisnika';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'create_user', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: create_user() - %', SQLERRM;
END $$;

\echo '--- Test 5.2: create_user() - duplikat username'
DO $$
DECLARE
    new_user_id INTEGER;
BEGIN
    CALL create_user(
        'admin', -- Vec postoji
        'duplicate@example.com',
        'hash',
        'Dup',
        'User',
        NULL,
        'EMPLOYEE',
        1,
        new_user_id
    );
    
    INSERT INTO test_results (test_category, test_name, test_status, test_message)
    VALUES ('PROCEDURES', 'create_user duplicate username', 'FAIL', 
            'Duplikat username prihvacen');
    RAISE NOTICE ' FAIL: create_user() prihvaca duplicate username';
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'create_user duplicate username', 'PASS', 
                'Duplikat username odbijen');
        RAISE NOTICE ' PASS: create_user() odbija duplicate username';
END $$;

\echo '--- Test 5.3: update_user() - azuriranje korisnika'
DO $$
DECLARE
    test_user_id INTEGER;
    updated_name VARCHAR(50);
BEGIN
    -- Kreiraj test korisnika
    INSERT INTO users (username, email, password_hash, first_name, last_name)
    VALUES ('update_test', 'update@test.com', 'hash', 'Original', 'Name')
    RETURNING user_id INTO test_user_id;
    
    INSERT INTO user_roles (user_id, role_id)
    VALUES (test_user_id, (SELECT role_id FROM roles WHERE name = 'EMPLOYEE'));
    
    -- Azuriraj korisnika
    CALL update_user(
        test_user_id,
        'UpdatedName',
        NULL,
        NULL,
        NULL,
        NULL,
        1
    );
    
    -- Provjeri je li azuriran
    SELECT first_name INTO updated_name FROM users WHERE user_id = test_user_id;
    
    IF updated_name = 'UpdatedName' THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'update_user', 'PASS', 
                'Korisnik uspjesno azuriran');
        RAISE NOTICE ' PASS: update_user() uspjesno azurirao korisnika';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'update_user', 'FAIL', 
                FORMAT('Ime nije azurirano, dobiveno: %s', updated_name));
        RAISE NOTICE ' FAIL: update_user() nije azurirao ime';
    END IF;
    
    -- Cleanup (audit_log prvo)
    UPDATE audit_log SET changed_by = NULL WHERE changed_by = test_user_id;
    DELETE FROM audit_log WHERE entity_name = 'users' AND entity_id = test_user_id;
    DELETE FROM audit_log WHERE entity_name = 'user_roles' AND (new_value->>'user_id')::INTEGER = test_user_id;
    DELETE FROM user_roles WHERE user_id = test_user_id;
    DELETE FROM users WHERE user_id = test_user_id;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'update_user', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: update_user() - %', SQLERRM;
END $$;

\echo '--- Test 5.4: deactivate_user() - deaktivacija korisnika'
DO $$
DECLARE
    test_user_id INTEGER;
    is_active_after BOOLEAN;
BEGIN
    -- Kreiraj test korisnika
    INSERT INTO users (username, email, password_hash, first_name, last_name, is_active)
    VALUES ('deactivate_test', 'deactivate@test.com', 'hash', 'Deact', 'Test', TRUE)
    RETURNING user_id INTO test_user_id;
    
    INSERT INTO user_roles (user_id, role_id)
    VALUES (test_user_id, (SELECT role_id FROM roles WHERE name = 'EMPLOYEE'));
    
    -- Deaktiviraj korisnika
    CALL deactivate_user(test_user_id, 1);
    
    -- Provjeri je li deaktiviran
    SELECT is_active INTO is_active_after FROM users WHERE user_id = test_user_id;
    
    IF is_active_after = FALSE THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'deactivate_user', 'PASS', 
                'Korisnik uspjesno deaktiviran');
        RAISE NOTICE ' PASS: deactivate_user() uspjesno deaktivirao korisnika';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'deactivate_user', 'FAIL', 
                'Korisnik nije deaktiviran');
        RAISE NOTICE ' FAIL: deactivate_user() nije deaktivirao korisnika';
    END IF;
    
    -- Cleanup (audit_log prvo)
    UPDATE audit_log SET changed_by = NULL WHERE changed_by = test_user_id;
    DELETE FROM audit_log WHERE entity_name = 'users' AND entity_id = test_user_id;
    DELETE FROM audit_log WHERE entity_name = 'user_roles' AND (new_value->>'user_id')::INTEGER = test_user_id;
    DELETE FROM user_roles WHERE user_id = test_user_id;
    DELETE FROM users WHERE user_id = test_user_id;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'deactivate_user', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: deactivate_user() - %', SQLERRM;
END $$;

\echo '--- Test 5.5: create_task() - kreiranje novog zadatka'
DO $$
DECLARE
    new_task_id INTEGER;
    task_exists BOOLEAN;
    assignee_id INTEGER;
    v_due_date DATE;
BEGIN
    -- Dohvati assignee ID unaprijed (subquery ne radi u CALL)
    SELECT user_id INTO assignee_id FROM users WHERE username = 'marko_dev';
    v_due_date := CURRENT_DATE + 7;
    
    CALL create_task(
        'Test zadatak iz procedure'::VARCHAR(200),
        'Opis test zadatka'::TEXT,
        'HIGH'::task_priority,
        v_due_date,
        1, -- admin
        assignee_id,
        new_task_id
    );
    
    SELECT EXISTS(SELECT 1 FROM tasks WHERE task_id = new_task_id) INTO task_exists;
    
    IF task_exists THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'create_task', 'PASS', 
                FORMAT('Zadatak kreiran s ID: %s', new_task_id));
        RAISE NOTICE ' PASS: create_task() uspjesno kreirao zadatak ID: %', new_task_id;
        
        -- Cleanup
        DELETE FROM tasks WHERE task_id = new_task_id;
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'create_task', 'FAIL', 
                'Zadatak nije kreiran');
        RAISE NOTICE ' FAIL: create_task() nije kreirao zadatak';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'create_task', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: create_task() - %', SQLERRM;
END $$;

\echo '--- Test 5.6: update_task_status() - azuriranje statusa zadatka'
DO $$
DECLARE
    test_task_id INTEGER;
    updated_status task_status;
    marko_id INTEGER;
BEGIN
    SELECT user_id INTO marko_id FROM users WHERE username = 'marko_dev';
    
    -- Kreiraj test zadatak
    INSERT INTO tasks (title, description, status, priority, created_by, assigned_to)
    VALUES ('Status test task', 'Test', 'NEW', 'LOW', 1, marko_id)
    RETURNING task_id INTO test_task_id;
    
    -- Azuriraj status
    CALL update_task_status(test_task_id, 'IN_PROGRESS', marko_id);
    
    -- Provjeri je li azuriran
    SELECT status INTO updated_status FROM tasks WHERE task_id = test_task_id;
    
    IF updated_status = 'IN_PROGRESS' THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'update_task_status', 'PASS', 
                'Status zadatka uspjesno azuriran');
        RAISE NOTICE ' PASS: update_task_status() uspjesno azurirao status';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'update_task_status', 'FAIL', 
                FORMAT('Status nije azuriran, dobiveno: %s', updated_status));
        RAISE NOTICE ' FAIL: update_task_status() nije azurirao status';
    END IF;
    
    -- Cleanup
    DELETE FROM tasks WHERE task_id = test_task_id;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'update_task_status', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: update_task_status() - %', SQLERRM;
END $$;

\echo '--- Test 5.7: update_task_status() - COMPLETED postavlja completed_at'
DO $$
DECLARE
    test_task_id INTEGER;
    completion_time TIMESTAMP;
    marko_id INTEGER;
BEGIN
    SELECT user_id INTO marko_id FROM users WHERE username = 'marko_dev';
    
    -- Kreiraj test zadatak
    INSERT INTO tasks (title, description, status, priority, created_by, assigned_to)
    VALUES ('Completion test', 'Test', 'NEW', 'LOW', 1, marko_id)
    RETURNING task_id INTO test_task_id;
    
    -- Azuriraj na COMPLETED
    CALL update_task_status(test_task_id, 'COMPLETED', marko_id);
    
    -- Provjeri completed_at
    SELECT completed_at INTO completion_time FROM tasks WHERE task_id = test_task_id;
    
    IF completion_time IS NOT NULL THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'update_task_status completed_at', 'PASS', 
                'completed_at automatski postavljen');
        RAISE NOTICE ' PASS: update_task_status() postavlja completed_at';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'update_task_status completed_at', 'FAIL', 
                'completed_at nije postavljen');
        RAISE NOTICE ' FAIL: update_task_status() ne postavlja completed_at';
    END IF;
    
    -- Cleanup
    DELETE FROM tasks WHERE task_id = test_task_id;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'update_task_status completed_at', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: update_task_status() completed_at - %', SQLERRM;
END $$;

\echo '--- Test 5.8: assign_task() - dodjeljivanje zadatka'
DO $$
DECLARE
    test_task_id INTEGER;
    assigned_user INTEGER;
    petra_id INTEGER;
BEGIN
    SELECT user_id INTO petra_id FROM users WHERE username = 'petra_dev';
    
    -- Kreiraj test zadatak bez assignee-a
    INSERT INTO tasks (title, description, status, priority, created_by)
    VALUES ('Assign test', 'Test', 'NEW', 'LOW', 1)
    RETURNING task_id INTO test_task_id;
    
    -- Dodijeli zadatak
    CALL assign_task(test_task_id, petra_id, 1);
    
    -- Provjeri je li dodijeljen
    SELECT assigned_to INTO assigned_user FROM tasks WHERE task_id = test_task_id;
    
    IF assigned_user = petra_id THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'assign_task', 'PASS', 
                'Zadatak uspjesno dodijeljen');
        RAISE NOTICE ' PASS: assign_task() uspjesno dodijelio zadatak';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'assign_task', 'FAIL', 
                'Zadatak nije dodijeljen');
        RAISE NOTICE ' FAIL: assign_task() nije dodijelio zadatak';
    END IF;
    
    -- Cleanup
    DELETE FROM tasks WHERE task_id = test_task_id;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'assign_task', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: assign_task() - %', SQLERRM;
END $$;

\echo '--- Test 5.9: assign_role() - dodjeljivanje uloge'
DO $$
DECLARE
    test_user_id INTEGER;
    role_assigned BOOLEAN;
BEGIN
    -- Kreiraj test korisnika sa EMPLOYEE ulogom
    INSERT INTO users (username, email, password_hash, first_name, last_name)
    VALUES ('role_test', 'role@test.com', 'hash', 'Role', 'Test')
    RETURNING user_id INTO test_user_id;
    
    INSERT INTO user_roles (user_id, role_id)
    VALUES (test_user_id, (SELECT role_id FROM roles WHERE name = 'EMPLOYEE'));
    
    -- Dodijeli MANAGER ulogu
    CALL assign_role(test_user_id, 'MANAGER', 1);
    
    -- Provjeri je li dodijeljena
    SELECT EXISTS(
        SELECT 1 FROM user_roles ur
        JOIN roles r ON ur.role_id = r.role_id
        WHERE ur.user_id = test_user_id AND r.name = 'MANAGER'
    ) INTO role_assigned;
    
    IF role_assigned THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'assign_role', 'PASS', 
                'Uloga uspjesno dodijeljena');
        RAISE NOTICE ' PASS: assign_role() uspjesno dodijelio ulogu';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'assign_role', 'FAIL', 
                'Uloga nije dodijeljena');
        RAISE NOTICE ' FAIL: assign_role() nije dodijelio ulogu';
    END IF;
    
    -- Cleanup (audit_log prvo)
    UPDATE audit_log SET changed_by = NULL WHERE changed_by = test_user_id;
    DELETE FROM audit_log WHERE entity_name = 'users' AND entity_id = test_user_id;
    DELETE FROM audit_log WHERE entity_name = 'user_roles' AND (new_value->>'user_id')::INTEGER = test_user_id;
    DELETE FROM user_roles WHERE user_id = test_user_id;
    DELETE FROM users WHERE user_id = test_user_id;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'assign_role', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: assign_role() - %', SQLERRM;
END $$;

\echo '--- Test 5.10: revoke_role() - uklanjanje uloge'
DO $$
DECLARE
    test_user_id INTEGER;
    manager_role_id INTEGER;
    role_revoked BOOLEAN;
BEGIN
    -- Kreiraj test korisnika s 2 uloge
    INSERT INTO users (username, email, password_hash, first_name, last_name)
    VALUES ('revoke_test', 'revoke@test.com', 'hash', 'Revoke', 'Test')
    RETURNING user_id INTO test_user_id;
    
    SELECT role_id INTO manager_role_id FROM roles WHERE name = 'MANAGER';
    
    INSERT INTO user_roles (user_id, role_id)
    VALUES 
        (test_user_id, (SELECT role_id FROM roles WHERE name = 'EMPLOYEE')),
        (test_user_id, manager_role_id);
    
    -- Ukloni MANAGER ulogu
    CALL revoke_role(test_user_id, 'MANAGER', 1);
    
    -- Provjeri je li uklonjena
    SELECT NOT EXISTS(
        SELECT 1 FROM user_roles ur
        JOIN roles r ON ur.role_id = r.role_id
        WHERE ur.user_id = test_user_id AND r.name = 'MANAGER'
    ) INTO role_revoked;
    
    IF role_revoked THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'revoke_role', 'PASS', 
                'Uloga uspjesno uklonjena');
        RAISE NOTICE ' PASS: revoke_role() uspjesno uklonio ulogu';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'revoke_role', 'FAIL', 
                'Uloga nije uklonjena');
        RAISE NOTICE ' FAIL: revoke_role() nije uklonio ulogu';
    END IF;
    
    -- Cleanup (audit_log prvo)
    UPDATE audit_log SET changed_by = NULL WHERE changed_by = test_user_id;
    DELETE FROM audit_log WHERE entity_name = 'users' AND entity_id = test_user_id;
    DELETE FROM audit_log WHERE entity_name = 'user_roles' AND (new_value->>'user_id')::INTEGER = test_user_id;
    DELETE FROM audit_log WHERE entity_name = 'user_roles' AND (old_value->>'user_id')::INTEGER = test_user_id;
    DELETE FROM user_roles WHERE user_id = test_user_id;
    DELETE FROM users WHERE user_id = test_user_id;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('PROCEDURES', 'revoke_role', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: revoke_role() - %', SQLERRM;
END $$;

\echo ''
