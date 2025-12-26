-- ============================================================================
-- TEST 6: Triggers - Audit, Validation, Auto-Update
-- ============================================================================
-- Testira sve triggere u sustavu
-- ============================================================================

SET search_path TO employee_management;

\echo '--- Test 6.1: Trigger audit_users_changes - INSERT'
DO $$
DECLARE
    test_user_id INTEGER;
    audit_count INTEGER;
BEGIN
    -- Kreiraj korisnika
    INSERT INTO users (username, email, password_hash, first_name, last_name)
    VALUES ('audit_insert_test', 'audit_insert@test.com', 'hash', 'Audit', 'Insert')
    RETURNING user_id INTO test_user_id;
    
    INSERT INTO user_roles (user_id, role_id)
    VALUES (test_user_id, (SELECT role_id FROM roles WHERE name = 'EMPLOYEE'));
    
    -- Provjeri audit log
    SELECT COUNT(*) INTO audit_count
    FROM audit_log
    WHERE entity_name = 'users' 
    AND entity_id = test_user_id 
    AND action = 'INSERT';
    
    IF audit_count > 0 THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'audit_users_changes INSERT', 'PASS', 
                'INSERT audit zapis kreiran');
        RAISE NOTICE ' PASS: Audit trigger za users INSERT radi ispravno';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'audit_users_changes INSERT', 'FAIL', 
                'INSERT audit zapis nije kreiran');
        RAISE NOTICE ' FAIL: Audit trigger za users INSERT ne radi';
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
        VALUES ('TRIGGERS', 'audit_users_changes INSERT', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: Audit trigger INSERT - %', SQLERRM;
END $$;

\echo '--- Test 6.2: Trigger audit_users_changes - UPDATE'
DO $$
DECLARE
    test_user_id INTEGER;
    audit_count INTEGER;
BEGIN
    -- Kreiraj korisnika
    INSERT INTO users (username, email, password_hash, first_name, last_name)
    VALUES ('audit_update_test', 'audit_update@test.com', 'hash', 'Original', 'Name')
    RETURNING user_id INTO test_user_id;
    
    INSERT INTO user_roles (user_id, role_id)
    VALUES (test_user_id, (SELECT role_id FROM roles WHERE name = 'EMPLOYEE'));
    
    -- Azuriraj korisnika
    UPDATE users SET first_name = 'Updated' WHERE user_id = test_user_id;
    
    -- Provjeri audit log
    SELECT COUNT(*) INTO audit_count
    FROM audit_log
    WHERE entity_name = 'users' 
    AND entity_id = test_user_id 
    AND action = 'UPDATE'
    AND old_value->>'first_name' = 'Original'
    AND new_value->>'first_name' = 'Updated';
    
    IF audit_count > 0 THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'audit_users_changes UPDATE', 'PASS', 
                'UPDATE audit zapis kreiran s ispravnim podacima');
        RAISE NOTICE ' PASS: Audit trigger za users UPDATE radi ispravno';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'audit_users_changes UPDATE', 'FAIL', 
                'UPDATE audit zapis nije kreiran ili nema ispravne podatke');
        RAISE NOTICE ' FAIL: Audit trigger za users UPDATE ne radi';
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
        VALUES ('TRIGGERS', 'audit_users_changes UPDATE', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: Audit trigger UPDATE - %', SQLERRM;
END $$;

\echo '--- Test 6.3: Trigger audit_users_changes - DELETE'
DO $$
DECLARE
    test_user_id INTEGER;
    audit_count INTEGER;
BEGIN
    -- Kreiraj korisnika
    INSERT INTO users (username, email, password_hash, first_name, last_name)
    VALUES ('audit_delete_test', 'audit_delete@test.com', 'hash', 'Delete', 'Test')
    RETURNING user_id INTO test_user_id;
    
    INSERT INTO user_roles (user_id, role_id)
    VALUES (test_user_id, (SELECT role_id FROM roles WHERE name = 'EMPLOYEE'));
    
    -- Cleanup audit_log references prije brisanja
    UPDATE audit_log SET changed_by = NULL WHERE changed_by = test_user_id;
    DELETE FROM audit_log WHERE entity_name = 'user_roles' AND (new_value->>'user_id')::INTEGER = test_user_id;
    
    -- Obrisi korisnika
    DELETE FROM user_roles WHERE user_id = test_user_id;
    DELETE FROM users WHERE user_id = test_user_id;
    
    -- Provjeri audit log
    SELECT COUNT(*) INTO audit_count
    FROM audit_log
    WHERE entity_name = 'users' 
    AND entity_id = test_user_id 
    AND action = 'DELETE';
    
    IF audit_count > 0 THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'audit_users_changes DELETE', 'PASS', 
                'DELETE audit zapis kreiran');
        RAISE NOTICE ' PASS: Audit trigger za users DELETE radi ispravno';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'audit_users_changes DELETE', 'FAIL', 
                'DELETE audit zapis nije kreiran');
        RAISE NOTICE ' FAIL: Audit trigger za users DELETE ne radi';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'audit_users_changes DELETE', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: Audit trigger DELETE - %', SQLERRM;
