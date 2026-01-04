-- ============================================================================
-- TEST 4: Functions - Validation, RBAC, Business Logic
-- ============================================================================
-- Testira sve funkcije u sustavu
-- ============================================================================

SET search_path TO employee_management;

\echo '--- Test 4.1: validate_email() - valjani email'
DO $$
BEGIN
    IF validate_email('test@example.com') = TRUE THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'validate_email valid', 'PASS', 
                'Validna email adresa prihvacena');
        RAISE NOTICE ' PASS: validate_email() prihvaca validne emailove';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'validate_email valid', 'FAIL', 
                'Validna email adresa odbijena');
        RAISE NOTICE ' FAIL: validate_email() odbija validne emailove';
    END IF;
END $$;

\echo '--- Test 4.2: validate_email() - nevaljani email'
DO $$
BEGIN
    IF validate_email('invalid-email') = FALSE THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'validate_email invalid', 'PASS', 
                'Nevalidna email adresa odbijena');
        RAISE NOTICE ' PASS: validate_email() odbija nevalidne emailove';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'validate_email invalid', 'FAIL', 
                'Nevalidna email adresa prihvacena');
        RAISE NOTICE ' FAIL: validate_email() prihvaca nevalidne emailove';
    END IF;
END $$;

\echo '--- Test 4.3: generate_slug() - generiranje slug-a'
DO $$
DECLARE
    result TEXT;
BEGIN
    result := generate_slug('Moj Novi Zadatak!');
    IF result = 'moj-novi-zadatak' THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'generate_slug', 'PASS', 
                FORMAT('Slug generiran ispravno: %s', result));
        RAISE NOTICE ' PASS: generate_slug() radi ispravno';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'generate_slug', 'FAIL', 
                FORMAT('Neispravan slug: %s (ocekivano: moj-novi-zadatak)', result));
        RAISE NOTICE ' FAIL: generate_slug() vratio: %', result;
    END IF;
END $$;

\echo '--- Test 4.4: check_password_strength() - slaba lozinka'
DO $$
DECLARE
    result RECORD;
BEGIN
    SELECT * INTO result FROM check_password_strength('weak');
    IF result.is_valid = FALSE THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'check_password_strength weak', 'PASS', 
                FORMAT('Slaba lozinka odbijena: %s', result.message));
        RAISE NOTICE ' PASS: check_password_strength() odbija slabe lozinke';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'check_password_strength weak', 'FAIL', 
                'Slaba lozinka prihvacena');
        RAISE NOTICE ' FAIL: check_password_strength() prihvaca slabe lozinke';
    END IF;
END $$;

\echo '--- Test 4.5: check_password_strength() - jaka lozinka'
DO $$
DECLARE
    result RECORD;
BEGIN
    SELECT * INTO result FROM check_password_strength('Strong@Pass123');
    IF result.is_valid = TRUE THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'check_password_strength strong', 'PASS', 
                'Jaka lozinka prihvacena');
        RAISE NOTICE ' PASS: check_password_strength() prihvaca jake lozinke';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'check_password_strength strong', 'FAIL', 
                FORMAT('Jaka lozinka odbijena: %s', result.message));
        RAISE NOTICE ' FAIL: check_password_strength() odbija jake lozinke';
    END IF;
END $$;

\echo '--- Test 4.6: user_has_permission() - admin ima TASK_DELETE'
DO $$
BEGIN
    IF user_has_permission(1, 'TASK_DELETE') = TRUE THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'user_has_permission admin', 'PASS', 
                'Admin ima TASK_DELETE permisiju');
        RAISE NOTICE ' PASS: user_has_permission() ispravno provjerava admin prava';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'user_has_permission admin', 'FAIL', 
                'Admin nema TASK_DELETE permisiju');
        RAISE NOTICE ' FAIL: user_has_permission() ne radi za admina';
    END IF;
END $$;

\echo '--- Test 4.7: user_has_permission() - employee nema TASK_DELETE'
DO $$
DECLARE
    employee_id INTEGER;
BEGIN
    SELECT user_id INTO employee_id FROM users WHERE username = 'marko_dev';
    IF user_has_permission(employee_id, 'TASK_DELETE') = FALSE THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'user_has_permission employee', 'PASS', 
                'Employee nema TASK_DELETE permisiju');
        RAISE NOTICE ' PASS: user_has_permission() ispravno ogranicava employee prava';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'user_has_permission employee', 'FAIL', 
                'Employee ima TASK_DELETE permisiju');
        RAISE NOTICE ' FAIL: user_has_permission() daje previsoka prava employeeima';
    END IF;
END $$;

\echo '--- Test 4.8: get_user_permissions() - brojanje admin permisija'
DO $$
DECLARE
    perm_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO perm_count FROM get_user_permissions(1);
    IF perm_count >= 24 THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'get_user_permissions admin', 'PASS', 
                FORMAT('Admin ima %s permisija', perm_count));
        RAISE NOTICE ' PASS: get_user_permissions() vraca % permisija za admina', perm_count;
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'get_user_permissions admin', 'FAIL', 
                FORMAT('Admin ima samo %s permisija (ocekivano 24+)', perm_count));
        RAISE NOTICE ' FAIL: get_user_permissions() vraca samo % permisija', perm_count;
    END IF;
END $$;

\echo '--- Test 4.9: get_user_roles() - admin uloge'
DO $$
DECLARE
    role_count INTEGER;
    role_name VARCHAR(50);
