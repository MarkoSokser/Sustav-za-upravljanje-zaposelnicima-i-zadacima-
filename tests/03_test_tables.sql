-- ============================================================================
-- TEST 3: Tables, Constraints and Relationships
-- ============================================================================
-- Testira strukturu tablica, constrainte i relacijske veze
-- ============================================================================

SET search_path TO employee_management;

\echo '--- Test 3.1: Unique constraint - username'
DO $$
BEGIN
    -- Pokusaj unosa dupliciranog usernamea
    INSERT INTO users (username, email, password_hash, first_name, last_name)
    VALUES ('admin', 'duplicate@test.com', 'hash', 'Test', 'User');
    
    INSERT INTO test_results (test_category, test_name, test_status, test_message)
    VALUES ('TABLES', 'Unique constraint username', 'FAIL', 
            'Duplicate username prihvacen');
    RAISE NOTICE ' FAIL: Duplicate username prihvacen';
EXCEPTION
    WHEN unique_violation THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TABLES', 'Unique constraint username', 'PASS', 
                'Duplicate username odbijen');
        RAISE NOTICE ' PASS: Unique constraint za username radi ispravno';
END $$;

\echo '--- Test 3.2: Unique constraint - email'
DO $$
BEGIN
    INSERT INTO users (username, email, password_hash, first_name, last_name)
    VALUES ('unique_user', 'admin@example.com', 'hash', 'Test', 'User');
    
    INSERT INTO test_results (test_category, test_name, test_status, test_message)
    VALUES ('TABLES', 'Unique constraint email', 'FAIL', 
            'Duplicate email prihvacen');
    RAISE NOTICE ' FAIL: Duplicate email prihvacen';
EXCEPTION
    WHEN unique_violation THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TABLES', 'Unique constraint email', 'PASS', 
                'Duplicate email odbijen');
        RAISE NOTICE ' PASS: Unique constraint za email radi ispravno';
END $$;

\echo '--- Test 3.3: Check constraint - korisnik ne moze biti sam sebi manager'
DO $$
DECLARE
    test_user_id INTEGER;
BEGIN
    INSERT INTO users (username, email, password_hash, first_name, last_name, manager_id)
    VALUES ('self_manager', 'self@test.com', 'hash', 'Self', 'Manager', 1)
    RETURNING user_id INTO test_user_id;
    
    -- Pokusaj postaviti managera na samog sebe
    UPDATE users SET manager_id = test_user_id WHERE user_id = test_user_id;
    
    -- Cleanup
    DELETE FROM users WHERE user_id = test_user_id;
    
    INSERT INTO test_results (test_category, test_name, test_status, test_message)
    VALUES ('TABLES', 'Check constraint self-manager', 'FAIL', 
            'Self-manager dopusten');
    RAISE NOTICE ' FAIL: Self-manager dopusten';
EXCEPTION
    WHEN check_violation THEN
        -- Cleanup
        ROLLBACK;
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TABLES', 'Check constraint self-manager', 'PASS', 
                'Self-manager odbijen');
        RAISE NOTICE ' PASS: Check constraint za self-manager radi ispravno';
END $$;

\echo '--- Test 3.4: Check constraint - task due_date >= created_at'
DO $$
BEGIN
    INSERT INTO tasks (title, description, status, priority, due_date, created_by, created_at)
    VALUES ('Invalid task', 'Test', 'NEW', 'LOW', '2020-01-01', 1, CURRENT_TIMESTAMP);
    
    DELETE FROM tasks WHERE title = 'Invalid task';
    
    INSERT INTO test_results (test_category, test_name, test_status, test_message)
    VALUES ('TABLES', 'Check constraint task due_date', 'FAIL', 
            'Due date prije created_at prihvacen');
    RAISE NOTICE ' FAIL: Due date prije created_at prihvacen';
EXCEPTION
    WHEN check_violation THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TABLES', 'Check constraint task due_date', 'PASS', 
                'Due date prije created_at odbijen');
        RAISE NOTICE ' PASS: Check constraint za due_date radi ispravno';
END $$;

\echo '--- Test 3.5: Check constraint - completed_at samo za COMPLETED status'
DO $$
BEGIN
    INSERT INTO tasks (title, description, status, priority, created_by, completed_at)
    VALUES ('Invalid completed', 'Test', 'NEW', 'LOW', 1, CURRENT_TIMESTAMP);
    
    DELETE FROM tasks WHERE title = 'Invalid completed';
    
    INSERT INTO test_results (test_category, test_name, test_status, test_message)
    VALUES ('TABLES', 'Check constraint completed_at', 'FAIL', 
            'Completed_at dopusten za non-completed task');
    RAISE NOTICE ' FAIL: Completed_at dopusten za non-completed task';
