-- Migracija za direktnu dodjelu permisija korisnicima
-- Omogucava administratorima da pojedinacnim korisnicima dodijele ili uklone permisije
-- neovisno o njihovim ulogama (custom dizajn pristupa)

SET search_path TO employee_management;

-- Tablica za direktnu dodjelu permisija korisnicima
CREATE TABLE IF NOT EXISTS user_permissions (
    user_permission_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    permission_id INTEGER NOT NULL,
    granted BOOLEAN NOT NULL DEFAULT TRUE,  -- TRUE = dozvoljeno, FALSE = zabranjeno (override)
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by INTEGER,
    notes TEXT,  -- Opcijski komentar zasto je permisija dodijeljena/uklonjena
    
    CONSTRAINT fk_user_permissions_user FOREIGN KEY (user_id) 
        REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_permissions_permission FOREIGN KEY (permission_id) 
        REFERENCES permissions(permission_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_permissions_assigned_by FOREIGN KEY (assigned_by) 
        REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_user_permissions UNIQUE (user_id, permission_id)
);

COMMENT ON TABLE user_permissions IS 'Direktna dodjela permisija korisnicima (override uloga)';
COMMENT ON COLUMN user_permissions.user_permission_id IS 'Jedinstveni identifikator dodjele';
COMMENT ON COLUMN user_permissions.user_id IS 'ID korisnika';
COMMENT ON COLUMN user_permissions.permission_id IS 'ID permisije';
COMMENT ON COLUMN user_permissions.granted IS 'TRUE=dozvola, FALSE=zabrana (override uloge)';
COMMENT ON COLUMN user_permissions.assigned_at IS 'Datum dodjele';
COMMENT ON COLUMN user_permissions.assigned_by IS 'ID admina koji je dodijelio';
COMMENT ON COLUMN user_permissions.notes IS 'Opcijski komentar';

-- Indeksi za brze pretrazivanje
CREATE INDEX IF NOT EXISTS idx_user_permissions_user ON user_permissions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_permissions_permission ON user_permissions(permission_id);
CREATE INDEX IF NOT EXISTS idx_user_permissions_granted ON user_permissions(granted);


-- Azuriraj funkciju get_user_permissions da ukljuci direktne permisije
CREATE OR REPLACE FUNCTION get_user_permissions(p_user_id INTEGER)
RETURNS TABLE(permission_code VARCHAR(50), permission_name VARCHAR(100), category VARCHAR(50), source VARCHAR(20))
AS $$
BEGIN
    RETURN QUERY
    -- Permisije iz uloga (ako nisu eksplicitno zabranjene)
    SELECT DISTINCT 
        p.code::VARCHAR(50),
        p.name::VARCHAR(100),
        p.category::VARCHAR(50),
        'ROLE'::VARCHAR(20) as source
    FROM user_roles ur
    JOIN role_permissions rp ON ur.role_id = rp.role_id
    JOIN permissions p ON rp.permission_id = p.permission_id
    WHERE ur.user_id = p_user_id
    AND NOT EXISTS (
        -- Provjeri da permisija nije eksplicitno zabranjena
        SELECT 1 FROM user_permissions up 
        WHERE up.user_id = p_user_id 
        AND up.permission_id = p.permission_id 
        AND up.granted = FALSE
    )
    
    UNION
    
    -- Direktno dodijeljene permisije (granted = TRUE)
    SELECT DISTINCT
        p.code::VARCHAR(50),
        p.name::VARCHAR(100),
        p.category::VARCHAR(50),
        'DIRECT'::VARCHAR(20) as source
    FROM user_permissions up
    JOIN permissions p ON up.permission_id = p.permission_id
    WHERE up.user_id = p_user_id
    AND up.granted = TRUE
    
    ORDER BY category, permission_code;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_user_permissions(INTEGER) IS 'Vraca sve permisije korisnika (iz uloga + direktno dodijeljene, minus zabranjene)';


-- Funkcija za provjeru da li korisnik ima odredjenu permisiju (azurirano za direktne permisije)
CREATE OR REPLACE FUNCTION user_has_permission(
    p_user_id INTEGER,
    p_permission_code VARCHAR(50)
)
RETURNS BOOLEAN AS $$
DECLARE
    v_permission_id INTEGER;
    v_direct_grant BOOLEAN;
    v_has_via_role BOOLEAN;
BEGIN
    -- Dohvati permission_id
    SELECT permission_id INTO v_permission_id 
    FROM permissions WHERE code = p_permission_code;
    
    IF v_permission_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Provjeri direktnu dodjelu (prioritet)
    SELECT granted INTO v_direct_grant
    FROM user_permissions
    WHERE user_id = p_user_id AND permission_id = v_permission_id;
    
    -- Ako postoji direktna dodjela, koristi tu vrijednost
    IF v_direct_grant IS NOT NULL THEN
        RETURN v_direct_grant;
    END IF;
    
    -- Inace provjeri kroz uloge
    SELECT EXISTS(
        SELECT 1
        FROM user_roles ur
        JOIN role_permissions rp ON ur.role_id = rp.role_id
        WHERE ur.user_id = p_user_id
        AND rp.permission_id = v_permission_id
    ) INTO v_has_via_role;
    
    RETURN v_has_via_role;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION user_has_permission(INTEGER, VARCHAR) IS 'Provjerava da li korisnik ima permisiju (direktna dodjela ima prioritet)';


-- Funkcija za dohvat direktnih permisija korisnika
CREATE OR REPLACE FUNCTION get_user_direct_permissions(p_user_id INTEGER)
RETURNS TABLE(
    permission_code VARCHAR(50), 
    permission_name VARCHAR(100), 
    category VARCHAR(50),
    granted BOOLEAN,
    assigned_at TIMESTAMP,
    assigned_by_name TEXT,
    notes TEXT
)
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.code::VARCHAR(50),
        p.name::VARCHAR(100),
        p.category::VARCHAR(50),
        up.granted,
        up.assigned_at,
        (SELECT first_name || ' ' || last_name FROM users WHERE user_id = up.assigned_by)::TEXT,
        up.notes
    FROM user_permissions up
    JOIN permissions p ON up.permission_id = p.permission_id
    WHERE up.user_id = p_user_id
    ORDER BY p.category, p.code;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_user_direct_permissions(INTEGER) IS 'Vraca sve direktno dodijeljene/zabranjene permisije korisnika';


-- Procedura za dodjelu direktne permisije korisniku
CREATE OR REPLACE PROCEDURE assign_user_permission(
    p_user_id INTEGER,
    p_permission_code VARCHAR(50),
    p_granted BOOLEAN,
    p_assigned_by INTEGER,
    p_notes TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_permission_id INTEGER;
BEGIN
    -- Dohvati permission_id
    SELECT permission_id INTO v_permission_id 
    FROM permissions WHERE code = p_permission_code;
    
    IF v_permission_id IS NULL THEN
        RAISE EXCEPTION 'Permisija % ne postoji', p_permission_code;
    END IF;
    
    -- Provjeri da korisnik postoji
    IF NOT EXISTS (SELECT 1 FROM users WHERE user_id = p_user_id) THEN
        RAISE EXCEPTION 'Korisnik s ID % ne postoji', p_user_id;
    END IF;
    
    -- Umetni ili azuriraj
    INSERT INTO user_permissions (user_id, permission_id, granted, assigned_by, notes)
    VALUES (p_user_id, v_permission_id, p_granted, p_assigned_by, p_notes)
    ON CONFLICT (user_id, permission_id) DO UPDATE SET
        granted = EXCLUDED.granted,
        assigned_at = CURRENT_TIMESTAMP,
        assigned_by = EXCLUDED.assigned_by,
        notes = EXCLUDED.notes;
END;
$$;

COMMENT ON PROCEDURE assign_user_permission(INTEGER, VARCHAR, BOOLEAN, INTEGER, TEXT) IS 'Dodjeljuje ili zabranjuje direktnu permisiju korisniku';


-- Procedura za uklanjanje direktne permisije (vraca na default iz uloge)
CREATE OR REPLACE PROCEDURE remove_user_permission(
    p_user_id INTEGER,
    p_permission_code VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_permission_id INTEGER;
BEGIN
    SELECT permission_id INTO v_permission_id 
    FROM permissions WHERE code = p_permission_code;
    
    IF v_permission_id IS NULL THEN
        RAISE EXCEPTION 'Permisija % ne postoji', p_permission_code;
    END IF;
    
    DELETE FROM user_permissions 
    WHERE user_id = p_user_id AND permission_id = v_permission_id;
END;
$$;

COMMENT ON PROCEDURE remove_user_permission(INTEGER, VARCHAR) IS 'Uklanja direktnu permisiju korisnika (vraca na default iz uloge)';


-- View za prikaz korisnika s njihovim efektivnim permisijama
CREATE OR REPLACE VIEW v_users_with_permissions AS
SELECT 
    u.user_id,
    u.username,
    u.first_name,
    u.last_name,
    u.email,
    u.is_active,
    ARRAY_AGG(DISTINCT r.name ORDER BY r.name) FILTER (WHERE r.name IS NOT NULL) AS roles,
    (
        SELECT ARRAY_AGG(DISTINCT permission_code ORDER BY permission_code)
        FROM get_user_permissions(u.user_id)
    ) AS effective_permissions,
    (
        SELECT ARRAY_AGG(DISTINCT permission_code ORDER BY permission_code)
        FROM get_user_direct_permissions(u.user_id)
        WHERE granted = TRUE
    ) AS direct_granted_permissions,
    (
        SELECT ARRAY_AGG(DISTINCT permission_code ORDER BY permission_code)
        FROM get_user_direct_permissions(u.user_id)
        WHERE granted = FALSE
    ) AS direct_denied_permissions
FROM users u
LEFT JOIN user_roles ur ON u.user_id = ur.user_id
LEFT JOIN roles r ON ur.role_id = r.role_id
GROUP BY u.user_id, u.username, u.first_name, u.last_name, u.email, u.is_active;

COMMENT ON VIEW v_users_with_permissions IS 'Korisnici s efektivnim permisijama (uloge + direktne dodjele)';


-- Dodaj user_permissions u audit_log constraint
ALTER TABLE audit_log DROP CONSTRAINT IF EXISTS chk_audit_log_entity;
ALTER TABLE audit_log ADD CONSTRAINT chk_audit_log_entity 
    CHECK (entity_name IN ('users', 'roles', 'tasks', 'user_roles', 'role_permissions', 'user_permissions'));


-- Trigger za audit log user_permissions
CREATE OR REPLACE FUNCTION trg_audit_user_permissions()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (entity_name, entity_id, action, changed_by, old_value, new_value)
        VALUES ('user_permissions', NEW.user_permission_id, 'INSERT', NEW.assigned_by, NULL,
            jsonb_build_object(
                'user_id', NEW.user_id,
                'permission_id', NEW.permission_id,
                'granted', NEW.granted,
                'notes', NEW.notes
            ));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (entity_name, entity_id, action, changed_by, old_value, new_value)
        VALUES ('user_permissions', NEW.user_permission_id, 'UPDATE', NEW.assigned_by,
            jsonb_build_object(
                'user_id', OLD.user_id,
                'permission_id', OLD.permission_id,
                'granted', OLD.granted,
                'notes', OLD.notes
            ),
            jsonb_build_object(
                'user_id', NEW.user_id,
                'permission_id', NEW.permission_id,
                'granted', NEW.granted,
                'notes', NEW.notes
            ));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (entity_name, entity_id, action, changed_by, old_value, new_value)
        VALUES ('user_permissions', OLD.user_permission_id, 'DELETE', NULL,
            jsonb_build_object(
                'user_id', OLD.user_id,
                'permission_id', OLD.permission_id,
                'granted', OLD.granted,
                'notes', OLD.notes
            ), NULL);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_user_permissions_audit
    AFTER INSERT OR UPDATE OR DELETE ON user_permissions
    FOR EACH ROW EXECUTE FUNCTION trg_audit_user_permissions();

COMMENT ON TRIGGER trg_user_permissions_audit ON user_permissions IS 'Audit trail za promjene direktnih korisnickih permisija';

