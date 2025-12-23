
SET search_path TO employee_management;


-- Funkcija za validaciju email formata
CREATE OR REPLACE FUNCTION validate_email(email_input TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN email_input ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION validate_email(TEXT) IS 'Validira format email adrese koristeci regex';


-- Funkcija za generiranje slug-a od teksta
CREATE OR REPLACE FUNCTION generate_slug(input_text TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN LOWER(
        REGEXP_REPLACE(
            REGEXP_REPLACE(
                TRIM(input_text),
                '[^a-zA-Z0-9\s-]', '', 'g'
            ),
            '\s+', '-', 'g'
        )
    );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION generate_slug(TEXT) IS 'Generira URL-friendly slug od teksta';


-- Funkcija za provjeru jacine lozinke
CREATE OR REPLACE FUNCTION check_password_strength(password TEXT)
RETURNS TABLE(is_valid BOOLEAN, message TEXT) AS $$
BEGIN
    -- Minimalno 8 karaktera
    IF LENGTH(password) < 8 THEN
        RETURN QUERY SELECT FALSE, 'Lozinka mora imati minimalno 8 karaktera';
        RETURN;
    END IF;
    
    -- Mora sadrzavati veliko slovo
    IF password !~ '[A-Z]' THEN
        RETURN QUERY SELECT FALSE, 'Lozinka mora sadrzavati barem jedno veliko slovo';
        RETURN;
    END IF;
    
    -- Mora sadrzavati malo slovo
    IF password !~ '[a-z]' THEN
        RETURN QUERY SELECT FALSE, 'Lozinka mora sadrzavati barem jedno malo slovo';
        RETURN;
    END IF;
    
    -- Mora sadrzavati broj
    IF password !~ '[0-9]' THEN
        RETURN QUERY SELECT FALSE, 'Lozinka mora sadrzavati barem jedan broj';
        RETURN;
    END IF;
    
    -- Mora sadrzavati specijalni karakter
    IF password !~ '[!@#$%^&*(),.?":{}|<>]' THEN
        RETURN QUERY SELECT FALSE, 'Lozinka mora sadrzavati barem jedan specijalni karakter';
        RETURN;
    END IF;
    
    RETURN QUERY SELECT TRUE, 'Lozinka zadovoljava sve kriterije';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION check_password_strength(TEXT) IS 'Provjerava jacinu lozinke prema sigurnosnim kriterijima';



-- Funkcija za provjeru da li korisnik ima odredjenu permisiju
CREATE OR REPLACE FUNCTION user_has_permission(
    p_user_id INTEGER,
    p_permission_code VARCHAR(50)
)
RETURNS BOOLEAN AS $$
DECLARE
    v_has_permission BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1
        FROM user_roles ur
        JOIN role_permissions rp ON ur.role_id = rp.role_id
        JOIN permissions p ON rp.permission_id = p.permission_id
        WHERE ur.user_id = p_user_id
        AND p.code = p_permission_code
    ) INTO v_has_permission;
    
    RETURN v_has_permission;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION user_has_permission(INTEGER, VARCHAR) IS 'Provjerava da li korisnik ima odredjenu permisiju kroz svoje uloge';


-- Funkcija za dohvacanje svih permisija korisnika
CREATE OR REPLACE FUNCTION get_user_permissions(p_user_id INTEGER)
RETURNS TABLE(
    permission_code VARCHAR(50),
    permission_name VARCHAR(100),
    category VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT 
        p.code,
        p.name,
        p.category
    FROM user_roles ur
    JOIN role_permissions rp ON ur.role_id = rp.role_id
    JOIN permissions p ON rp.permission_id = p.permission_id
    WHERE ur.user_id = p_user_id
    ORDER BY p.category, p.code;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_user_permissions(INTEGER) IS 'Vraca sve permisije koje korisnik ima kroz svoje uloge';


-- Funkcija za dohvacanje uloga korisnika
CREATE OR REPLACE FUNCTION get_user_roles(p_user_id INTEGER)
RETURNS TABLE(
    role_id INTEGER,
    role_name VARCHAR(50),
    role_description TEXT,
    assigned_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.role_id,
        r.name,
        r.description,
        ur.assigned_at
    FROM user_roles ur
    JOIN roles r ON ur.role_id = r.role_id
    WHERE ur.user_id = p_user_id
    ORDER BY ur.assigned_at;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_user_roles(INTEGER) IS 'Vraca sve uloge dodijeljene korisniku';


-- Funkcija za provjeru da li je korisnik manager drugog korisnika
CREATE OR REPLACE FUNCTION is_manager_of(
    p_manager_id INTEGER,
    p_employee_id INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    v_is_manager BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1
        FROM users
        WHERE user_id = p_employee_id
        AND manager_id = p_manager_id
    ) INTO v_is_manager;
    
    RETURN v_is_manager;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION is_manager_of(INTEGER, INTEGER) IS 'Provjerava da li je prvi korisnik manager drugog korisnika';


-- Funkcija za dohvacanje clanova tima
CREATE OR REPLACE FUNCTION get_team_members(p_manager_id INTEGER)
RETURNS TABLE(
    user_id INTEGER,
    username VARCHAR(50),
    full_name TEXT,
    email VARCHAR(255),
    is_active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.user_id,
        u.username,
        u.first_name || ' ' || u.last_name AS full_name,
        u.email::VARCHAR(255),
        u.is_active
    FROM users u
    WHERE u.manager_id = p_manager_id
    ORDER BY u.last_name, u.first_name;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_team_members(INTEGER) IS 'Vraca sve clanove tima za odredjenog managera';



-- Funkcija za dohvacanje zadataka korisnika
CREATE OR REPLACE FUNCTION get_user_tasks(
    p_user_id INTEGER,
    p_status task_status DEFAULT NULL,
    p_include_created BOOLEAN DEFAULT FALSE
)
RETURNS TABLE(
    task_id INTEGER,
    title VARCHAR(200),
    description TEXT,
    status task_status,
    priority task_priority,
    due_date DATE,
    is_overdue BOOLEAN,
    creator_name TEXT,
    assignee_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.task_id,
        t.title,
        t.description,
        t.status,
        t.priority,
        t.due_date,
        (t.due_date < CURRENT_DATE AND t.status NOT IN ('COMPLETED', 'CANCELLED')) AS is_overdue,
        (SELECT first_name || ' ' || last_name FROM users WHERE user_id = t.created_by) AS creator_name,
        (SELECT first_name || ' ' || last_name FROM users WHERE user_id = t.assigned_to) AS assignee_name
    FROM tasks t
    WHERE (t.assigned_to = p_user_id OR (p_include_created AND t.created_by = p_user_id))
    AND (p_status IS NULL OR t.status = p_status)
    ORDER BY 
        CASE t.priority 
            WHEN 'URGENT' THEN 1 
            WHEN 'HIGH' THEN 2 
            WHEN 'MEDIUM' THEN 3 
            WHEN 'LOW' THEN 4 
        END,
        t.due_date NULLS LAST;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_user_tasks(INTEGER, task_status, BOOLEAN) IS 'Vraca zadatke dodijeljene korisniku sa opcijama filtriranja';


-- Funkcija za statistiku zadataka korisnika
CREATE OR REPLACE FUNCTION get_task_statistics(p_user_id INTEGER)
RETURNS TABLE(
    total_tasks BIGINT,
    completed_tasks BIGINT,
    in_progress_tasks BIGINT,
    overdue_tasks BIGINT,
    completion_rate NUMERIC(5,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) AS total_tasks,
        COUNT(*) FILTER (WHERE t.status = 'COMPLETED') AS completed_tasks,
        COUNT(*) FILTER (WHERE t.status = 'IN_PROGRESS') AS in_progress_tasks,
        COUNT(*) FILTER (WHERE t.due_date < CURRENT_DATE AND t.status NOT IN ('COMPLETED', 'CANCELLED')) AS overdue_tasks,
        CASE 
            WHEN COUNT(*) > 0 
            THEN ROUND((COUNT(*) FILTER (WHERE t.status = 'COMPLETED')::NUMERIC / COUNT(*)) * 100, 2)
            ELSE 0 
        END AS completion_rate
    FROM tasks t
    WHERE t.assigned_to = p_user_id;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_task_statistics(INTEGER) IS 'Vraca statistiku zadataka za korisnika';



-- Procedura za kreiranje korisnika
CREATE OR REPLACE PROCEDURE create_user(
    p_username VARCHAR(50),
    p_email VARCHAR(255),
    p_password_hash VARCHAR(255),
    p_first_name VARCHAR(100),
    p_last_name VARCHAR(100),
    p_manager_id INTEGER DEFAULT NULL,
    p_role_name VARCHAR(50) DEFAULT 'EMPLOYEE',
    p_created_by INTEGER DEFAULT NULL,
    INOUT p_new_user_id INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_role_id INTEGER;
BEGIN
    -- Provjera da li username vec postoji
    IF EXISTS(SELECT 1 FROM users WHERE username = p_username) THEN
        RAISE EXCEPTION 'Korisnicko ime % vec postoji', p_username;
    END IF;
    
    -- Provjera da li email vec postoji
    IF EXISTS(SELECT 1 FROM users WHERE email = p_email::email_address) THEN
        RAISE EXCEPTION 'Email % vec postoji', p_email;
    END IF;
    
    -- Provjera da li manager postoji
    IF p_manager_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM users WHERE user_id = p_manager_id) THEN
        RAISE EXCEPTION 'Manager sa ID % ne postoji', p_manager_id;
    END IF;
    
    -- Dohvati role_id
    SELECT role_id INTO v_role_id FROM roles WHERE name = p_role_name;
    IF v_role_id IS NULL THEN
        RAISE EXCEPTION 'Uloga % ne postoji', p_role_name;
    END IF;
    
    -- Kreiraj korisnika
    INSERT INTO users (username, email, password_hash, first_name, last_name, manager_id)
    VALUES (p_username, p_email::email_address, p_password_hash, p_first_name, p_last_name, p_manager_id)
    RETURNING user_id INTO p_new_user_id;
    
    -- Dodijeli ulogu
    INSERT INTO user_roles (user_id, role_id, assigned_by)
    VALUES (p_new_user_id, v_role_id, p_created_by);
    
    RAISE NOTICE 'Korisnik % uspjesno kreiran sa ID %', p_username, p_new_user_id;
END;
$$;

COMMENT ON PROCEDURE create_user IS 'Kreira novog korisnika i dodjeljuje mu pocetnu ulogu';


-- Procedura za azuriranje korisnika
CREATE OR REPLACE PROCEDURE update_user(
    p_user_id INTEGER,
    p_first_name VARCHAR(100) DEFAULT NULL,
    p_last_name VARCHAR(100) DEFAULT NULL,
    p_email VARCHAR(255) DEFAULT NULL,
    p_manager_id INTEGER DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT NULL,
    p_updated_by INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_values JSONB;
    v_new_values JSONB;
BEGIN
    -- Provjera da li korisnik postoji
    IF NOT EXISTS(SELECT 1 FROM users WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'Korisnik sa ID % ne postoji', p_user_id;
    END IF;
    
    -- Sacuvaj stare vrijednosti za audit
    SELECT jsonb_build_object(
        'first_name', first_name,
        'last_name', last_name,
        'email', email,
        'manager_id', manager_id,
        'is_active', is_active
    ) INTO v_old_values
    FROM users WHERE user_id = p_user_id;
    
    -- Azuriraj korisnika
    UPDATE users SET
        first_name = COALESCE(p_first_name, first_name),
        last_name = COALESCE(p_last_name, last_name),
        email = COALESCE(p_email::email_address, email),
        manager_id = COALESCE(p_manager_id, manager_id),
        is_active = COALESCE(p_is_active, is_active),
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = p_user_id;
    
    -- Sacuvaj nove vrijednosti za audit
    SELECT jsonb_build_object(
        'first_name', first_name,
        'last_name', last_name,
        'email', email,
        'manager_id', manager_id,
        'is_active', is_active
    ) INTO v_new_values
    FROM users WHERE user_id = p_user_id;
    
    RAISE NOTICE 'Korisnik ID % uspjesno azuriran', p_user_id;
END;
$$;

COMMENT ON PROCEDURE update_user IS 'Azurira podatke korisnika';


-- Procedura za deaktivaciju korisnika
CREATE OR REPLACE PROCEDURE deactivate_user(
    p_user_id INTEGER,
    p_deactivated_by INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Provjera da li korisnik postoji
    IF NOT EXISTS(SELECT 1 FROM users WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'Korisnik sa ID % ne postoji', p_user_id;
    END IF;
    
    -- Provjera da korisnik ne deaktivira sam sebe
    IF p_user_id = p_deactivated_by THEN
        RAISE EXCEPTION 'Korisnik ne moze deaktivirati sam sebe';
    END IF;
    
    -- Deaktiviraj korisnika
    UPDATE users SET 
        is_active = FALSE,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = p_user_id;
    
    -- Ponisti sve nezavrsene zadatke
    UPDATE tasks SET 
        status = 'CANCELLED',
        updated_at = CURRENT_TIMESTAMP
    WHERE assigned_to = p_user_id 
    AND status NOT IN ('COMPLETED', 'CANCELLED');
    
    RAISE NOTICE 'Korisnik ID % deaktiviran', p_user_id;
END;
$$;

COMMENT ON PROCEDURE deactivate_user IS 'Deaktivira korisnika i ponistava njegove nezavrsene zadatke';


-- Procedura za kreiranje zadatka
CREATE OR REPLACE PROCEDURE create_task(
    p_title VARCHAR(200),
    p_description TEXT,
    p_priority task_priority,
    p_due_date DATE,
    p_created_by INTEGER,
    p_assigned_to INTEGER DEFAULT NULL,
    INOUT p_new_task_id INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Provjera da li kreator postoji i aktivan je
    IF NOT EXISTS(SELECT 1 FROM users WHERE user_id = p_created_by AND is_active = TRUE) THEN
        RAISE EXCEPTION 'Kreator sa ID % ne postoji ili nije aktivan', p_created_by;
    END IF;
    
    -- Provjera da li assignee postoji i aktivan je
    IF p_assigned_to IS NOT NULL AND NOT EXISTS(SELECT 1 FROM users WHERE user_id = p_assigned_to AND is_active = TRUE) THEN
        RAISE EXCEPTION 'Korisnik sa ID % ne postoji ili nije aktivan', p_assigned_to;
    END IF;
    
    -- Provjera da li due_date nije u proslosti
    IF p_due_date IS NOT NULL AND p_due_date < CURRENT_DATE THEN
        RAISE EXCEPTION 'Rok zadatka ne moze biti u proslosti';
    END IF;
    
    -- Kreiraj zadatak
    INSERT INTO tasks (title, description, priority, due_date, created_by, assigned_to, status)
    VALUES (p_title, p_description, p_priority, p_due_date, p_created_by, p_assigned_to, 'NEW')
    RETURNING task_id INTO p_new_task_id;
    
    RAISE NOTICE 'Zadatak "%" uspjesno kreiran sa ID %', p_title, p_new_task_id;
END;
$$;

COMMENT ON PROCEDURE create_task IS 'Kreira novi zadatak';


-- Procedura za azuriranje statusa zadatka
CREATE OR REPLACE PROCEDURE update_task_status(
    p_task_id INTEGER,
    p_new_status task_status,
    p_updated_by INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status task_status;
    v_assigned_to INTEGER;
    v_created_by INTEGER;
BEGIN
    -- Dohvati trenutni status i dodijeljenost
    SELECT status, assigned_to, created_by 
    INTO v_current_status, v_assigned_to, v_created_by
    FROM tasks WHERE task_id = p_task_id;
    
    IF v_current_status IS NULL THEN
        RAISE EXCEPTION 'Zadatak sa ID % ne postoji', p_task_id;
    END IF;
    
    -- Provjeri da li korisnik ima pravo azurirati ovaj zadatak
    IF v_assigned_to != p_updated_by AND v_created_by != p_updated_by THEN
        -- Provjeri da li ima TASK_UPDATE_ANY permisiju
        IF NOT user_has_permission(p_updated_by, 'TASK_UPDATE_ANY') THEN
            RAISE EXCEPTION 'Nemate dozvolu za azuriranje ovog zadatka';
        END IF;
    END IF;
    
    -- Validacija tranzicije statusa
    IF v_current_status = 'COMPLETED' AND p_new_status != 'COMPLETED' THEN
        RAISE EXCEPTION 'Nije moguce promijeniti status zavrsenog zadatka';
    END IF;
    
    IF v_current_status = 'CANCELLED' THEN
        RAISE EXCEPTION 'Nije moguce promijeniti status otkazanog zadatka';
    END IF;
    
    -- Azuriraj status
    UPDATE tasks SET 
        status = p_new_status,
        completed_at = CASE WHEN p_new_status = 'COMPLETED' THEN CURRENT_TIMESTAMP ELSE NULL END,
        updated_at = CURRENT_TIMESTAMP
    WHERE task_id = p_task_id;
    
    RAISE NOTICE 'Status zadatka ID % promijenjen iz % u %', p_task_id, v_current_status, p_new_status;
END;
$$;

COMMENT ON PROCEDURE update_task_status IS 'Azurira status zadatka sa validacijom permisija';


-- Procedura za dodjelu zadatka korisniku
CREATE OR REPLACE PROCEDURE assign_task(
    p_task_id INTEGER,
    p_assignee_id INTEGER,
    p_assigned_by INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_task_exists BOOLEAN;
BEGIN
    -- Provjera da li zadatak postoji
    SELECT EXISTS(SELECT 1 FROM tasks WHERE task_id = p_task_id) INTO v_task_exists;
    IF NOT v_task_exists THEN
        RAISE EXCEPTION 'Zadatak sa ID % ne postoji', p_task_id;
    END IF;
    
    -- Provjera da li korisnik postoji i aktivan je
    IF NOT EXISTS(SELECT 1 FROM users WHERE user_id = p_assignee_id AND is_active = TRUE) THEN
        RAISE EXCEPTION 'Korisnik sa ID % ne postoji ili nije aktivan', p_assignee_id;
    END IF;
    
    -- Provjera permisije
    IF NOT user_has_permission(p_assigned_by, 'TASK_ASSIGN') THEN
        RAISE EXCEPTION 'Nemate dozvolu za dodjelu zadataka';
    END IF;
    
    -- Dodijeli zadatak
    UPDATE tasks SET 
        assigned_to = p_assignee_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE task_id = p_task_id;
    
    RAISE NOTICE 'Zadatak ID % dodijeljen korisniku ID %', p_task_id, p_assignee_id;
END;
$$;

COMMENT ON PROCEDURE assign_task IS 'Dodjeljuje zadatak korisniku';


-- Procedura za dodjelu uloge korisniku
CREATE OR REPLACE PROCEDURE assign_role(
    p_user_id INTEGER,
    p_role_name VARCHAR(50),
    p_assigned_by INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_role_id INTEGER;
BEGIN
    -- Provjera permisije
    IF NOT user_has_permission(p_assigned_by, 'ROLE_ASSIGN') THEN
        RAISE EXCEPTION 'Nemate dozvolu za dodjelu uloga';
    END IF;
    
    -- Dohvati role_id
    SELECT role_id INTO v_role_id FROM roles WHERE name = p_role_name;
    IF v_role_id IS NULL THEN
        RAISE EXCEPTION 'Uloga % ne postoji', p_role_name;
    END IF;
    
    -- Provjera da li korisnik postoji
    IF NOT EXISTS(SELECT 1 FROM users WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'Korisnik sa ID % ne postoji', p_user_id;
    END IF;
    
    -- Provjera da li vec ima tu ulogu
    IF EXISTS(SELECT 1 FROM user_roles WHERE user_id = p_user_id AND role_id = v_role_id) THEN
        RAISE EXCEPTION 'Korisnik vec ima ulogu %', p_role_name;
    END IF;
    
    -- Dodijeli ulogu
    INSERT INTO user_roles (user_id, role_id, assigned_by)
    VALUES (p_user_id, v_role_id, p_assigned_by);
    
    RAISE NOTICE 'Uloga % dodijeljena korisniku ID %', p_role_name, p_user_id;
END;
$$;

COMMENT ON PROCEDURE assign_role IS 'Dodjeljuje ulogu korisniku';


-- Procedura za uklanjanje uloge od korisnika
CREATE OR REPLACE PROCEDURE revoke_role(
    p_user_id INTEGER,
    p_role_name VARCHAR(50),
    p_revoked_by INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_role_id INTEGER;
    v_user_role_count INTEGER;
BEGIN
    -- Provjera permisije
    IF NOT user_has_permission(p_revoked_by, 'ROLE_ASSIGN') THEN
        RAISE EXCEPTION 'Nemate dozvolu za uklanjanje uloga';
    END IF;
    
    -- Dohvati role_id
    SELECT role_id INTO v_role_id FROM roles WHERE name = p_role_name;
    IF v_role_id IS NULL THEN
        RAISE EXCEPTION 'Uloga % ne postoji', p_role_name;
    END IF;
    
    -- Provjera koliko uloga korisnik ima
    SELECT COUNT(*) INTO v_user_role_count FROM user_roles WHERE user_id = p_user_id;
    IF v_user_role_count <= 1 THEN
        RAISE EXCEPTION 'Korisnik mora imati barem jednu ulogu';
    END IF;
    
    -- Ukloni ulogu
    DELETE FROM user_roles 
    WHERE user_id = p_user_id AND role_id = v_role_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Korisnik nema ulogu %', p_role_name;
    END IF;
    
    RAISE NOTICE 'Uloga % uklonjena od korisnika ID %', p_role_name, p_user_id;
END;
$$;

COMMENT ON PROCEDURE revoke_role IS 'Uklanja ulogu od korisnika';

-- Trigger funkcija za audit log korisnika
CREATE OR REPLACE FUNCTION audit_users_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (entity_name, entity_id, action, changed_by, new_value)
        VALUES ('users', NEW.user_id, 'INSERT', NEW.user_id, 
            jsonb_build_object(
                'username', NEW.username,
                'email', NEW.email,
                'first_name', NEW.first_name,
                'last_name', NEW.last_name,
                'is_active', NEW.is_active
            )
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Samo loguj ako je doslo do stvarne promjene
        IF OLD.* IS DISTINCT FROM NEW.* THEN
            INSERT INTO audit_log (entity_name, entity_id, action, changed_by, old_value, new_value)
            VALUES ('users', NEW.user_id, 'UPDATE', NEW.user_id,
                jsonb_build_object(
                    'username', OLD.username,
                    'email', OLD.email,
                    'first_name', OLD.first_name,
                    'last_name', OLD.last_name,
                    'is_active', OLD.is_active
                ),
                jsonb_build_object(
                    'username', NEW.username,
                    'email', NEW.email,
                    'first_name', NEW.first_name,
                    'last_name', NEW.last_name,
                    'is_active', NEW.is_active
                )
            );
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (entity_name, entity_id, action, changed_by, old_value)
        VALUES ('users', OLD.user_id, 'DELETE', OLD.user_id,
            jsonb_build_object(
                'username', OLD.username,
                'email', OLD.email,
                'first_name', OLD.first_name,
                'last_name', OLD.last_name,
                'is_active', OLD.is_active
            )
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger za users tabelu
DROP TRIGGER IF EXISTS trg_audit_users ON users;
CREATE TRIGGER trg_audit_users
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION audit_users_changes();

COMMENT ON FUNCTION audit_users_changes() IS 'Trigger funkcija koja automatski loguje promjene na users tabeli';


-- Trigger funkcija za audit log zadataka
CREATE OR REPLACE FUNCTION audit_tasks_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (entity_name, entity_id, action, changed_by, new_value)
        VALUES ('tasks', NEW.task_id, 'INSERT', NEW.created_by,
            jsonb_build_object(
                'title', NEW.title,
                'status', NEW.status,
                'priority', NEW.priority,
                'assigned_to', NEW.assigned_to
            )
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.* IS DISTINCT FROM NEW.* THEN
            INSERT INTO audit_log (entity_name, entity_id, action, changed_by, old_value, new_value)
            VALUES ('tasks', NEW.task_id, 'UPDATE', NEW.created_by,
                jsonb_build_object(
                    'title', OLD.title,
                    'status', OLD.status,
                    'priority', OLD.priority,
                    'assigned_to', OLD.assigned_to
                ),
                jsonb_build_object(
                    'title', NEW.title,
                    'status', NEW.status,
                    'priority', NEW.priority,
                    'assigned_to', NEW.assigned_to
                )
            );
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (entity_name, entity_id, action, changed_by, old_value)
        VALUES ('tasks', OLD.task_id, 'DELETE', OLD.created_by,
            jsonb_build_object(
                'title', OLD.title,
                'status', OLD.status,
                'priority', OLD.priority,
                'assigned_to', OLD.assigned_to
            )
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger za tasks tabelu
DROP TRIGGER IF EXISTS trg_audit_tasks ON tasks;
CREATE TRIGGER trg_audit_tasks
    AFTER INSERT OR UPDATE OR DELETE ON tasks
    FOR EACH ROW EXECUTE FUNCTION audit_tasks_changes();

COMMENT ON FUNCTION audit_tasks_changes() IS 'Trigger funkcija koja automatski loguje promjene na tasks tabeli';


-- Trigger funkcija za audit log user_roles
CREATE OR REPLACE FUNCTION audit_user_roles_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_role_name VARCHAR(50);
    v_username VARCHAR(50);
BEGIN
    IF TG_OP = 'INSERT' THEN
        SELECT name INTO v_role_name FROM roles WHERE role_id = NEW.role_id;
        SELECT username INTO v_username FROM users WHERE user_id = NEW.user_id;
        
        INSERT INTO audit_log (entity_name, entity_id, action, changed_by, new_value)
        VALUES ('user_roles', NEW.user_role_id, 'INSERT', NEW.assigned_by,
            jsonb_build_object(
                'user_id', NEW.user_id,
                'username', v_username,
                'role_id', NEW.role_id,
                'role_name', v_role_name
            )
        );
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        SELECT name INTO v_role_name FROM roles WHERE role_id = OLD.role_id;
        SELECT username INTO v_username FROM users WHERE user_id = OLD.user_id;
        
        INSERT INTO audit_log (entity_name, entity_id, action, changed_by, old_value)
        VALUES ('user_roles', OLD.user_role_id, 'DELETE', OLD.assigned_by,
            jsonb_build_object(
                'user_id', OLD.user_id,
                'username', v_username,
                'role_id', OLD.role_id,
                'role_name', v_role_name
            )
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger za user_roles tabelu
DROP TRIGGER IF EXISTS trg_audit_user_roles ON user_roles;
CREATE TRIGGER trg_audit_user_roles
    AFTER INSERT OR DELETE ON user_roles
    FOR EACH ROW EXECUTE FUNCTION audit_user_roles_changes();

COMMENT ON FUNCTION audit_user_roles_changes() IS 'Trigger funkcija koja automatski loguje promjene na user_roles tabeli';



CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggeri za automatsko azuriranje updated_at
DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_roles_updated_at ON roles;
CREATE TRIGGER trg_roles_updated_at
    BEFORE UPDATE ON roles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_tasks_updated_at ON tasks;
CREATE TRIGGER trg_tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMENT ON FUNCTION update_updated_at_column() IS 'Automatski postavlja updated_at na trenutni timestamp';



CREATE OR REPLACE FUNCTION validate_manager_hierarchy()
RETURNS TRIGGER AS $$
DECLARE
    v_current_manager_id INTEGER;
    v_depth INTEGER := 0;
    v_max_depth INTEGER := 10;
BEGIN
    -- Preskoci ako nema managera
    IF NEW.manager_id IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Provjeri da korisnik nije sam sebi manager
    IF NEW.user_id = NEW.manager_id THEN
        RAISE EXCEPTION 'Korisnik ne moze biti sam sebi manager';
    END IF;
    
    -- Provjeri cirkularnu referencu
    v_current_manager_id := NEW.manager_id;
    WHILE v_current_manager_id IS NOT NULL AND v_depth < v_max_depth LOOP
        IF v_current_manager_id = NEW.user_id THEN
            RAISE EXCEPTION 'Cirkularna referenca u hijerarhiji managera nije dozvoljena';
        END IF;
        
        SELECT manager_id INTO v_current_manager_id
        FROM users WHERE user_id = v_current_manager_id;
        
        v_depth := v_depth + 1;
    END LOOP;
    
    IF v_depth >= v_max_depth THEN
        RAISE EXCEPTION 'Maksimalna dubina hijerarhije managera premasena';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validate_manager_hierarchy ON users;
CREATE TRIGGER trg_validate_manager_hierarchy
    BEFORE INSERT OR UPDATE OF manager_id ON users
    FOR EACH ROW EXECUTE FUNCTION validate_manager_hierarchy();

COMMENT ON FUNCTION validate_manager_hierarchy() IS 'Validira hijerarhiju managera i sprecava cirkularne reference';



CREATE OR REPLACE FUNCTION log_login_attempt(
    p_username VARCHAR(50),
    p_ip_address INET,
    p_user_agent TEXT,
    p_success BOOLEAN,
    p_failure_reason VARCHAR(50) DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    v_user_id INTEGER;
    v_login_event_id INTEGER;
BEGIN
    -- Pokusaj pronaci korisnika
    SELECT user_id INTO v_user_id FROM users WHERE username = p_username;
    
    -- Logiraj pokusaj
    INSERT INTO login_events (user_id, username_attempted, ip_address, user_agent, success, failure_reason)
    VALUES (v_user_id, p_username, p_ip_address, p_user_agent, p_success, p_failure_reason)
    RETURNING login_event_id INTO v_login_event_id;
    
    RETURN v_login_event_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION log_login_attempt IS 'Loguje pokusaj prijave u sustav';


CREATE OR REPLACE PROCEDURE cleanup_old_audit_logs(
    p_days_to_keep INTEGER DEFAULT 365
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM audit_log 
    WHERE changed_at < CURRENT_TIMESTAMP - (p_days_to_keep || ' days')::INTERVAL;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RAISE NOTICE 'Obrisano % audit zapisa starijih od % dana', v_deleted_count, p_days_to_keep;
END;
$$;

COMMENT ON PROCEDURE cleanup_old_audit_logs IS 'Brise audit zapise starije od zadanog broja dana';




CREATE OR REPLACE PROCEDURE cleanup_old_login_events(
    p_days_to_keep INTEGER DEFAULT 90
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM login_events 
    WHERE login_time < CURRENT_TIMESTAMP - (p_days_to_keep || ' days')::INTERVAL;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RAISE NOTICE 'Obrisano % login eventa starijih od % dana', v_deleted_count, p_days_to_keep;
END;
$$;

COMMENT ON PROCEDURE cleanup_old_login_events IS 'Brise login evente starije od zadanog broja dana';