END $$;

\echo '--- Test 6.4: Trigger audit_tasks_changes - INSERT'
DO $$
DECLARE
    test_task_id INTEGER;
    audit_count INTEGER;
BEGIN
    -- Kreiraj zadatak
    INSERT INTO tasks (title, description, status, priority, created_by)
    VALUES ('Audit task test', 'Test', 'NEW', 'LOW', 1)
    RETURNING task_id INTO test_task_id;
    
    -- Provjeri audit log
    SELECT COUNT(*) INTO audit_count
    FROM audit_log
    WHERE entity_name = 'tasks' 
    AND entity_id = test_task_id 
    AND action = 'INSERT';
    
    IF audit_count > 0 THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'audit_tasks_changes INSERT', 'PASS', 
                'Task INSERT audit zapis kreiran');
        RAISE NOTICE ' PASS: Audit trigger za tasks INSERT radi ispravno';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'audit_tasks_changes INSERT', 'FAIL', 
                'Task INSERT audit zapis nije kreiran');
        RAISE NOTICE ' FAIL: Audit trigger za tasks INSERT ne radi';
    END IF;
    
    -- Cleanup
    DELETE FROM tasks WHERE task_id = test_task_id;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'audit_tasks_changes INSERT', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: Audit trigger tasks INSERT - %', SQLERRM;
END $$;

\echo '--- Test 6.5: Trigger update_updated_at_column - users'
DO $$
DECLARE
    test_user_id INTEGER;
    created_time TIMESTAMP;
    updated_time TIMESTAMP;
BEGIN
    -- Kreiraj korisnika
    INSERT INTO users (username, email, password_hash, first_name, last_name)
    VALUES ('update_at_test', 'updateat@test.com', 'hash', 'Test', 'User')
    RETURNING user_id, created_at INTO test_user_id, created_time;
    
    INSERT INTO user_roles (user_id, role_id)
    VALUES (test_user_id, (SELECT role_id FROM roles WHERE name = 'EMPLOYEE'));
    
    -- cekaj malo
    PERFORM pg_sleep(0.1);
    
    -- Azuriraj korisnika
    UPDATE users SET first_name = 'Updated' WHERE user_id = test_user_id;
    
    -- Provjeri updated_at (koristimo >= jer u istoj transakciji mogu biti jednaki)
    SELECT updated_at INTO updated_time FROM users WHERE user_id = test_user_id;
    
    IF updated_time >= created_time THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'update_updated_at users', 'PASS', 
                'updated_at automatski azuriran');
        RAISE NOTICE ' PASS: Auto-update trigger za users radi ispravno';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'update_updated_at users', 'FAIL', 
                'updated_at nije azuriran');
        RAISE NOTICE ' FAIL: Auto-update trigger za users ne radi';
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
        VALUES ('TRIGGERS', 'update_updated_at users', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: Auto-update trigger users - %', SQLERRM;
END $$;

\echo '--- Test 6.6: Trigger update_updated_at_column - tasks'
DO $$
DECLARE
    test_task_id INTEGER;
    created_time TIMESTAMP;
    updated_time TIMESTAMP;
BEGIN
    -- Kreiraj zadatak
    INSERT INTO tasks (title, description, status, priority, created_by)
    VALUES ('Update at task', 'Test', 'NEW', 'LOW', 1)
    RETURNING task_id, created_at INTO test_task_id, created_time;
    
    -- cekaj malo
    PERFORM pg_sleep(0.1);
    
    -- Azuriraj zadatak
    UPDATE tasks SET priority = 'HIGH' WHERE task_id = test_task_id;
    
    -- Provjeri updated_at (koristimo >= jer u istoj transakciji mogu biti jednaki)
    SELECT updated_at INTO updated_time FROM tasks WHERE task_id = test_task_id;
    
    IF updated_time >= created_time THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'update_updated_at tasks', 'PASS', 
                'updated_at automatski azuriran');
        RAISE NOTICE ' PASS: Auto-update trigger za tasks radi ispravno';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'update_updated_at tasks', 'FAIL', 
                'updated_at nije azuriran');
        RAISE NOTICE ' FAIL: Auto-update trigger za tasks ne radi';
    END IF;
    
    -- Cleanup
    DELETE FROM tasks WHERE task_id = test_task_id;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'update_updated_at tasks', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: Auto-update trigger tasks - %', SQLERRM;
