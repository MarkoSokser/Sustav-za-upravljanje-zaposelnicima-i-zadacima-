
-- MASTER TEST SCRIPT - Interni sustav za upravljanje zaposlenicima i zadacima
-- Testovi izradeni i generirani pomocu AI alata radi lakse validacije koda i baze podataka
-- Autor: AI Assistant

\echo '========================================================================='
\echo '  MASTER TEST SUITE - Employee Management System'
\echo '========================================================================='
\echo ''

-- Postavljanje parametara
\set VERBOSITY verbose
\timing on
SET client_min_messages TO NOTICE;

-- Kreiranje privremene tablice za rezultate testova
DROP TABLE IF EXISTS test_results;
CREATE TEMP TABLE test_results (
    test_id SERIAL PRIMARY KEY,
    test_category VARCHAR(50),
    test_name VARCHAR(200),
    test_status VARCHAR(20), -- PASS, FAIL, SKIP
    test_message TEXT,
    execution_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

\echo ''
\echo '========================================================================='
\echo '  1. OSNOVNI TESTOVI - Database Setup'
\echo '========================================================================='
\i tests/01_test_basic_setup.sql

\echo ''
\echo '========================================================================='
\echo '  2. TESTOVI TIPOVA - ENUM, Domain, Composite'
\echo '========================================================================='
\i tests/02_test_types.sql

\echo ''
\echo '========================================================================='
\echo '  3. TESTOVI TABLICA - Structure, Constraints, Relationships'
\echo '========================================================================='
\i tests/03_test_tables.sql

\echo ''
\echo '========================================================================='
\echo '  4. TESTOVI FUNKCIJA - Validation, RBAC, Business Logic'
\echo '========================================================================='
\i tests/04_test_functions.sql

\echo ''
\echo '========================================================================='
\echo '  5. TESTOVI PROCEDURA - CRUD Operations'
\echo '========================================================================='
\i tests/05_test_procedures.sql

\echo ''
\echo '========================================================================='
\echo '  6. TESTOVI TRIGGERA - Audit, Validation, Auto-Update'
\echo '========================================================================='
\i tests/06_test_triggers.sql

\echo ''
\echo '========================================================================='
\echo '  7. TESTOVI VIEW-OVA I INDEKSA - Performance & Data Integrity'
\echo '========================================================================='
\i tests/07_test_views_indexes.sql

\echo ''
\echo '========================================================================='
\echo '  TEST SUMMARY - Ukupni rezultati testiranja'
\echo '========================================================================='
\echo ''


SELECT 
    test_category,
    COUNT(*) AS total_tests,
    SUM(CASE WHEN test_status = 'PASS' THEN 1 ELSE 0 END) AS passed,
    SUM(CASE WHEN test_status = 'FAIL' THEN 1 ELSE 0 END) AS failed,
    SUM(CASE WHEN test_status = 'SKIP' THEN 1 ELSE 0 END) AS skipped,
    ROUND(100.0 * SUM(CASE WHEN test_status = 'PASS' THEN 1 ELSE 0 END) / COUNT(*), 2) AS success_rate
FROM test_results
GROUP BY test_category
ORDER BY test_category;

\echo ''
\echo 'Overall Summary:'
SELECT 
    COUNT(*) AS total_tests,
    SUM(CASE WHEN test_status = 'PASS' THEN 1 ELSE 0 END) AS passed,
    SUM(CASE WHEN test_status = 'FAIL' THEN 1 ELSE 0 END) AS failed,
    SUM(CASE WHEN test_status = 'SKIP' THEN 1 ELSE 0 END) AS skipped,
    ROUND(100.0 * SUM(CASE WHEN test_status = 'PASS' THEN 1 ELSE 0 END) / COUNT(*), 2) AS success_rate
FROM test_results;

\echo ''
\echo 'Failed Tests Details:'
SELECT 
    test_category,
    test_name,
    test_message,
    execution_time
FROM test_results
WHERE test_status = 'FAIL'
ORDER BY execution_time;

\echo ''
\echo '========================================================================='
\echo '  TEST EXECUTION COMPLETED'
\echo '========================================================================='
