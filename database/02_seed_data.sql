-- Interni sustav za upravljanje zaposlenicima i zadacima
SET search_path TO employee_management;


-- POCETNI PODACI - PERMISSIONS (Prava pristupa)
-- Upravljanje korisnicima
INSERT INTO permissions (code, name, description, category) VALUES
('USER_CREATE', 'Kreiranje korisnika', 'Mogucnost kreiranja novih korisnickih racuna', 'USER'),
('USER_READ_ALL', 'Pregled svih korisnika', 'Mogucnost pregleda svih korisnika u sustavu', 'USER'),
('USER_READ_TEAM', 'Pregled tima', 'Mogucnost pregleda korisnika u vlastitom timu', 'USER'),
('USER_READ_SELF', 'Pregled vlastitih podataka', 'Mogucnost pregleda vlastitih podataka', 'USER'),
('USER_UPDATE_ALL', 'Uredj rating svih korisnika', 'Mogucnost uredjivanja svih korisnickih racuna', 'USER'),
('USER_UPDATE_SELF', 'Uredjivanje vlastitih podataka', 'Mogucnost uredjivanja vlastitih podataka', 'USER'),
('USER_DEACTIVATE', 'Deaktivacija korisnika', 'Mogucnost deaktivacije korisnickih racuna', 'USER');

-- Upravljanje ulogama
INSERT INTO permissions (code, name, description, category) VALUES
('ROLE_CREATE', 'Kreiranje uloga', 'Mogucnost kreiranja novih uloga', 'ROLE'),
('ROLE_READ', 'Pregled uloga', 'Mogucnost pregleda uloga u sustavu', 'ROLE'),
('ROLE_UPDATE', 'Uredjivanje uloga', 'Mogucnost uredjivanja postojecih uloga', 'ROLE'),
('ROLE_DELETE', 'Brisanje uloga', 'Mogucnost brisanja uloga', 'ROLE'),
('ROLE_ASSIGN', 'Dodjela uloga', 'Mogucnost dodjeljivanja uloga korisnicima', 'ROLE'),
('PERMISSION_MANAGE', 'Upravljanje pravima', 'Mogucnost upravljanja pravima pristupa', 'ROLE');

-- Upravljanje zadacima
INSERT INTO permissions (code, name, description, category) VALUES
('TASK_CREATE', 'Kreiranje zadataka', 'Mogucnost kreiranja novih zadataka', 'TASK'),
('TASK_ASSIGN', 'Dodjela zadataka', 'Mogucnost dodjeljivanja zadataka korisnicima', 'TASK'),
('TASK_READ_ALL', 'Pregled svih zadataka', 'Mogucnost pregleda svih zadataka u sustavu', 'TASK'),
('TASK_READ_TEAM', 'Pregled zadataka tima', 'Mogucnost pregleda zadataka u vlastitom timu', 'TASK'),
('TASK_READ_SELF', 'Pregled vlastitih zadataka', 'Mogucnost pregleda vlastitih zadataka', 'TASK'),
('TASK_UPDATE_ANY', 'Uredjivanje svih zadataka', 'Mogucnost uredjivanja bilo kojeg zadatka', 'TASK'),
('TASK_UPDATE_SELF_STATUS', 'Azuriranje statusa', 'Mogucnost azuriranja statusa vlastitih zadataka', 'TASK'),
('TASK_DELETE', 'Brisanje zadataka', 'Mogucnost brisanja zadataka', 'TASK');

-- Audit i meta-podaci
INSERT INTO permissions (code, name, description, category) VALUES
('AUDIT_READ_ALL', 'Pregled audit zapisa', 'Mogucnost pregleda svih audit zapisa', 'AUDIT'),
('LOGIN_EVENTS_READ_ALL', 'Pregled svih prijava', 'Mogucnost pregleda svih prijava u sustav', 'AUDIT'),
('LOGIN_EVENTS_READ_SELF', 'Pregled vlastitih prijava', 'Mogucnost pregleda vlastitih prijava', 'AUDIT');


-- POCETNI PODACI - ROLES (Uloge)
INSERT INTO roles (name, description, is_system) VALUES
('ADMIN', 'Administrator sustava s punim pristupom svim funkcionalnostima', TRUE),
('MANAGER', 'Voditelj tima koji upravlja zaposlenicima i zadacima', TRUE),
('EMPLOYEE', 'Zaposlenik s pristupom vlastitim podacima i zadacima', TRUE);


