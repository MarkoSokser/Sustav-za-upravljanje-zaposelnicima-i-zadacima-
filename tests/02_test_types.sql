-- ============================================================================
-- TEST 2: Custom Types (ENUM, Domain, Composite)
-- ============================================================================
-- Testira sve custom tipove podataka
-- ============================================================================

SET search_path TO employee_management;

\echo '--- Test 2.1: ENUM tipovi - task_status'
DO $$
BEGIN
    -- Test validnih vrijednosti
    IF 'NEW'::task_status IS NOT NULL AND 
       'IN_PROGRESS'::task_status IS NOT NULL AND
       'COMPLETED'::task_status IS NOT NULL THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'ENUM task_status valid values', 'PASS', 
                'Sve vrijednosti task_status su validne');
        RAISE NOTICE 'PASS: ENUM task_status radi ispravno';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'ENUM task_status valid values', 'FAIL', 'Problem s validnim vrijednostima');
        RAISE NOTICE 'FAIL: ENUM task_status ne radi ispravno';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'ENUM task_status valid values', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: ENUM task_status - %', SQLERRM;
END $$;

\echo '--- Test 2.2: ENUM tipovi - task_priority'
DO $$
BEGIN
    IF 'LOW'::task_priority IS NOT NULL AND 
       'HIGH'::task_priority IS NOT NULL AND
       'URGENT'::task_priority IS NOT NULL THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'ENUM task_priority valid values', 'PASS', 
                'Sve vrijednosti task_priority su validne');
        RAISE NOTICE 'PASS: ENUM task_priority radi ispravno';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'ENUM task_priority valid values', 'FAIL', 'Problem s validnim vrijednostima');
        RAISE NOTICE 'FAIL: ENUM task_priority ne radi ispravno';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'ENUM task_priority valid values', 'FAIL', SQLERRM);
        RAISE NOTICE 'FAIL: ENUM task_priority - %', SQLERRM;
END $$;

\echo '--- Test 2.3: ENUM tipovi - audit_action'
DO $$
BEGIN
    IF 'INSERT'::audit_action IS NOT NULL AND 
       'UPDATE'::audit_action IS NOT NULL AND
       'DELETE'::audit_action IS NOT NULL THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'ENUM audit_action valid values', 'PASS', 
                'Sve vrijednosti audit_action su validne');
        RAISE NOTICE 'PASS: ENUM audit_action radi ispravno';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'ENUM audit_action valid values', 'FAIL', 'Problem s validnim vrijednostima');
        RAISE NOTICE 'FAIL: ENUM audit_action ne radi ispravno';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'ENUM audit_action valid values', 'FAIL', SQLERRM);
        RAISE NOTICE 'FAIL: ENUM audit_action - %', SQLERRM;
END $$;

\echo '--- Test 2.4: ENUM - Negativni test (nevaljana vrijednost)'
DO $$
DECLARE
    test_value task_status;
BEGIN
    test_value := 'INVALID_STATUS'::task_status;
    -- Ako dođemo ovdje, test je FAILED
    INSERT INTO test_results (test_category, test_name, test_status, test_message)
    VALUES ('TYPES', 'ENUM invalid value rejection', 'FAIL', 
            'ENUM prihvaca nevalidne vrijednosti');
    RAISE NOTICE 'FAIL: ENUM prihvaca nevalidne vrijednosti';
EXCEPTION
    WHEN invalid_text_representation THEN
        -- Ovo je očekivano ponašanje
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'ENUM invalid value rejection', 'PASS', 
                'ENUM odbija nevalidne vrijednosti');
        RAISE NOTICE ' PASS: ENUM ispravno odbija nevalidne vrijednosti';
END $$;

\echo '--- Test 2.5: Domena email_address - validna email adresa'
DO $$
DECLARE
    test_email email_address;
BEGIN
    test_email := 'test@example.com';
    INSERT INTO test_results (test_category, test_name, test_status, test_message)
    VALUES ('TYPES', 'Domain email_address valid', 'PASS', 
            'Validan email prihvacen');
    RAISE NOTICE 'PASS: Domena email_address prihvaca validne emailove';
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'Domain email_address valid', 'FAIL', SQLERRM);
        RAISE NOTICE 'FAIL: Domena email_address - %', SQLERRM;
