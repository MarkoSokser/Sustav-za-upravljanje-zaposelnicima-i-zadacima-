-- ============================================================================
-- TEST 7: Views and Indexes
-- ============================================================================
-- Testira view-ove i provjera postojanja indeksa
-- ============================================================================

SET search_path TO employee_management;

\echo '--- Test 7.1: View v_users_with_roles - structure'
DO $$
DECLARE
    view_exists BOOLEAN;
    column_count INTEGER;
BEGIN
    -- Provjeri postoji li view
    SELECT EXISTS (
        SELECT 1 FROM pg_views 
        WHERE schemaname = 'employee_management' 
        AND viewname = 'v_users_with_roles'
    ) INTO view_exists;
    
    IF view_exists THEN
        -- Provjeri broj stupaca
        SELECT COUNT(*) INTO column_count
        FROM information_schema.columns
        WHERE table_schema = 'employee_management'
        AND table_name = 'v_users_with_roles';
        
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('VIEWS', 'v_users_with_roles structure', 'PASS', 
                FORMAT('View postoji s %s stupaca', column_count));
        RAISE NOTICE ' PASS: View v_users_with_roles postoji s % stupaca', column_count;
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('VIEWS', 'v_users_with_roles structure', 'FAIL', 
                'View ne postoji');
        RAISE NOTICE ' FAIL: View v_users_with_roles ne postoji';
    END IF;
END $$;

\echo '--- Test 7.2: View v_users_with_roles - data'
DO $$
DECLARE
    row_count INTEGER;
    admin_roles TEXT[];
