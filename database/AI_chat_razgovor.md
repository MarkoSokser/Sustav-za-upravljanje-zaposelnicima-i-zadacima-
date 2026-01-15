# AI Chat Razgovor - Dokumentacija korištenja AI chat-a

---

##  1. Seed Data - Generiranje testnih podataka

### Moj pristup

Prvo sam **samostalno kreirao sve ključne i bitne podatke** koji definiraju strukturu i logiku sustava:

- **Permissions (prava pristupa)** - definirao sam sve permission kodove, nazive, opise i kategorije
- **Roles (uloge)** - kreirao ADMIN, MANAGER, EMPLOYEE uloge s opisima
- **RBAC Matrix** - samostalno mapirao koje permisije pripadaju kojim ulogama
- **Inicijalne korisnike** - admin, managere i strukturu timova

### Korištenje AI za generiranje dodatnih podataka

Nakon što sam postavio osnovnu strukturu, zamolio sam AI da na temelju mojih primjera generira dodatne podatke da bih uštedio vrijeme.

**Moj upit AI-ju:**
> "Evo primjera kako sam kreirao zaposlenike za Development tim:
> ```sql
> INSERT INTO users (username, email, password_hash, first_name, last_name, manager_id, is_active) VALUES
> ('marko_dev', 'marko.novak@example.com', '$2b$12$...', 'Marko', 'Novak', 
>  (SELECT user_id FROM users WHERE username = 'ivan_manager'), TRUE);
> ```
> Možeš li mi generirati još 2-3 zaposlenika za Design tim pod anom_manager, koristeći istu strukturu i konvenciju imenovanja?"

**AI odgovor:**
> AI mi je generirao dodatne INSERT naredbe prateći moj obrazac:
> - Koristio je istu strukturu username-a (ime_odjel)
> - Nastavio s istim formatom email adresa
> - Zadržao dosljednost u password hash formatu
> - Pravilno referencirao manager_id

---

##  2. Funkcije i Procedure 

### 2.1 Provjera korisničkih permisija

**Ja:** Kako mogu implementirati funkciju koja provjerava ima li korisnik određenu permisiju, uzimajući u obzir i direktne dodjele i dodjele kroz uloge?

**AI :**
> Za RBAC sustav s prioritetima, potrebno je razumjeti redoslijed provjere:
> 
> 1. **Prvo provjeri direktnu dodjelu** - ako postoji eksplicitna dozvola/zabrana za korisnika
> 2. **Zatim provjeri kroz uloge** - ako nema direktne dodjele
> 
> Primjer koncepta:
> ```sql
> -- Pseudokod logike:
> -- 1. Pronađi permission_id za dani kod
> -- 2. Provjeri user_permissions tablicu za direktnu dodjelu
> -- 3. Ako postoji direktna, vrati tu vrijednost (granted TRUE/FALSE)
> -- 4. Ako ne postoji, provjeri kroz role_permissions JOIN user_roles
> ```
> 
> Koristi `STABLE` volatilnost jer funkcija ovisi o podacima u tablicama, ali ne mijenja stanje.

**Ja:** Što znači ta volatilnost STABLE?

**AI :**
> PostgreSQL ima tri razine volatilnosti funkcija:
> - `IMMUTABLE` - uvijek vraća isti rezultat za iste ulazne parametre (npr. matematičke funkcije)
> - `STABLE` - vraća isti rezultat unutar jedne SQL naredbe (čita iz baze, ali ne mijenja)
> - `VOLATILE` - može vratiti različite rezultate čak i s istim parametrima (default)
> 
> Za `user_has_permission` koristiš STABLE jer:
> - Čitaš podatke iz tablica (permissions, user_permissions, user_roles)
> - Ne mijenjaš podatke
> - Rezultat može biti različit ako se podaci promijene između poziva

**Moja implementacija:**
Na temelju ovog razumijevanja,  sam implementirao `user_has_permission` funkciju koja koristi IF/THEN logiku za provjeru prioriteta.

---

### 2.2 Funkcija za statistiku zadataka

**Ja:** Trebam funkciju koja vraća statistiku zadataka za korisnika - ukupan broj, završeni, u tijeku, prekoračeni rok, postotak završenosti. Kako strukturirati povratni tip?

**AI :**
> Za vraćanje više vrijednosti imaš nekoliko opcija:
> 
> 1. **RETURNS TABLE** - definiraj stupce u definiciji funkcije
> 2. **OUT parametri** - koristi INOUT/OUT parametre
> 3. **Composite type** - kreiraj vlastiti tip
> 
> Za statistiku preporučam `RETURNS TABLE` jer je najčitljiviji:
> ```sql
> RETURNS TABLE(
>     naziv_stupca TIP_PODATKA,
>     ...
> )
> ```
> 
> Za izračun postotka, pazi na dijeljenje s nulom - koristi CASE izraz.