EXCEPTION
    WHEN check_violation THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TABLES', 'Check constraint completed_at', 'PASS', 
                'Completed_at odbijen za non-completed task');
        RAISE NOTICE ' PASS: Check constraint za completed_at radi ispravno';
END $$;

\echo '--- Test 3.6: Foreign key - manager_id references users'
DO $$
BEGIN
    INSERT INTO users (username, email, password_hash, first_name, last_name, manager_id)
    VALUES ('test_fk', 'fk@test.com', 'hash', 'Test', 'FK', 99999);
    
    DELETE FROM users WHERE username = 'test_fk';
    
    INSERT INTO test_results (test_category, test_name, test_status, test_message)
    VALUES ('TABLES', 'Foreign key manager_id', 'FAIL', 
            'Nepostojeci manager_id prihvacen');
    RAISE NOTICE ' FAIL: Nepostojeci manager_id prihvacen';
EXCEPTION
    WHEN foreign_key_violation THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TABLES', 'Foreign key manager_id', 'PASS', 
                'Nepostojeci manager_id odbijen');
        RAISE NOTICE ' PASS: Foreign key za manager_id radi ispravno';
END $$;

\echo '--- Test 3.7: Foreign key - task created_by ON DELETE RESTRICT'
DO $$
DECLARE
    test_user_id INTEGER;
    test_task_id INTEGER;
BEGIN
    -- Kreiraj test korisnika
    INSERT INTO users (username, email, password_hash, first_name, last_name)
    VALUES ('temp_creator', 'temp@test.com', 'hash', 'Temp', 'Creator')
    RETURNING user_id INTO test_user_id;
    
    -- Dodijeli mu ulogu
    INSERT INTO user_roles (user_id, role_id)
    VALUES (test_user_id, (SELECT role_id FROM roles WHERE name = 'EMPLOYEE'));
    
    -- Kreiraj task
    INSERT INTO tasks (title, description, status, priority, created_by)
    VALUES ('Test task', 'Test', 'NEW', 'LOW', test_user_id)
    RETURNING task_id INTO test_task_id;
    
    -- Pokusaj obrisati korisnika koji je kreirao task
    DELETE FROM users WHERE user_id = test_user_id;
    
    -- Cleanup
    DELETE FROM tasks WHERE task_id = test_task_id;
    DELETE FROM user_roles WHERE user_id = test_user_id;
    DELETE FROM users WHERE user_id = test_user_id;
    
    INSERT INTO test_results (test_category, test_name, test_status, test_message)
    VALUES ('TABLES', 'FK ON DELETE RESTRICT', 'FAIL', 
            'Brisanje kreatora zadatka dopusteno');
    RAISE NOTICE ' FAIL: Brisanje kreatora zadatka dopusteno';
EXCEPTION
    WHEN foreign_key_violation THEN
        -- Cleanup nakon greske
        DELETE FROM tasks WHERE task_id = test_task_id;
        DELETE FROM user_roles WHERE user_id = test_user_id;
        DELETE FROM users WHERE user_id = test_user_id;
        
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TABLES', 'FK ON DELETE RESTRICT', 'PASS', 
                'Brisanje kreatora zadatka odbijeno');
        RAISE NOTICE ' PASS: ON DELETE RESTRICT radi ispravno';
END $$;

\echo '--- Test 3.8: Foreign key - task assigned_to ON DELETE SET NULL'
DO $$
DECLARE
    test_user_id INTEGER;
    test_task_id INTEGER;
    assigned_after_delete INTEGER;
