-- ============================================================================
-- TEST 1: Basic Database Setup
-- ============================================================================
-- Testira postojanje baze podataka, sheme i osnovnih komponenti
-- ============================================================================

SET search_path TO employee_management;

\echo '--- Test 1.1: Provjera postojanja sheme'
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'employee_management') THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('SETUP', 'Schema exists', 'PASS', 'Schema employee_management postoji');
        RAISE NOTICE 'PASS: Schema employee_management postoji';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('SETUP', 'Schema exists', 'FAIL', 'Schema employee_management ne postoji');
        RAISE NOTICE ' FAIL: Schema employee_management ne postoji';
    END IF;
END $$;

\echo '--- Test 1.2: Provjera postojanja svih tablica'
DO $$
DECLARE
    expected_tables TEXT[] := ARRAY['users', 'roles', 'permissions', 'tasks', 
                                     'user_roles', 'role_permissions', 
                                     'login_events', 'audit_log'];
    table_name TEXT;
    missing_tables TEXT := '';
    all_exist BOOLEAN := TRUE;
BEGIN
    FOREACH table_name IN ARRAY expected_tables
    LOOP
        IF NOT EXISTS (SELECT 1 FROM pg_tables 
                      WHERE schemaname = 'employee_management' 
                      AND tablename = table_name) THEN
            all_exist := FALSE;
            missing_tables := missing_tables || table_name || ', ';
        END IF;
    END LOOP;
    
    IF all_exist THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('SETUP', 'All tables exist', 'PASS', 'Svih 8 tablica postoji');
        RAISE NOTICE 'PASS: Svih 8 tablica postoji';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('SETUP', 'All tables exist', 'FAIL', 
                'Nedostaju tablice: ' || TRIM(TRAILING ', ' FROM missing_tables));
        RAISE NOTICE ' FAIL: Nedostaju tablice: %', TRIM(TRAILING ', ' FROM missing_tables);
    END IF;
END $$;

\echo '--- Test 1.3: Provjera postojanja pocetnih podataka'
DO $$
DECLARE
    user_count INTEGER;
    role_count INTEGER;
    permission_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO role_count FROM roles;
    SELECT COUNT(*) INTO permission_count FROM permissions;
    
    IF user_count >= 9 AND role_count >= 3 AND permission_count >= 24 THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('SETUP', 'Seed data loaded', 'PASS', 
                FORMAT('Users: %s, Roles: %s, Permissions: %s', user_count, role_count, permission_count));
        RAISE NOTICE ' PASS: Pocetni podaci ucitani (Users: %, Roles: %, Permissions: %)', 
                     user_count, role_count, permission_count;
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('SETUP', 'Seed data loaded', 'FAIL', 
                FORMAT('Nedostaju podaci - Users: %s, Roles: %s, Permissions: %s', 
                       user_count, role_count, permission_count));
        RAISE NOTICE 'FAIL: Nedostaju pocetni podaci';
    END IF;
END $$;

\echo '--- Test 1.4: Provjera primarnih kljuceva'
DO $$
DECLARE
    missing_pk TEXT := '';
    all_have_pk BOOLEAN := TRUE;
    table_rec RECORD;
BEGIN
    FOR table_rec IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'employee_management'
    LOOP
        IF NOT EXISTS (
            SELECT 1 
            FROM pg_constraint 
            WHERE conrelid = ('employee_management.' || table_rec.tablename)::regclass 
            AND contype = 'p'
        ) THEN
            all_have_pk := FALSE;
            missing_pk := missing_pk || table_rec.tablename || ', ';
        END IF;
    END LOOP;
    
    IF all_have_pk THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('SETUP', 'Primary keys exist', 'PASS', 'Sve tablice imaju primarni ključ');
        RAISE NOTICE ' PASS: Sve tablice imaju primarni kljuc';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('SETUP', 'Primary keys exist', 'FAIL', 
                'Nedostaju PK na tablicama: ' || TRIM(TRAILING ', ' FROM missing_pk));
        RAISE NOTICE 'FAIL: Nedostaju primarni kljucevi';
    END IF;
END $$;

\echo '--- Test 1.5: Provjera stranih kljuceva'
DO $$
DECLARE
    fk_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO fk_count
    FROM pg_constraint
    WHERE contype = 'f'
    AND connamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'employee_management');
    
    IF fk_count >= 10 THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('SETUP', 'Foreign keys exist', 'PASS', 
                FORMAT('%s stranih kljuceva definirano', fk_count));
        RAISE NOTICE ' PASS: % stranih kljuceva definirano', fk_count;
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('SETUP', 'Foreign keys exist', 'FAIL', 
                FORMAT('Samo %s stranih kljuceva pronadeno', fk_count));
        RAISE NOTICE 'FAIL: Samo % stranih kljuceva pronadeno', fk_count;
    END IF;
END $$;

\echo ''