END $$;

\echo '--- Test 6.7: Trigger validate_manager_hierarchy - self reference'
DO $$
DECLARE
    test_user_id INTEGER;
BEGIN
    -- Kreiraj korisnika
    INSERT INTO users (username, email, password_hash, first_name, last_name)
    VALUES ('hierarchy_test', 'hierarchy@test.com', 'hash', 'Hierarchy', 'Test')
    RETURNING user_id INTO test_user_id;
    
    INSERT INTO user_roles (user_id, role_id)
    VALUES (test_user_id, (SELECT role_id FROM roles WHERE name = 'EMPLOYEE'));
    
    -- Pokusaj postaviti managera na samog sebe
    UPDATE users SET manager_id = test_user_id WHERE user_id = test_user_id;
    
    -- Ako dodemo ovdje, trigger nije radio (cleanup i fail)
    UPDATE audit_log SET changed_by = NULL WHERE changed_by = test_user_id;
    DELETE FROM audit_log WHERE entity_name = 'users' AND entity_id = test_user_id;
    DELETE FROM audit_log WHERE entity_name = 'user_roles' AND (new_value->>'user_id')::INTEGER = test_user_id;
    DELETE FROM user_roles WHERE user_id = test_user_id;
    DELETE FROM users WHERE user_id = test_user_id;
    
    INSERT INTO test_results (test_category, test_name, test_status, test_message)
    VALUES ('TRIGGERS', 'validate_manager_hierarchy self', 'FAIL', 
            'Self-manager dopusten');
    RAISE NOTICE ' FAIL: Manager hierarchy trigger ne sprjecava self-reference';
EXCEPTION
    WHEN OTHERS THEN
        -- Ocekivana greska
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'validate_manager_hierarchy self', 'PASS', 
                'Self-manager odbijen');
        RAISE NOTICE ' PASS: Manager hierarchy trigger sprjecava self-reference';
        
        -- Cleanup (audit_log prvo)
        UPDATE audit_log SET changed_by = NULL WHERE changed_by = test_user_id;
        DELETE FROM audit_log WHERE entity_name = 'users' AND entity_id = test_user_id;
        DELETE FROM audit_log WHERE entity_name = 'user_roles' AND (new_value->>'user_id')::INTEGER = test_user_id;
        DELETE FROM user_roles WHERE user_id = test_user_id;
        DELETE FROM users WHERE user_id = test_user_id;
END $$;

\echo '--- Test 6.8: Trigger validate_manager_hierarchy - circular reference'
DO $$
DECLARE
    user1_id INTEGER;
    user2_id INTEGER;
BEGIN
    -- Kreiraj prvog korisnika
    INSERT INTO users (username, email, password_hash, first_name, last_name)
    VALUES ('circular1', 'circular1@test.com', 'hash', 'User', 'One')
    RETURNING user_id INTO user1_id;
    
    INSERT INTO user_roles (user_id, role_id)
    VALUES (user1_id, (SELECT role_id FROM roles WHERE name = 'EMPLOYEE'));
    
    -- Kreiraj drugog korisnika s user1 kao managerom
    INSERT INTO users (username, email, password_hash, first_name, last_name, manager_id)
    VALUES ('circular2', 'circular2@test.com', 'hash', 'User', 'Two', user1_id)
    RETURNING user_id INTO user2_id;
    
    INSERT INTO user_roles (user_id, role_id)
    VALUES (user2_id, (SELECT role_id FROM roles WHERE name = 'EMPLOYEE'));
    
    -- Pokusaj napraviti kruznu referencu (user1.manager = user2)
    UPDATE users SET manager_id = user2_id WHERE user_id = user1_id;
    
    -- Ako dodemo ovdje, trigger nije radio (cleanup i fail)
    UPDATE audit_log SET changed_by = NULL WHERE changed_by IN (user1_id, user2_id);
    DELETE FROM audit_log WHERE entity_name = 'users' AND entity_id IN (user1_id, user2_id);
    DELETE FROM audit_log WHERE entity_name = 'user_roles' AND (new_value->>'user_id')::INTEGER IN (user1_id, user2_id);
    DELETE FROM user_roles WHERE user_id IN (user1_id, user2_id);
    DELETE FROM users WHERE user_id IN (user1_id, user2_id);
    
    INSERT INTO test_results (test_category, test_name, test_status, test_message)
    VALUES ('TRIGGERS', 'validate_manager_hierarchy circular', 'FAIL', 
            'Circular reference dopusten');
    RAISE NOTICE ' FAIL: Manager hierarchy trigger ne sprjecava circular reference';