-- POCETNI PODACI - ROLE_PERMISSIONS (RBAC Matrix)
-- ADMIN 
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
    (SELECT role_id FROM roles WHERE name = 'ADMIN'),
    permission_id
FROM permissions;

-- MANAGER 
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
    (SELECT role_id FROM roles WHERE name = 'MANAGER'),
    permission_id
FROM permissions
WHERE code IN (
    'USER_READ_ALL', 'USER_READ_TEAM', 'USER_READ_SELF', 'USER_UPDATE_SELF',
    'ROLE_READ',
    'TASK_CREATE', 'TASK_ASSIGN', 'TASK_READ_ALL', 'TASK_READ_TEAM', 'TASK_UPDATE_ANY', 'TASK_DELETE',
    'LOGIN_EVENTS_READ_SELF'
);

-- EMPLOYEE 
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
    (SELECT role_id FROM roles WHERE name = 'EMPLOYEE'),
    permission_id
FROM permissions
WHERE code IN (
    'USER_READ_SELF', 'USER_UPDATE_SELF',
    'TASK_READ_SELF', 'TASK_UPDATE_SELF_STATUS',
    'LOGIN_EVENTS_READ_SELF'
);


-- POCETNI PODACI - USERS
-- Admin (lozinka: Admin123!)
INSERT INTO users (username, email, password_hash, first_name, last_name, manager_id, is_active) VALUES
('admin', 'admin@example.com', '$2b$12$WErNpEAgQFi6N6TXILJhpe9fVXBIQVKhEC4xFn55PIz6Tl0izHRmG', 'System', 'Admin', NULL, TRUE);

-- Manageri 
-- Ivan (lozinka: IvanM2024!)
-- Ana (lozinka: AnaK2024!)
INSERT INTO users (username, email, password_hash, first_name, last_name, manager_id, is_active) VALUES
('ivan_manager', 'ivan.horvat@example.com', '$2b$12$OiJvRGwQdtR4BAVFibFBJOr87F8EpTGwnSQsTyK3rtYuHgwmX0RpO', 'Ivan', 'Horvat', (SELECT user_id FROM users WHERE username = 'admin'), TRUE),
('ana_manager', 'ana.kovac@example.com', '$2b$12$YW3fZn9imJYh00WpbiPEN.VC.x4bw5Tz4RzQjvmzxfcTccXYZcUxG', 'Ana', 'Kovac', (SELECT user_id FROM users WHERE username = 'admin'), TRUE);

-- Zaposlenici - Development Team (pod Ivanom)
-- Marko (lozinka: Marko2024!)
-- Petra (lozinka: Petra2024!)
-- Luka (lozinka: Luka2024!)
INSERT INTO users (username, email, password_hash, first_name, last_name, manager_id, is_active) VALUES
('marko_dev', 'marko.novak@example.com', '$2b$12$lW3xA6KVqZFmG.8hmTpqL.ag7AKtMLAY5Imm70G1iL7/s8SgsV9Ce', 'Marko', 'Novak', (SELECT user_id FROM users WHERE username = 'ivan_manager'), TRUE),
('petra_dev', 'petra.juric@example.com', '$2b$12$LBORJY4LXCJ6YMYawZ68vuzZnP.OKgNID2q50v8AaLgy3HNu58U/W', 'Petra', 'Juric', (SELECT user_id FROM users WHERE username = 'ivan_manager'), TRUE),
('luka_dev', 'luka.baric@example.com', '$2b$12$PKCjJ/dHLfDP7t3FFXrRSe4bLAZdRN4rotU8G1jPHqloFUdhc0k9.', 'Luka', 'Baric', (SELECT user_id FROM users WHERE username = 'ivan_manager'), TRUE);

-- Zaposlenici - Design Team (pod Anom)
-- Maja (lozinka: Maja2024!)
-- Tomislav (lozinka: Tomi2024!)
INSERT INTO users (username, email, password_hash, first_name, last_name, manager_id, is_active) VALUES
('maja_design', 'maja.pavic@example.com', '$2b$12$Dek2mc1v4YaS6eEmiymTWu3UvPYJdeUty33SUIelplQTVxUu78yQ2', 'Maja', 'Pavic', (SELECT user_id FROM users WHERE username = 'ana_manager'), TRUE),
('tomislav_design', 'tomislav.knez@example.com', '$2b$12$2KCwi7wDeJiUJtB.k.M/2.Bzd8ZteugiwXAY2A2tJvseseA7WQZKm', 'Tomislav', 'Knez', (SELECT user_id FROM users WHERE username = 'ana_manager'), TRUE);