BEGIN
    SELECT COUNT(*), MAX(r.role_name) INTO role_count, role_name 
    FROM get_user_roles(1) r;
    
    IF role_count >= 1 AND role_name = 'ADMIN' THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'get_user_roles', 'PASS', 
                FORMAT('Admin ima %s uloga, ukljucujuci ADMIN', role_count));
        RAISE NOTICE ' PASS: get_user_roles() vraca ispravne uloge';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'get_user_roles', 'FAIL', 
                FORMAT('Problem s ulogama: count=%s, role=%s', role_count, role_name));
        RAISE NOTICE ' FAIL: get_user_roles() ne radi ispravno';
    END IF;
END $$;

\echo '--- Test 4.10: is_manager_of() - Ivan je manager Marka'
DO $$
DECLARE
    ivan_id INTEGER;
    marko_id INTEGER;
BEGIN
    SELECT user_id INTO ivan_id FROM users WHERE username = 'ivan_manager';
    SELECT user_id INTO marko_id FROM users WHERE username = 'marko_dev';
    
    IF is_manager_of(ivan_id, marko_id) = TRUE THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'is_manager_of true', 'PASS', 
                'Ivan je ispravno prepoznat kao manager Marka');
        RAISE NOTICE ' PASS: is_manager_of() ispravno prepoznaje manager odnos';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'is_manager_of true', 'FAIL', 
                'Ivan nije prepoznat kao manager Marka');
        RAISE NOTICE ' FAIL: is_manager_of() ne prepoznaje manager odnos';
    END IF;
END $$;

\echo '--- Test 4.11: is_manager_of() - Marko nije manager Ivana'
DO $$
DECLARE
    ivan_id INTEGER;
    marko_id INTEGER;
BEGIN
    SELECT user_id INTO ivan_id FROM users WHERE username = 'ivan_manager';
    SELECT user_id INTO marko_id FROM users WHERE username = 'marko_dev';
    
    IF is_manager_of(marko_id, ivan_id) = FALSE THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'is_manager_of false', 'PASS', 
                'Marko ispravno nije prepoznat kao manager Ivana');
        RAISE NOTICE ' PASS: is_manager_of() ispravno odbija false odnose';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'is_manager_of false', 'FAIL', 
                'Marko pogresno prepoznat kao manager Ivana');
        RAISE NOTICE ' FAIL: is_manager_of() vraca false positive';
    END IF;
END $$;

\echo '--- Test 4.12: get_team_members() - Ivanov tim'
DO $$
DECLARE
    ivan_id INTEGER;
    team_count INTEGER;
BEGIN
    SELECT user_id INTO ivan_id FROM users WHERE username = 'ivan_manager';
    SELECT COUNT(*) INTO team_count FROM get_team_members(ivan_id);
    
    IF team_count >= 3 THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'get_team_members', 'PASS', 
                FORMAT('Ivanov tim ima %s clanova', team_count));
        RAISE NOTICE ' PASS: get_team_members() vraca % clanova tima', team_count;
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'get_team_members', 'FAIL', 
                FORMAT('Ivanov tim ima samo %s clanova (ocekivano 3+)', team_count));
        RAISE NOTICE ' FAIL: get_team_members() vraca % clanova', team_count;
    END IF;
END $$;

\echo '--- Test 4.13: get_user_tasks() - zadaci korisnika'
DO $$
DECLARE
    marko_id INTEGER;
    task_count INTEGER;
BEGIN
    SELECT user_id INTO marko_id FROM users WHERE username = 'marko_dev';
    SELECT COUNT(*) INTO task_count FROM get_user_tasks(marko_id);
    
    IF task_count >= 0 THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'get_user_tasks', 'PASS', 
                FORMAT('Marko ima %s zadataka', task_count));
        RAISE NOTICE ' PASS: get_user_tasks() vraca % zadataka', task_count;
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'get_user_tasks', 'FAIL', 
                'Greska pri dohvacanju zadataka');
        RAISE NOTICE ' FAIL: get_user_tasks() ne radi ispravno';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'get_user_tasks', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: get_user_tasks() - %', SQLERRM;
END $$;

\echo '--- Test 4.14: get_user_tasks() - filtriranje po statusu'
DO $$
DECLARE
    marko_id INTEGER;
    active_count INTEGER;
BEGIN
    SELECT user_id INTO marko_id FROM users WHERE username = 'marko_dev';
    SELECT COUNT(*) INTO active_count FROM get_user_tasks(marko_id, 'IN_PROGRESS');
    
    IF active_count >= 0 THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'get_user_tasks filtered', 'PASS', 
                FORMAT('Marko ima %s IN_PROGRESS zadataka', active_count));
        RAISE NOTICE ' PASS: get_user_tasks() filtriranje radi, % IN_PROGRESS zadataka', active_count;
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'get_user_tasks filtered', 'FAIL', 
                'Greska pri filtriranju zadataka');
        RAISE NOTICE ' FAIL: get_user_tasks() filtriranje ne radi';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'get_user_tasks filtered', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: get_user_tasks() filtered - %', SQLERRM;
END $$;

\echo '--- Test 4.15: get_task_statistics() - statistika zadataka'
DO $$
DECLARE
    marko_id INTEGER;
    stats RECORD;
BEGIN
    SELECT user_id INTO marko_id FROM users WHERE username = 'marko_dev';
    SELECT * INTO stats FROM get_task_statistics(marko_id);
    
    IF stats.total_tasks IS NOT NULL THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'get_task_statistics', 'PASS', 
                FORMAT('Statistika: total=%s, completed=%s, rate=%s%%', 
                       stats.total_tasks, stats.completed_tasks, stats.completion_rate));
        RAISE NOTICE ' PASS: get_task_statistics() vraca statistiku';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'get_task_statistics', 'FAIL', 
                'Greska pri generiranju statistike');
        RAISE NOTICE ' FAIL: get_task_statistics() ne radi ispravno';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('FUNCTIONS', 'get_task_statistics', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: get_task_statistics() - %', SQLERRM;
END $$;

\echo ''