EXCEPTION
    WHEN OTHERS THEN
        -- Ocekivana greska
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'validate_manager_hierarchy circular', 'PASS', 
                'Circular reference odbijen');
        RAISE NOTICE ' PASS: Manager hierarchy trigger sprjecava circular reference';
        
        -- Cleanup (audit_log prvo)
        UPDATE audit_log SET changed_by = NULL WHERE changed_by IN (user1_id, user2_id);
        DELETE FROM audit_log WHERE entity_name = 'users' AND entity_id IN (user1_id, user2_id);
        DELETE FROM audit_log WHERE entity_name = 'user_roles' AND (new_value->>'user_id')::INTEGER IN (user1_id, user2_id);
        DELETE FROM user_roles WHERE user_id IN (user1_id, user2_id);
        DELETE FROM users WHERE user_id IN (user1_id, user2_id);
END $$;

\echo '--- Test 6.9: Trigger audit_user_roles_changes - INSERT'
DO $$
DECLARE
    test_user_id INTEGER;
    audit_count INTEGER;
BEGIN
    -- Kreiraj korisnika
    INSERT INTO users (username, email, password_hash, first_name, last_name)
    VALUES ('role_audit_test', 'role_audit@test.com', 'hash', 'Role', 'Audit')
    RETURNING user_id INTO test_user_id;
    
    -- Dodijeli ulogu (ovo ce triggerirati audit)
    INSERT INTO user_roles (user_id, role_id, assigned_by)
    VALUES (test_user_id, (SELECT role_id FROM roles WHERE name = 'EMPLOYEE'), 1);
    
    -- Provjeri audit log
    SELECT COUNT(*) INTO audit_count
    FROM audit_log
    WHERE entity_name = 'user_roles' 
    AND action = 'INSERT'
    AND new_value->>'user_id' = test_user_id::TEXT;
    
    IF audit_count > 0 THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'audit_user_roles INSERT', 'PASS', 
                'User role assignment audit kreiran');
        RAISE NOTICE ' PASS: Audit trigger za user_roles INSERT radi ispravno';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'audit_user_roles INSERT', 'FAIL', 
                'User role assignment audit nije kreiran');
        RAISE NOTICE ' FAIL: Audit trigger za user_roles INSERT ne radi';
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
        VALUES ('TRIGGERS', 'audit_user_roles INSERT', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: Audit trigger user_roles INSERT - %', SQLERRM;
END $$;

\echo '--- Test 6.10: Trigger audit_user_roles_changes - DELETE'
DO $$
DECLARE
    test_user_id INTEGER;
    test_role_id INTEGER;
    audit_count INTEGER;
BEGIN
    -- Kreiraj korisnika s ulogom
    INSERT INTO users (username, email, password_hash, first_name, last_name)
    VALUES ('role_delete_audit', 'role_del_audit@test.com', 'hash', 'Role', 'Delete')
    RETURNING user_id INTO test_user_id;
    
    SELECT role_id INTO test_role_id FROM roles WHERE name = 'EMPLOYEE';
    
    INSERT INTO user_roles (user_id, role_id, assigned_by)
    VALUES (test_user_id, test_role_id, 1);
    
    -- Ukloni ulogu (ovo ce triggerirati audit)
    DELETE FROM user_roles WHERE user_id = test_user_id AND role_id = test_role_id;
    
    -- Provjeri audit log
    SELECT COUNT(*) INTO audit_count
    FROM audit_log
    WHERE entity_name = 'user_roles' 
    AND action = 'DELETE'
    AND old_value->>'user_id' = test_user_id::TEXT;
    
    IF audit_count > 0 THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'audit_user_roles DELETE', 'PASS', 
                'User role revocation audit kreiran');
        RAISE NOTICE ' PASS: Audit trigger za user_roles DELETE radi ispravno';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'audit_user_roles DELETE', 'FAIL', 
                'User role revocation audit nije kreiran');
        RAISE NOTICE ' FAIL: Audit trigger za user_roles DELETE ne radi';
    END IF;
    
    -- Cleanup (audit_log prvo)
    UPDATE audit_log SET changed_by = NULL WHERE changed_by = test_user_id;
    DELETE FROM audit_log WHERE entity_name = 'users' AND entity_id = test_user_id;
    DELETE FROM audit_log WHERE entity_name = 'user_roles' AND (new_value->>'user_id')::INTEGER = test_user_id;
    DELETE FROM audit_log WHERE entity_name = 'user_roles' AND (old_value->>'user_id')::INTEGER = test_user_id;
    DELETE FROM users WHERE user_id = test_user_id;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TRIGGERS', 'audit_user_roles DELETE', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: Audit trigger user_roles DELETE - %', SQLERRM;
END $$;

\echo ''
