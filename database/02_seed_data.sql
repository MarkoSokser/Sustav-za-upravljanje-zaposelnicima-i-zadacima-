--  Početni podaci (Seed Data)
-- Interni sustav za upravljanje zaposlenicima i zadacima

SET search_path TO employee_management;


-- POČETNI PODACI - PERMISSIONS (Prava pristupa)
-- Upravljanje korisnicima
INSERT INTO permissions (code, name, description, category) VALUES
('USER_CREATE', 'Kreiranje korisnika', 'Mogućnost kreiranja novih korisničkih računa', 'USER'),
('USER_READ_ALL', 'Pregled svih korisnika', 'Mogućnost pregleda svih korisnika u sustavu', 'USER'),
('USER_READ_TEAM', 'Pregled tima', 'Mogućnost pregleda korisnika u vlastitom timu', 'USER'),
('USER_READ_SELF', 'Pregled vlastitih podataka', 'Mogućnost pregleda vlastitih podataka', 'USER'),
('USER_UPDATE_ALL', 'Uređivanje svih korisnika', 'Mogućnost uređivanja svih korisničkih računa', 'USER'),
('USER_UPDATE_SELF', 'Uređivanje vlastitih podataka', 'Mogućnost uređivanja vlastitih podataka', 'USER'),
('USER_DEACTIVATE', 'Deaktivacija korisnika', 'Mogućnost deaktivacije korisničkih računa', 'USER');

-- Upravljanje ulogama
INSERT INTO permissions (code, name, description, category) VALUES
('ROLE_CREATE', 'Kreiranje uloga', 'Mogućnost kreiranja novih uloga', 'ROLE'),
('ROLE_READ', 'Pregled uloga', 'Mogućnost pregleda uloga u sustavu', 'ROLE'),
('ROLE_UPDATE', 'Uređivanje uloga', 'Mogućnost uređivanja postojećih uloga', 'ROLE'),
('ROLE_DELETE', 'Brisanje uloga', 'Mogućnost brisanja uloga', 'ROLE'),
('ROLE_ASSIGN', 'Dodjela uloga', 'Mogućnost dodjeljivanja uloga korisnicima', 'ROLE'),
('PERMISSION_MANAGE', 'Upravljanje pravima', 'Mogućnost upravljanja pravima pristupa', 'ROLE');

-- Upravljanje zadacima
INSERT INTO permissions (code, name, description, category) VALUES
('TASK_CREATE', 'Kreiranje zadataka', 'Mogućnost kreiranja novih zadataka', 'TASK'),
('TASK_ASSIGN', 'Dodjela zadataka', 'Mogućnost dodjeljivanja zadataka korisnicima', 'TASK'),
('TASK_READ_ALL', 'Pregled svih zadataka', 'Mogućnost pregleda svih zadataka u sustavu', 'TASK'),
('TASK_READ_TEAM', 'Pregled zadataka tima', 'Mogućnost pregleda zadataka u vlastitom timu', 'TASK'),
('TASK_READ_SELF', 'Pregled vlastitih zadataka', 'Mogućnost pregleda vlastitih zadataka', 'TASK'),
('TASK_UPDATE_ANY', 'Uređivanje svih zadataka', 'Mogućnost uređivanja bilo kojeg zadatka', 'TASK'),
('TASK_UPDATE_SELF_STATUS', 'Ažuriranje statusa', 'Mogućnost ažuriranja statusa vlastitih zadataka', 'TASK'),
('TASK_DELETE', 'Brisanje zadataka', 'Mogućnost brisanja zadataka', 'TASK');

-- Audit i meta-podaci
INSERT INTO permissions (code, name, description, category) VALUES
('AUDIT_READ_ALL', 'Pregled audit zapisa', 'Mogućnost pregleda svih audit zapisa', 'AUDIT'),
('LOGIN_EVENTS_READ_ALL', 'Pregled svih prijava', 'Mogućnost pregleda svih prijava u sustav', 'AUDIT'),
('LOGIN_EVENTS_READ_SELF', 'Pregled vlastitih prijava', 'Mogućnost pregleda vlastitih prijava', 'AUDIT');


-- POČETNI PODACI - ROLES (Uloge)
INSERT INTO roles (name, description, is_system) VALUES
('ADMIN', 'Administrator sustava s punim pristupom svim funkcionalnostima', TRUE),
('MANAGER', 'Voditelj tima koji upravlja zaposlenicima i zadacima', TRUE),
('EMPLOYEE', 'Zaposlenik s pristupom vlastitim podacima i zadacima', TRUE);


-- POČETNI PODACI - ROLE_PERMISSIONS (RBAC matrica)
-- ADMIN - sva prava
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r, permissions p
WHERE r.name = 'ADMIN';