-- Deaktivirani korisnik (lozinka: Old2024!)
INSERT INTO users (username, email, password_hash, first_name, last_name, manager_id, is_active) VALUES
('old_employee', 'old.employee@example.com', '$2b$12$ndN1tt1WGFCk1O2KeQjnBOPph78lpfcOHie7fr9r956i2QHQ9W57i', 'Old', 'Employee', NULL, FALSE);


-- POCETNI PODACI - USER_ROLES 
-- Admin
INSERT INTO user_roles (user_id, role_id)
VALUES (
    (SELECT user_id FROM users WHERE username = 'admin'),
    (SELECT role_id FROM roles WHERE name = 'ADMIN')
);

-- Manageri
INSERT INTO user_roles (user_id, role_id)
SELECT 
    user_id,
    (SELECT role_id FROM roles WHERE name = 'MANAGER')
FROM users
WHERE username IN ('ivan_manager', 'ana_manager');

-- Zaposlenici
INSERT INTO user_roles (user_id, role_id)
SELECT 
    user_id,
    (SELECT role_id FROM roles WHERE name = 'EMPLOYEE')
FROM users
WHERE username IN ('marko_dev', 'petra_dev', 'luka_dev', 'maja_design', 'tomislav_design');

-- Deaktivirani korisnik 
INSERT INTO user_roles (user_id, role_id)
VALUES (
    (SELECT user_id FROM users WHERE username = 'old_employee'),
    (SELECT role_id FROM roles WHERE name = 'EMPLOYEE')
);


-- POCETNI PODACI - TASKS 
-- Zadaci od Ivan Horvat (Manager)
INSERT INTO tasks (title, description, status, priority, due_date, created_by, assigned_to, created_at, completed_at) VALUES
(
    'Implementacija login stranice',
    'Kreirati responzivnu login stranicu s validacijom forme i error handling-om',
    'IN_PROGRESS',
    'HIGH',
    CURRENT_DATE + INTERVAL '7 days',
    (SELECT user_id FROM users WHERE username = 'ivan_manager'),
    (SELECT user_id FROM users WHERE username = 'marko_dev'),
    CURRENT_TIMESTAMP,
    NULL
),
(
    'Postavljanje baze podataka',
    'Instalirati PostgreSQL i kreirati shemu baze prema specifikaciji',
    'COMPLETED',
    'URGENT',
    CURRENT_DATE - INTERVAL '2 days',
    (SELECT user_id FROM users WHERE username = 'ivan_manager'),
    (SELECT user_id FROM users WHERE username = 'petra_dev'),
    CURRENT_TIMESTAMP - INTERVAL '2 days',
    CURRENT_TIMESTAMP - INTERVAL '1 day'
),
(
    'API dokumentacija',
    'Napisati OpenAPI/Swagger dokumentaciju za REST API',
    'NEW',
    'MEDIUM',
    CURRENT_DATE + INTERVAL '14 days',
    (SELECT user_id FROM users WHERE username = 'ivan_manager'),
    (SELECT user_id FROM users WHERE username = 'luka_dev'),
    CURRENT_TIMESTAMP,
    NULL
),
(
    'Code review - autentikacija',
    'Pregledati kod za autentikacijski modul',
    'ON_HOLD',
    'MEDIUM',
    NULL,
    (SELECT user_id FROM users WHERE username = 'ivan_manager'),
    NULL,
    CURRENT_TIMESTAMP,
    NULL
);

-- Zadaci od Ana Kovac (Manager)
INSERT INTO tasks (title, description, status, priority, due_date, created_by, assigned_to, created_at, completed_at) VALUES
(
    'Dizajn dashboard-a',
    'Kreirati wireframe i mockup za glavni dashboard korisnika',
    'IN_PROGRESS',
    'HIGH',
    CURRENT_DATE + INTERVAL '5 days',
    (SELECT user_id FROM users WHERE username = 'ana_manager'),
    (SELECT user_id FROM users WHERE username = 'maja_design'),
    CURRENT_TIMESTAMP,
    NULL
),
(
    'Logo redesign',
    'Osvjeziti logotip tvrtke prema novim brand smjernicama',
    'NEW',
    'LOW',
    CURRENT_DATE + INTERVAL '30 days',
    (SELECT user_id FROM users WHERE username = 'ana_manager'),
    (SELECT user_id FROM users WHERE username = 'tomislav_design'),
    CURRENT_TIMESTAMP,
    NULL
),
(
    'UI komponente',
    'Dizajnirati set UI komponenti za design system',
    'IN_PROGRESS',
    'MEDIUM',
    CURRENT_DATE + INTERVAL '10 days',
    (SELECT user_id FROM users WHERE username = 'ana_manager'),
    (SELECT user_id FROM users WHERE username = 'maja_design'),
    CURRENT_TIMESTAMP,
    NULL
);