**Ja:** Kako mogu u jednom SELECT-u izračunati više različitih COUNT-ova s različitim uvjetima?

**AI :**
> Koristi `FILTER` klauzulu - PostgreSQL proširenje koje je čitljivije od CASE:
> ```sql
> COUNT(*) FILTER (WHERE status = 'COMPLETED') AS completed_tasks
> ```
> Ovo je ekvivalent:
> ```sql
> COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END)
> ```
> FILTER sintaksa je preporučena u PostgreSQL-u jer je jasnija.

**Moja implementacija:**
Implementirao sam  `get_task_statistics` funkciju koristeći FILTER klauzulu i CASE za postotak.

---

### 2.3 Procedura za ažuriranje statusa zadatka s workflow-om

**Ja:** Imam workflow gdje zaposlenici ne mogu direktno završiti zadatak - moraju ga predati na odobrenje manageru. Kako to implementirati u proceduri?

**AI :**
> Razmisli o stanjima (state machine):
> 
> ```
> NEW → IN_PROGRESS → PENDING_APPROVAL → COMPLETED
>                   ↘ ON_HOLD ↗        ↘ (manager odbije) → IN_PROGRESS
> ```
> 
> U proceduri trebaš:
> 1. Dohvatiti trenutni status zadatka
> 2. Provjeriti je li korisnik assignee, manager ili admin
> 3. Primijeniti pravila prijelaza stanja
> 
> Koristi `EXISTS` s JOIN-om za provjeru uloga:
> ```sql
> SELECT EXISTS (
>     SELECT 1 FROM user_roles ur
>     JOIN roles r ON ur.role_id = r.role_id
>     WHERE ur.user_id = p_user_id AND r.name IN ('ADMIN', 'MANAGER')
> ) INTO v_is_manager_or_admin;
> ```

**Ja:** Kako pravilno koristiti RAISE EXCEPTION za validacijske greške?

**AI :**
> `RAISE EXCEPTION` prekida izvršavanje i vraća grešku klijentu:
> ```sql
> RAISE EXCEPTION 'Poruka greške s parametrom %', p_vrijednost;
> ```
> 
> Za informativne poruke (ne greške) koristi:
> - `RAISE NOTICE` - informativna poruka, nastavlja izvršavanje
> - `RAISE WARNING` - upozorenje, nastavlja izvršavanje
> - `RAISE EXCEPTION` - greška, prekida izvršavanje i rollback

**Moja implementacija:**
Implementirao sam `update_task_status` proceduru s kompletnom workflow logikom i validacijama.

---

### 2.4 Audit trigger za praćenje promjena

**Ja:** Kako napraviti univerzalni audit trigger koji logira INSERT, UPDATE i DELETE operacije s razlikama u starim i novim vrijednostima?

**AI :**
> Koristi `TG_OP` varijablu za određivanje tipa operacije:
> 
> ```sql
> IF TG_OP = 'INSERT' THEN
>     -- OLD ne postoji, samo NEW
> ELSIF TG_OP = 'UPDATE' THEN
>     -- OLD i NEW postoje
> ELSIF TG_OP = 'DELETE' THEN
>     -- NEW ne postoji, samo OLD
> END IF;
> ```
> 
> Za JSON reprezentaciju koristi `jsonb_build_object`:
> ```sql
> jsonb_build_object('key1', value1, 'key2', value2)
> ```
> 
> Za provjeru da li se nešto stvarno promijenilo:
> ```sql
> IF OLD.* IS DISTINCT FROM NEW.* THEN
>     -- Stvarna promjena
> END IF;
> ```

**Moja implementacija:**
Kreirao sam `audit_users_changes`, `audit_tasks_changes` i `audit_user_roles_changes` trigger funkcije.

---

##  3. Advanced Features - RULES i LIKE klauzula

### 3.1 Kreiranje arhivske tablice pomoću LIKE

**Ja:** Imam tasks tablicu i želim napraviti tasks_archive za stare završene zadatke. Kako kopirati strukturu bez ponovnog pisanja svih stupaca?

**AI :**
> PostgreSQL ima `LIKE` klauzulu za kreiranje tablica:
> 
> ```sql
> CREATE TABLE nova_tablica (
>     LIKE postojeca_tablica INCLUDING DEFAULTS INCLUDING COMMENTS
> );
> ```
> 
> Opcije za INCLUDING:
> - `INCLUDING DEFAULTS` - kopira default vrijednosti
> - `INCLUDING CONSTRAINTS` - kopira CHECK i NOT NULL
> - `INCLUDING INDEXES` - kopira indekse
> - `INCLUDING COMMENTS` - kopira komentare
> - `INCLUDING ALL` - sve gore navedeno
> 
> **Napomena:** LIKE NE kopira:
> - SERIAL/IDENTITY (moraš ručno dodati PK)
> - Foreign key constraints
> - Triggere