BEGIN
    -- Kreiraj test korisnika
    INSERT INTO users (username, email, password_hash, first_name, last_name)
    VALUES ('temp_assignee', 'assignee@test.com', 'hash', 'Temp', 'Assignee')
    RETURNING user_id INTO test_user_id;
    
    -- Dodijeli ulogu
    INSERT INTO user_roles (user_id, role_id)
    VALUES (test_user_id, (SELECT role_id FROM roles WHERE name = 'EMPLOYEE'));
    
    -- Kreiraj task (admin je creator, temp_assignee je assigned)
    INSERT INTO tasks (title, description, status, priority, created_by, assigned_to)
    VALUES ('Test assign', 'Test', 'NEW', 'LOW', 1, test_user_id)
    RETURNING task_id INTO test_task_id;
    
    -- Obrisi assignee-a (prvo cleanup audit_log)
    UPDATE audit_log SET changed_by = NULL WHERE changed_by = test_user_id;
    DELETE FROM audit_log WHERE entity_name = 'users' AND entity_id = test_user_id;
    DELETE FROM audit_log WHERE entity_name = 'user_roles' AND (new_value->>'user_id')::INTEGER = test_user_id;
    DELETE FROM user_roles WHERE user_id = test_user_id;
    DELETE FROM users WHERE user_id = test_user_id;
    
    -- Provjeri je li assigned_to postao NULL
    SELECT assigned_to INTO assigned_after_delete FROM tasks WHERE task_id = test_task_id;
    
    -- Cleanup
    DELETE FROM tasks WHERE task_id = test_task_id;
    
    IF assigned_after_delete IS NULL THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TABLES', 'FK ON DELETE SET NULL', 'PASS', 
                'assigned_to postavljen na NULL nakon brisanja');
        RAISE NOTICE ' PASS: ON DELETE SET NULL radi ispravno';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TABLES', 'FK ON DELETE SET NULL', 'FAIL', 
                'assigned_to nije postavljen na NULL');
        RAISE NOTICE ' FAIL: ON DELETE SET NULL ne radi ispravno';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TABLES', 'FK ON DELETE SET NULL', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: ON DELETE SET NULL - %', SQLERRM;
END $$;

\echo '--- Test 3.9: Foreign key - user_roles CASCADE DELETE'
DO $$
DECLARE
    test_user_id INTEGER;
    role_count INTEGER;
BEGIN
    -- Kreiraj test korisnika
    INSERT INTO users (username, email, password_hash, first_name, last_name)
    VALUES ('cascade_test', 'cascade@test.com', 'hash', 'Cascade', 'Test')
    RETURNING user_id INTO test_user_id;
    
    -- Dodijeli ulogu
    INSERT INTO user_roles (user_id, role_id)
    VALUES (test_user_id, (SELECT role_id FROM roles WHERE name = 'EMPLOYEE'));
    
    -- Obrisi korisnika (prvo cleanup audit_log)
    UPDATE audit_log SET changed_by = NULL WHERE changed_by = test_user_id;
    DELETE FROM audit_log WHERE entity_name = 'users' AND entity_id = test_user_id;
    DELETE FROM audit_log WHERE entity_name = 'user_roles' AND (new_value->>'user_id')::INTEGER = test_user_id;
    DELETE FROM users WHERE user_id = test_user_id;
    
    -- Provjeri jesu li role assignments obrisani
    SELECT COUNT(*) INTO role_count FROM user_roles WHERE user_id = test_user_id;
    
    IF role_count = 0 THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TABLES', 'FK CASCADE DELETE', 'PASS', 
                'user_roles obrisan CASCADE-om');
        RAISE NOTICE ' PASS: CASCADE DELETE radi ispravno';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TABLES', 'FK CASCADE DELETE', 'FAIL', 
                'user_roles nije obrisan CASCADE-om');
        RAISE NOTICE ' FAIL: CASCADE DELETE ne radi ispravno';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TABLES', 'FK CASCADE DELETE', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: CASCADE DELETE - %', SQLERRM;
END $$;

\echo '--- Test 3.10: NOT NULL constraints'
DO $$
BEGIN
    -- Test NOT NULL za username
    INSERT INTO users (email, password_hash, first_name, last_name)
    VALUES ('nouser@test.com', 'hash', 'No', 'Username');
    
    DELETE FROM users WHERE email = 'nouser@test.com';
    
    INSERT INTO test_results (test_category, test_name, test_status, test_message)
    VALUES ('TABLES', 'NOT NULL constraints', 'FAIL', 
            'NULL vrijednost prihvacena za NOT NULL polje');
    RAISE NOTICE ' FAIL: NULL vrijednost prihvacena';
EXCEPTION
    WHEN not_null_violation THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TABLES', 'NOT NULL constraints', 'PASS', 
                'NULL vrijednost odbijen za NOT NULL polje');
        RAISE NOTICE ' PASS: NOT NULL constraints rade ispravno';
END $$;

\echo ''