BEGIN
    -- Provjeri broj redaka
    SELECT COUNT(*) INTO row_count FROM v_users_with_roles;
    
    -- Provjeri admin uloge
    SELECT roles INTO admin_roles FROM v_users_with_roles WHERE username = 'admin';
    
    IF row_count > 0 AND 'ADMIN' = ANY(admin_roles) THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('VIEWS', 'v_users_with_roles data', 'PASS', 
                FORMAT('%s redaka, admin ima ADMIN ulogu', row_count));
        RAISE NOTICE ' PASS: View v_users_with_roles vraca % redaka', row_count;
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('VIEWS', 'v_users_with_roles data', 'FAIL', 
                'Problem s podacima u view-u');
        RAISE NOTICE ' FAIL: View v_users_with_roles ne vraca ispravne podatke';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('VIEWS', 'v_users_with_roles data', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: View v_users_with_roles data - %', SQLERRM;
END $$;

\echo '--- Test 7.3: View v_roles_with_permissions - structure'
DO $$
DECLARE
    view_exists BOOLEAN;
    admin_permissions TEXT[];
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM pg_views 
        WHERE schemaname = 'employee_management' 
        AND viewname = 'v_roles_with_permissions'
    ) INTO view_exists;
    
    IF view_exists THEN
        -- Provjeri admin permisije
        SELECT permissions INTO admin_permissions 
        FROM v_roles_with_permissions 
        WHERE role_name = 'ADMIN';
        
        IF array_length(admin_permissions, 1) >= 24 THEN
            INSERT INTO test_results (test_category, test_name, test_status, test_message)
            VALUES ('VIEWS', 'v_roles_with_permissions', 'PASS', 
                    FORMAT('View radi, ADMIN ima %s permisija', array_length(admin_permissions, 1)));
            RAISE NOTICE ' PASS: View v_roles_with_permissions radi ispravno';
        ELSE
            INSERT INTO test_results (test_category, test_name, test_status, test_message)
            VALUES ('VIEWS', 'v_roles_with_permissions', 'FAIL', 
                    'ADMIN nema sve permisije');
            RAISE NOTICE ' FAIL: View v_roles_with_permissions ne pokazuje sve permisije';
        END IF;
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('VIEWS', 'v_roles_with_permissions', 'FAIL', 
                'View ne postoji');
        RAISE NOTICE ' FAIL: View v_roles_with_permissions ne postoji';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('VIEWS', 'v_roles_with_permissions', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: View v_roles_with_permissions - %', SQLERRM;
END $$;

\echo '--- Test 7.4: View v_tasks_details - structure and data'
DO $$
DECLARE
    view_exists BOOLEAN;
    task_count INTEGER;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM pg_views 
        WHERE schemaname = 'employee_management' 
        AND viewname = 'v_tasks_details'
    ) INTO view_exists;
    
    IF view_exists THEN
        SELECT COUNT(*) INTO task_count FROM v_tasks_details;
        
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('VIEWS', 'v_tasks_details', 'PASS', 
                FORMAT('View postoji s %s zadataka', task_count));
        RAISE NOTICE ' PASS: View v_tasks_details radi s % zadataka', task_count;
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('VIEWS', 'v_tasks_details', 'FAIL', 
                'View ne postoji');
        RAISE NOTICE ' FAIL: View v_tasks_details ne postoji';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('VIEWS', 'v_tasks_details', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: View v_tasks_details - %', SQLERRM;
END $$;

\echo '--- Test 7.5: View v_user_statistics'
DO $$
DECLARE
    view_exists BOOLEAN;
    admin_stats RECORD;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM pg_views 
        WHERE schemaname = 'employee_management' 
        AND viewname = 'v_user_statistics'
    ) INTO view_exists;
    
    IF view_exists THEN
        SELECT * INTO admin_stats FROM v_user_statistics WHERE username = 'admin';
        
        IF admin_stats.username IS NOT NULL THEN
            INSERT INTO test_results (test_category, test_name, test_status, test_message)
            VALUES ('VIEWS', 'v_user_statistics', 'PASS', 
                    'View radi i vraca statistiku');
            RAISE NOTICE ' PASS: View v_user_statistics radi ispravno';
        ELSE
            INSERT INTO test_results (test_category, test_name, test_status, test_message)
            VALUES ('VIEWS', 'v_user_statistics', 'FAIL', 
                    'View ne vraca podatke');
            RAISE NOTICE ' FAIL: View v_user_statistics ne vraca podatke';
        END IF;
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('VIEWS', 'v_user_statistics', 'FAIL', 
                'View ne postoji');
        RAISE NOTICE ' FAIL: View v_user_statistics ne postoji';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('VIEWS', 'v_user_statistics', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: View v_user_statistics - %', SQLERRM;
END $$;

\echo '--- Test 7.6: View v_manager_team'
DO $$
DECLARE
    view_exists BOOLEAN;
    ivan_team_count INTEGER;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM pg_views 
        WHERE schemaname = 'employee_management' 
        AND viewname = 'v_manager_team'
    ) INTO view_exists;
    
    IF view_exists THEN
        SELECT COUNT(*) INTO ivan_team_count 
        FROM v_manager_team 
        WHERE manager_username = 'ivan_manager';
        
        IF ivan_team_count >= 3 THEN
            INSERT INTO test_results (test_category, test_name, test_status, test_message)
            VALUES ('VIEWS', 'v_manager_team', 'PASS', 
                    FORMAT('View radi, Ivan ima %s clanova tima', ivan_team_count));
            RAISE NOTICE ' PASS: View v_manager_team radi, Ivan ima % clanova', ivan_team_count;
        ELSE
            INSERT INTO test_results (test_category, test_name, test_status, test_message)
            VALUES ('VIEWS', 'v_manager_team', 'FAIL', 
                    FORMAT('Ivan ima samo %s clanova tima (ocekivano 3+)', ivan_team_count));
            RAISE NOTICE ' FAIL: View v_manager_team ne vraca sve clanove tima';
        END IF;
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('VIEWS', 'v_manager_team', 'FAIL', 
                'View ne postoji');
        RAISE NOTICE ' FAIL: View v_manager_team ne postoji';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('VIEWS', 'v_manager_team', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: View v_manager_team - %', SQLERRM;
END $$;

\echo '--- Test 7.7: Index postojanje - users tablice'
DO $$
DECLARE
    index_count INTEGER;
    expected_indexes TEXT[] := ARRAY[
        'idx_users_username',
        'idx_users_email',
        'idx_users_manager',
        'idx_users_active',
        'idx_users_full_name'
    ];
    idx_name TEXT;
    missing_indexes TEXT := '';
BEGIN
    FOREACH idx_name IN ARRAY expected_indexes
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'employee_management' 
            AND indexname = idx_name
        ) THEN
            missing_indexes := missing_indexes || idx_name || ', ';
        END IF;
    END LOOP;
    
    IF missing_indexes = '' THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('INDEXES', 'users table indexes', 'PASS', 
                'Svi ocekivani indeksi postoje');
        RAISE NOTICE ' PASS: Svi indeksi za users tablicu postoje';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('INDEXES', 'users table indexes', 'FAIL', 
                'Nedostaju indeksi: ' || TRIM(TRAILING ', ' FROM missing_indexes));
        RAISE NOTICE ' FAIL: Nedostaju indeksi: %', TRIM(TRAILING ', ' FROM missing_indexes);
    END IF;