-- POCETNI PODACI - LOGIN_EVENTS 
-- Uspjesne prijave
INSERT INTO login_events (user_id, username_attempted, login_time, ip_address, user_agent, success) VALUES
((SELECT user_id FROM users WHERE username = 'admin'), 'admin', CURRENT_TIMESTAMP - INTERVAL '2 hours', '192.168.1.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', TRUE),
((SELECT user_id FROM users WHERE username = 'ivan_manager'), 'ivan_manager', CURRENT_TIMESTAMP - INTERVAL '1 hour', '192.168.1.5', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', TRUE),
((SELECT user_id FROM users WHERE username = 'marko_dev'), 'marko_dev', CURRENT_TIMESTAMP - INTERVAL '30 minutes', '192.168.1.10', 'Mozilla/5.0 (X11; Linux x86_64)', TRUE);

-- Neuspjesne prijave (pogresna lozinka)
INSERT INTO login_events (user_id, username_attempted, login_time, ip_address, user_agent, success, failure_reason) VALUES
((SELECT user_id FROM users WHERE username = 'admin'), 'admin', CURRENT_TIMESTAMP - INTERVAL '3 hours', '192.168.1.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', FALSE, 'INVALID_CREDENTIALS'),
(NULL, 'nonexistent_user', CURRENT_TIMESTAMP - INTERVAL '1 hour 30 minutes', '203.0.113.42', 'curl/7.68.0', FALSE, 'INVALID_CREDENTIALS');

-- Pokusaj prijave na deaktivirani racun
INSERT INTO login_events (user_id, username_attempted, login_time, ip_address, user_agent, success, failure_reason) VALUES
((SELECT user_id FROM users WHERE username = 'old_employee'), 'old_employee', CURRENT_TIMESTAMP - INTERVAL '45 minutes', '192.168.1.20', 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6)', FALSE, 'ACCOUNT_INACTIVE');


-- POCETNI PODACI - AUDIT_LOG 
-- Audit za kreiranje admin korisnika
INSERT INTO audit_log (changed_by, action, entity_name, entity_id, old_value, new_value, ip_address) VALUES
((SELECT user_id FROM users WHERE username = 'admin'), 'INSERT', 'users', 1, NULL, '{"username":"admin","email":"admin@example.com"}', '192.168.1.1');

-- Audit za kreiranje zadatka
INSERT INTO audit_log (changed_by, action, entity_name, entity_id, old_value, new_value, ip_address) VALUES
((SELECT user_id FROM users WHERE username = 'ivan_manager'), 'INSERT', 'tasks', 1, NULL, '{"title":"Implementacija login stranice","status":"IN_PROGRESS","priority":"HIGH"}', '192.168.1.5');

-- Audit za azuriranje zadatka
INSERT INTO audit_log (changed_by, action, entity_name, entity_id, old_value, new_value, ip_address) VALUES
((SELECT user_id FROM users WHERE username = 'petra_dev'), 'UPDATE', 'tasks', 2, '{"status":"IN_PROGRESS"}', '{"status":"COMPLETED","completed_at":"2025-12-22"}', '192.168.1.12');

-- Audit za deaktivaciju korisnika
INSERT INTO audit_log (changed_by, action, entity_name, entity_id, old_value, new_value, ip_address) VALUES
((SELECT user_id FROM users WHERE username = 'admin'), 'UPDATE', 'users', 13, '{"is_active":true}', '{"is_active":false}', '192.168.1.1');

-- Audit za dodjeljivanje uloge  
INSERT INTO audit_log (changed_by, action, entity_name, entity_id, old_value, new_value, ip_address) VALUES
((SELECT user_id FROM users WHERE username = 'admin'), 'INSERT', 'user_roles', 1, NULL, '{"user_id":2,"role_id":3}', '192.168.1.1');

-- Audit za brisanje zadatka (simulacija - zadatak nije stvarno obrisan)
INSERT INTO audit_log (changed_by, action, entity_name, entity_id, old_value, new_value, ip_address) VALUES
((SELECT user_id FROM users WHERE username = 'ivan_manager'), 'DELETE', 'tasks', 9999, '{"title":"Stari zadatak","status":"CANCELLED"}', NULL, '192.168.1.5');