**Ja:** Znači moram ručno dodati dodatne stupce za arhivu?

**AI :**
> Da, možeš kombinirati LIKE s dodatnim stupcima:
> ```sql
> CREATE TABLE archive (
>     LIKE original INCLUDING DEFAULTS,
>     archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
>     archived_by INTEGER,
>     archive_reason TEXT
> );
> ```

**Moja implementacija:**
Kreirao sam `tasks_archive` tablicu s LIKE i dodatnim stupcima za praćenje arhiviranja.

---

### 3.2 PostgreSQL RULES za zaštitu podataka

**Ja:** Kako spriječiti brisanje sistemskih uloga (ADMIN, MANAGER, EMPLOYEE) bez korištenja triggera?

**AI :**
> PostgreSQL ima `RULE` sustav koji može prepisati SQL naredbe:
> 
> ```sql
> CREATE RULE ime_pravila AS
>     ON operacija TO tablica
>     WHERE uvjet
>     DO INSTEAD akcija;
> ```
> 
> Za sprječavanje operacije koristi `DO INSTEAD NOTHING`:
> ```sql
> CREATE RULE prevent_delete AS
>     ON DELETE TO tablica
>     WHERE OLD.protected = TRUE
>     DO INSTEAD NOTHING;
> ```
> 
> Razlika RULE vs TRIGGER:
> - RULE prepisuje upit PRIJE izvršavanja
> - TRIGGER se izvršava kao dio transakcije
> - RULE je efikasniji za jednostavne slučajeve
> - Trigger je fleksibilniji za kompleksnu logiku

**Moja implementacija:**
Kreirao sam `prevent_system_role_delete` rule za zaštitu sistemskih uloga.

---

### 3.3 Automatsko logiranje s RULE DO ALSO

**Ja:** Mogu li koristiti RULE da automatski logiram svaki pokušaj brisanja korisnika bez da blokiram samo brisanje?

**AI :**
> Da! Koristi `DO ALSO` umjesto `DO INSTEAD`:
> 
> ```sql
> CREATE RULE log_operacija AS
>     ON DELETE TO tablica
>     DO ALSO (
>         INSERT INTO log_tablica (...)
>         VALUES (...)
>     );
> ```
> 
> `DO ALSO` - izvršava dodatnu akciju UZ originalnu operaciju
> `DO INSTEAD` - ZAMJENJUJE originalnu operaciju
> 
> U RULE možeš koristiti OLD i NEW pseudo-varijable kao u triggerima.

**Moja implementacija:**
Kreirao sam `log_user_delete_attempt` rule koji logira brisanja U audit_log.

---

### 3.4 Automatsko arhiviranje starih zadataka

**Ja:** Kako automatski kopirati završene zadatke starije od 180 dana u arhivu prilikom bilo kakvog UPDATE-a?

**AI :**
> Kombinacija RULE s podupitom:
> 
> ```sql
> CREATE RULE auto_archive AS
>     ON UPDATE TO tasks
>     WHERE NEW.status IN ('COMPLETED', 'CANCELLED')
>     AND NEW.updated_at < CURRENT_TIMESTAMP - INTERVAL '180 days'
>     DO ALSO (
>         INSERT INTO archive SELECT ... FROM ... 
>         WHERE NOT EXISTS (SELECT 1 FROM archive WHERE ...)
>     );
> ```
> 
> `NOT EXISTS` sprječava duplikate ako se isti zadatak ažurira više puta.
> 
> Za datumsku aritmetiku:
> - `INTERVAL '180 days'` - PostgreSQL interval literal
> - `CURRENT_TIMESTAMP - INTERVAL` - oduzimanje intervala od timestamp-a

**Moja implementacija:**
Kreirao sam `auto_archive_old_completed` rule s provjerom duplikata.

---

### 3.5 Zaštita završenih zadataka od izmjena

**Ja:** Kako spriječiti izmjenu sadržaja završenih zadataka, ali dozvoliti promjenu statusa (npr. vraćanje na IN_PROGRESS)?

**AI :**
> Trebaš RULE koji provjerava što se točno mijenja:
> 
> ```sql
> CREATE RULE prevent_edit AS
>     ON UPDATE TO tasks
>     WHERE OLD.status IN ('COMPLETED', 'CANCELLED')
>     AND (
>         NEW.title != OLD.title OR
>         NEW.description IS DISTINCT FROM OLD.description OR
>         -- ostala polja...
>     )
>     DO INSTEAD NOTHING;
> ```
> 
> Koristi `IS DISTINCT FROM` za NULL-safe usporedbu:
> - `NULL != NULL` vraća NULL (ne TRUE!)
> - `NULL IS DISTINCT FROM NULL` vraća FALSE
> - Korisno za nullable stupce

**Moja implementacija:**
Kreirao sam `prevent_completed_task_edit` rule koji štiti sadržaj ali dozvoljava promjenu statusa.