END $$;

\echo '--- Test 7.8: Index postojanje - tasks tablice'
DO $$
DECLARE
    expected_indexes TEXT[] := ARRAY[
        'idx_tasks_status',
        'idx_tasks_priority',
        'idx_tasks_assigned_to',
        'idx_tasks_created_by',
        'idx_tasks_due_date',
        'idx_tasks_active'
    ];
    idx_name TEXT;
    missing_indexes TEXT := '';
BEGIN
    FOREACH idx_name IN ARRAY expected_indexes
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'employee_management' 
            AND indexname = idx_name
        ) THEN
            missing_indexes := missing_indexes || idx_name || ', ';
        END IF;
    END LOOP;
    
    IF missing_indexes = '' THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('INDEXES', 'tasks table indexes', 'PASS', 
                'Svi ocekivani indeksi postoje');
        RAISE NOTICE ' PASS: Svi indeksi za tasks tablicu postoje';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('INDEXES', 'tasks table indexes', 'FAIL', 
                'Nedostaju indeksi: ' || TRIM(TRAILING ', ' FROM missing_indexes));
        RAISE NOTICE ' FAIL: Nedostaju indeksi: %', TRIM(TRAILING ', ' FROM missing_indexes);
    END IF;
END $$;

\echo '--- Test 7.9: Index postojanje - audit tablice'
DO $$
DECLARE
    expected_indexes TEXT[] := ARRAY[
        'idx_audit_log_entity',
        'idx_audit_log_changed_by',
        'idx_audit_log_time',
        'idx_audit_log_action'
    ];
    idx_name TEXT;
    missing_indexes TEXT := '';
BEGIN
    FOREACH idx_name IN ARRAY expected_indexes
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'employee_management' 
            AND indexname = idx_name
        ) THEN
            missing_indexes := missing_indexes || idx_name || ', ';
        END IF;
    END LOOP;
    
    IF missing_indexes = '' THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('INDEXES', 'audit_log table indexes', 'PASS', 
                'Svi ocekivani indeksi postoje');
        RAISE NOTICE ' PASS: Svi indeksi za audit_log tablicu postoje';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('INDEXES', 'audit_log table indexes', 'FAIL', 
                'Nedostaju indeksi: ' || TRIM(TRAILING ', ' FROM missing_indexes));
        RAISE NOTICE ' FAIL: Nedostaju indeksi: %', TRIM(TRAILING ', ' FROM missing_indexes);
    END IF;
END $$;

\echo '--- Test 7.10: Index performance - verify index exists'
DO $$
DECLARE
    idx_count INTEGER;
BEGIN
    -- Jednostavna provjera da postoje kljucni indeksi za performance
    SELECT COUNT(*) INTO idx_count
    FROM pg_indexes
    WHERE schemaname = 'employee_management'
    AND indexname IN ('idx_users_username', 'idx_users_email', 'idx_tasks_status');
    
    IF idx_count = 3 THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('INDEXES', 'index usage in queries', 'PASS', 
                'Svi performance indeksi postoje');
        RAISE NOTICE ' PASS: Performance indeksi verificirani';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('INDEXES', 'index usage in queries', 'FAIL', 
                'Nedostaju performance indeksi: ' || idx_count || '/3');
        RAISE NOTICE ' FAIL: Nedostaju performance indeksi';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('INDEXES', 'index usage in queries', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: Index test error - %', SQLERRM;
END $$;

\echo ''