END $$;

\echo '--- Test 2.6: Domena email_address - nevaljana email adresa'
DO $$
DECLARE
    test_email email_address;
BEGIN
    test_email := 'invalid-email';
    -- Ako dođemo ovdje, test je FAILED
    INSERT INTO test_results (test_category, test_name, test_status, test_message)
    VALUES ('TYPES', 'Domain email_address invalid rejection', 'FAIL', 
            'Domena prihvaca nevalidne emailove');
    RAISE NOTICE ' FAIL: Domena prihvaca nevalidne emailove';
EXCEPTION
    WHEN check_violation THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'Domain email_address invalid rejection', 'PASS', 
                'Domena odbija nevalidne emailove');
        RAISE NOTICE 'PASS: Domena email_address ispravno odbija nevalidne emailove';
END $$;

\echo '--- Test 2.7: Domena username_type - validno korisnicko ime'
DO $$
DECLARE
    test_username username_type;
BEGIN
    test_username := 'valid_user123';
    INSERT INTO test_results (test_category, test_name, test_status, test_message)
    VALUES ('TYPES', 'Domain username_type valid', 'PASS', 
            'Validno korisnicko ime prihvaceno');
    RAISE NOTICE 'PASS: Domena username_type prihvaca validna imena';
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'Domain username_type valid', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: Domena username_type - %', SQLERRM;
END $$;

\echo '--- Test 2.8: Domena username_type - nevaljano korisnicko ime'
DO $$
DECLARE
    test_username username_type;
BEGIN
    test_username := 'ab'; -- Prekratko (min 3 znaka)
    INSERT INTO test_results (test_category, test_name, test_status, test_message)
    VALUES ('TYPES', 'Domain username_type invalid rejection', 'FAIL', 
            'Domena prihvaca nevalidna korisnicka imena');
    RAISE NOTICE ' FAIL: Domena prihvaca nevalidna korisnicka imena';
EXCEPTION
    WHEN check_violation THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'Domain username_type invalid rejection', 'PASS', 
                'Domena odbija nevalidna korisnicka imena');
        RAISE NOTICE ' PASS: Domena username_type ispravno odbija nevalidna imena';
END $$;

\echo '--- Test 2.9: Composite tip timestamp_metadata'
DO $$
DECLARE
    test_metadata timestamp_metadata;
BEGIN
    test_metadata := ROW(CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)::timestamp_metadata;
    IF (test_metadata).created_at IS NOT NULL THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'Composite timestamp_metadata', 'PASS', 
                'Composite tip timestamp_metadata funkcionira');
        RAISE NOTICE 'PASS: Composite tip timestamp_metadata radi ispravno';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'Composite timestamp_metadata', 'FAIL', 
                'Problem s pristupom atributima');
        RAISE NOTICE 'FAIL: Composite tip timestamp_metadata ne radi ispravno';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'Composite timestamp_metadata', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: Composite timestamp_metadata - %', SQLERRM;
END $$;

\echo '--- Test 2.10: Composite tip address_info'
DO $$
DECLARE
    test_address address_info;
BEGIN
    test_address := ROW('Main St', 'Zagreb', '10000', 'Croatia')::address_info;
    IF (test_address).city = 'Zagreb' THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'Composite address_info', 'PASS', 
                'Composite tip address_info funkcionira');
        RAISE NOTICE ' PASS: Composite tip address_info radi ispravno';
    ELSE
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'Composite address_info', 'FAIL', 
                'Problem s pristupom atributima');
        RAISE NOTICE 'FAIL: Composite tip address_info ne radi ispravno';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO test_results (test_category, test_name, test_status, test_message)
        VALUES ('TYPES', 'Composite address_info', 'FAIL', SQLERRM);
        RAISE NOTICE ' FAIL: Composite address_info - %', SQLERRM;
END $$;

\echo ''