-- MANAGER prava
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r, permissions p
WHERE r.name = 'MANAGER' 
AND p.code IN (
    'USER_READ_TEAM',
    'USER_READ_SELF',
    'USER_UPDATE_SELF',
    'ROLE_READ',
    'TASK_CREATE',
    'TASK_ASSIGN',
    'TASK_READ_TEAM',
    'TASK_READ_SELF',
    'TASK_UPDATE_ANY',
    'TASK_UPDATE_SELF_STATUS',
    'TASK_DELETE',
    'LOGIN_EVENTS_READ_SELF'
);

-- EMPLOYEE prava
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM roles r, permissions p
WHERE r.name = 'EMPLOYEE' 
AND p.code IN (
    'USER_READ_SELF',
    'USER_UPDATE_SELF',
    'TASK_READ_SELF',
    'TASK_UPDATE_SELF_STATUS',
    'LOGIN_EVENTS_READ_SELF'
);


-- POČETNI PODACI - USERS (Testni korisnici)

-- Napomena: password_hash je bcrypt hash za lozinku 'Password123!'
-- U produkciji koristiti pravu hash funkciju!

-- Administrator
INSERT INTO users (username, email, password_hash, first_name, last_name, is_active) VALUES
('admin', 'admin@company.hr', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.G5FuIQ.Gu.sKyW', 'System', 'Administrator', TRUE);

-- Manageri
INSERT INTO users (username, email, password_hash, first_name, last_name, is_active) VALUES
('ivan_manager', 'ivan.horvat@company.hr', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.G5FuIQ.Gu.sKyW', 'Ivan', 'Horvat', TRUE),
('ana_manager', 'ana.kovac@company.hr', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.G5FuIQ.Gu.sKyW', 'Ana', 'Kovač', TRUE);

-- Zaposlenici pod Ivan Horvat
INSERT INTO users (username, email, password_hash, first_name, last_name, manager_id, is_active) VALUES
('marko_dev', 'marko.babic@company.hr', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.G5FuIQ.Gu.sKyW', 'Marko', 'Babić', 
    (SELECT user_id FROM users WHERE username = 'ivan_manager'), TRUE),
('petra_dev', 'petra.novak@company.hr', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.G5FuIQ.Gu.sKyW', 'Petra', 'Novak', 
    (SELECT user_id FROM users WHERE username = 'ivan_manager'), TRUE),
('luka_dev', 'luka.maric@company.hr', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.G5FuIQ.Gu.sKyW', 'Luka', 'Marić', 
    (SELECT user_id FROM users WHERE username = 'ivan_manager'), TRUE);

-- Zaposlenici pod Ana Kovač
INSERT INTO users (username, email, password_hash, first_name, last_name, manager_id, is_active) VALUES
('maja_design', 'maja.juric@company.hr', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.G5FuIQ.Gu.sKyW', 'Maja', 'Jurić', 
    (SELECT user_id FROM users WHERE username = 'ana_manager'), TRUE),
('tomislav_design', 'tomislav.peric@company.hr', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.G5FuIQ.Gu.sKyW', 'Tomislav', 'Perić', 
    (SELECT user_id FROM users WHERE username = 'ana_manager'), TRUE);

-- Deaktivirani korisnik (za testiranje)
INSERT INTO users (username, email, password_hash, first_name, last_name, is_active) VALUES
('inactive_user', 'inactive@company.hr', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.G5FuIQ.Gu.sKyW', 'Inactive', 'User', FALSE);


-- POČETNI PODACI - USER_ROLES (Dodjela uloga)
-- Admin dobiva ADMIN ulogu
INSERT INTO user_roles (user_id, role_id, assigned_by)
SELECT u.user_id, r.role_id, u.user_id
FROM users u, roles r
WHERE u.username = 'admin' AND r.name = 'ADMIN';

-- Manageri dobivaju MANAGER ulogu
INSERT INTO user_roles (user_id, role_id, assigned_by)
SELECT u.user_id, r.role_id, (SELECT user_id FROM users WHERE username = 'admin')
FROM users u, roles r
WHERE u.username IN ('ivan_manager', 'ana_manager') AND r.name = 'MANAGER';

-- Zaposlenici dobivaju EMPLOYEE ulogu
INSERT INTO user_roles (user_id, role_id, assigned_by)
SELECT u.user_id, r.role_id, (SELECT user_id FROM users WHERE username = 'admin')
FROM users u, roles r
WHERE u.username IN ('marko_dev', 'petra_dev', 'luka_dev', 'maja_design', 'tomislav_design', 'inactive_user') 
AND r.name = 'EMPLOYEE';


-- POČETNI PODACI - TASKS (Testni zadaci)
-- Zadaci od Ivan Horvat (Manager)
INSERT INTO tasks (title, description, status, priority, due_date, created_by, assigned_to) VALUES
(
    'Implementacija login stranice',
    'Kreirati responzivnu login stranicu s validacijom forme i error handling-om',
    'IN_PROGRESS',
    'HIGH',
    CURRENT_DATE + INTERVAL '7 days',
    (SELECT user_id FROM users WHERE username = 'ivan_manager'),
    (SELECT user_id FROM users WHERE username = 'marko_dev')
),
(
    'Postavljanje baze podataka',
    'Instalirati PostgreSQL i kreirati shemu baze prema specifikaciji',
    'COMPLETED',
    'URGENT',
    CURRENT_DATE - INTERVAL '2 days',
    (SELECT user_id FROM users WHERE username = 'ivan_manager'),
    (SELECT user_id FROM users WHERE username = 'petra_dev')
),
(
    'API dokumentacija',
    'Napisati OpenAPI/Swagger dokumentaciju za REST API',
    'NEW',
    'MEDIUM',
    CURRENT_DATE + INTERVAL '14 days',
    (SELECT user_id FROM users WHERE username = 'ivan_manager'),
    (SELECT user_id FROM users WHERE username = 'luka_dev')
),
(
    'Code review - autentikacija',
    'Pregledati kod za autentikacijski modul',
    'ON_HOLD',
    'MEDIUM',
    NULL,
    (SELECT user_id FROM users WHERE username = 'ivan_manager'),
    NULL
);

-- Ažuriraj completed_at za završeni zadatak
UPDATE tasks 
SET completed_at = CURRENT_TIMESTAMP - INTERVAL '1 day'
WHERE title = 'Postavljanje baze podataka';

-- Zadaci od Ana Kovač (Manager)
INSERT INTO tasks (title, description, status, priority, due_date, created_by, assigned_to) VALUES
(
    'Dizajn dashboard-a',
    'Kreirati wireframe i mockup za glavni dashboard korisnika',
    'IN_PROGRESS',
    'HIGH',
    CURRENT_DATE + INTERVAL '5 days',
    (SELECT user_id FROM users WHERE username = 'ana_manager'),
    (SELECT user_id FROM users WHERE username = 'maja_design')
),
(
    'Logo redesign',
    'Osvježiti logotip tvrtke prema novim brand smjernicama',
    'NEW',
    'LOW',
    CURRENT_DATE + INTERVAL '30 days',
    (SELECT user_id FROM users WHERE username = 'ana_manager'),
    (SELECT user_id FROM users WHERE username = 'tomislav_design')
),
(
    'UI komponente',
    'Dizajnirati set UI komponenti za design system',
    'IN_PROGRESS',
    'MEDIUM',
    CURRENT_DATE + INTERVAL '10 days',
    (SELECT user_id FROM users WHERE username = 'ana_manager'),
    (SELECT user_id FROM users WHERE username = 'maja_design')
);


-- POČETNI PODACI - LOGIN_EVENTS (Primjer prijava)
-- Uspješne prijave
INSERT INTO login_events (user_id, username_attempted, ip_address, user_agent, success) VALUES
((SELECT user_id FROM users WHERE username = 'admin'), 'admin', '192.168.1.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0', TRUE),
((SELECT user_id FROM users WHERE username = 'ivan_manager'), 'ivan_manager', '192.168.1.10', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Firefox/121.0', TRUE),
((SELECT user_id FROM users WHERE username = 'marko_dev'), 'marko_dev', '192.168.1.20', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Safari/17.0', TRUE);

-- Neuspješne prijave
INSERT INTO login_events (user_id, username_attempted, ip_address, user_agent, success, failure_reason) VALUES
((SELECT user_id FROM users WHERE username = 'admin'), 'admin', '192.168.1.100', 'Mozilla/5.0 (Windows NT 10.0) Chrome/120.0', FALSE, 'INVALID_CREDENTIALS'),
(NULL, 'nonexistent_user', '10.0.0.50', 'curl/7.81.0', FALSE, 'INVALID_CREDENTIALS'),
((SELECT user_id FROM users WHERE username = 'inactive_user'), 'inactive_user', '192.168.1.55', 'Mozilla/5.0 Firefox/121.0', FALSE, 'ACCOUNT_INACTIVE');



-- VERIFIKACIJA PODATAKA
DO $$
DECLARE
    v_users_count INTEGER;
    v_roles_count INTEGER;
    v_permissions_count INTEGER;
    v_tasks_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_users_count FROM users;
    SELECT COUNT(*) INTO v_roles_count FROM roles;
    SELECT COUNT(*) INTO v_permissions_count FROM permissions;
    SELECT COUNT(*) INTO v_tasks_count FROM tasks;
    
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'FAZA 4 - Početni podaci uspješno uneseni!';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Statistika:';
    RAISE NOTICE '  - Korisnika: %', v_users_count;
    RAISE NOTICE '  - Uloga: %', v_roles_count;
    RAISE NOTICE '  - Prava: %', v_permissions_count;
    RAISE NOTICE '  - Zadataka: %', v_tasks_count;
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Testni korisnici (lozinka za sve: Password123!):';
    RAISE NOTICE '  - admin (Administrator)';
    RAISE NOTICE '  - ivan_manager, ana_manager (Manageri)';
    RAISE NOTICE '  - marko_dev, petra_dev, luka_dev (Zaposlenici - tim Ivan)';
    RAISE NOTICE '  - maja_design, tomislav_design (Zaposlenici - tim Ana)';
    RAISE NOTICE '============================================================';
END $$;
