
# FAZA 1 – Definicija domene i zahtjeva

## 1.1 Svrha sustava i problem koji rješava

Moderne organizacije često trebaju interni web sustav koji omogućuje upravljanje zaposlenicima, njihovim korisničkim računima, zadacima i razinama ovlasti. U takvim sustavima nije prihvatljivo da svi korisnici imaju isti stupanj pristupa, već je potrebno jasno definirati tko smije izvršavati koje radnje.

Svrha ovog sustava je omogućiti **kontrolirani pristup internom portalu organizacije**, pri čemu se prava pristupa dodjeljuju na temelju korisničkih uloga. Time se postiže veća sigurnost, preglednost i jednostavnije upravljanje korisnicima.

---

## 1.2 Glavni akteri i uloge

### Akteri sustava
- **Administrator (Admin)** – odgovoran za održavanje sustava, upravljanje korisnicima, ulogama i pravima pristupa. Ima potpuni uvid u sve podatke sustava.
- **Manager (Voditelj tima)** – upravlja zaposlenicima i zadacima unutar svog tima. Ima uvid u članove svog tima i njihove zadatke.
- **Employee (Zaposlenik)** – izvršava zadatke i ima pristup isključivo vlastitim podacima.

### Definirane uloge
- `ADMIN` – puni pristup sustavu
- `MANAGER` – upravljanje timom i zadacima
- `EMPLOYEE` – osnovni pristup vlastitim podacima

Ovaj skup uloga predstavlja realističan i često korišten model u poslovnim informacijskim sustavima.

---

## 1.3 Funkcionalni zahtjevi

### Autentikacija i korisnički računi
1. Sustav mora omogućiti prijavu korisnika putem korisničkog imena i lozinke.
2. Sustav mora omogućiti odjavu korisnika.
3. Sustav mora omogućiti promjenu lozinke korisnika.
4. Deaktivirani korisnici ne smiju imati pristup sustavu.
5. Sustav mora evidentirati sve pokušaje prijave (uspješne i neuspješne).

### Upravljanje korisnicima
6. Administrator može kreirati nove korisničke račune.
7. Administrator može uređivati sve korisničke račune.
8. Administrator može deaktivirati korisničke račune.
9. Administrator može pregledati sve korisnike u sustavu.
10. Manager može pregledati korisnike unutar svog tima.
11. Employee može pregledati vlastite osnovne podatke.
12. Employee može uređivati vlastite osnovne podatke (osim uloge i statusa).

### Upravljanje ulogama i pravima (RBAC)
13. Administrator može kreirati nove uloge.
14. Administrator može uređivati postojeće uloge.
15. Administrator može brisati uloge koje nisu dodijeljene korisnicima.
16. Administrator može dodjeljivati uloge korisnicima.
17. Administrator može uklanjati uloge korisnicima.
18. Administrator može definirati prava pristupa za svaku ulogu.
19. Sustav mora na temelju prava pristupa ograničiti izvršavanje radnji.
20. Sustav mora na temelju prava pristupa prilagoditi prikaz funkcionalnosti.

### Upravljanje zadacima
21. Manager može kreirati nove zadatke.
22. Manager može dodijeliti zadatak zaposleniku iz svog tima.
23. Manager može uređivati zadatke koje je kreirao.
24. Manager može pregledati sve zadatke unutar svog tima.
25. Manager može brisati zadatke koje je kreirao.
26. Employee može pregledati vlastite zadatke.
27. Employee može ažurirati status vlastitih zadataka.
28. Administrator može pregledati sve zadatke u sustavu.
29. Administrator može uređivati sve zadatke u sustavu.
30. Administrator može brisati sve zadatke u sustavu.

### Meta-podaci i audit
31. Sustav mora bilježiti sve prijave korisnika (vrijeme, IP adresa, uspješnost).
32. Sustav mora bilježiti sve promjene nad korisnicima.
33. Sustav mora bilježiti sve promjene nad ulogama.
34. Sustav mora bilježiti sve promjene nad zadacima.
35. Administrator može pregledati sve audit zapise.
36. Korisnik može pregledati vlastite prijave u sustav.

---

## 1.4 Ne-funkcionalni zahtjevi

### Sigurnost
- Lozinke se pohranjuju isključivo u hashiranom obliku (bcrypt ili Argon2).
- Autorizacija se provodi na razini backenda prije svake operacije.
- Svi API zahtjevi moraju biti autenticirani (JWT tokeni).
- Osjetljivi podaci moraju biti zaštićeni od neovlaštenog pristupa.

### Pouzdanost
- Integritet podataka osigurava se ograničenjima baze podataka.
- Sve kritične operacije izvršavaju se unutar transakcija.
- Sustav mora biti dostupan 99% vremena.

### Održivost
- Sustav je modularan i lako proširiv.
- Kod je dokumentiran i prati najbolje prakse.
- Odvajanje poslovne logike od prezentacijskog sloja.

### Auditabilnost
- Sve važne promjene se evidentiraju s vremenskom oznakom.
- Audit zapisi uključuju podatke o korisniku koji je izvršio promjenu.
- Audit zapisi su nepromjenjivi (samo unos, bez izmjena ili brisanja).

### Performanse
- Vrijeme odgovora API-ja ne smije prelaziti 500ms za standardne operacije.
- Sustav mora podržavati najmanje 100 istovremenih korisnika.

---

## 1.5 Objekti domene (entiteti)

Potpuni skup entiteta potreban za implementaciju sustava:

| Entitet | Opis |
|---------|------|
| **User** | Korisnik sustava (zaposlenik) |
| **Role** | Uloga u sustavu (Admin, Manager, Employee) |
| **Permission** | Pojedinačno pravo pristupa |
| **UserRole** | Veza korisnika i uloge (M:N) |
| **RolePermission** | Veza uloge i prava (M:N) |
| **Task** | Zadatak dodijeljen korisniku |
| **LoginEvent** | Evidencija prijava u sustav |
| **AuditLog** | Evidencija promjena nad podacima |

---

## 1.6 Popis prava pristupa (Permissions)

### Upravljanje korisnicima
| Kod | Opis |
|-----|------|
| `USER_CREATE` | Kreiranje novih korisnika |
| `USER_READ_ALL` | Pregled svih korisnika |
| `USER_READ_TEAM` | Pregled korisnika u vlastitom timu |
| `USER_READ_SELF` | Pregled vlastitih podataka |
| `USER_UPDATE_ALL` | Uređivanje svih korisnika |
| `USER_UPDATE_SELF` | Uređivanje vlastitih podataka |
| `USER_DEACTIVATE` | Deaktivacija korisnika |

### Upravljanje ulogama i pravima
| Kod | Opis |
|-----|------|
| `ROLE_CREATE` | Kreiranje novih uloga |
| `ROLE_READ` | Pregled uloga |
| `ROLE_UPDATE` | Uređivanje uloga |
| `ROLE_DELETE` | Brisanje uloga |
| `ROLE_ASSIGN` | Dodjela uloga korisnicima |
| `PERMISSION_MANAGE` | Upravljanje pravima pristupa |

### Upravljanje zadacima
| Kod | Opis |
|-----|------|
| `TASK_CREATE` | Kreiranje novih zadataka |
| `TASK_ASSIGN` | Dodjela zadataka korisnicima |
| `TASK_READ_ALL` | Pregled svih zadataka |
| `TASK_READ_TEAM` | Pregled zadataka u vlastitom timu |
| `TASK_READ_SELF` | Pregled vlastitih zadataka |
| `TASK_UPDATE_ANY` | Uređivanje bilo kojeg zadatka |
| `TASK_UPDATE_SELF_STATUS` | Ažuriranje statusa vlastitih zadataka |
| `TASK_DELETE` | Brisanje zadataka |

### Audit i meta-podaci
| Kod | Opis |
|-----|------|
| `AUDIT_READ_ALL` | Pregled svih audit zapisa |
| `LOGIN_EVENTS_READ_ALL` | Pregled svih prijava |
| `LOGIN_EVENTS_READ_SELF` | Pregled vlastitih prijava |

---

## 1.7 RBAC matrica (Role × Permission)

| Permission | ADMIN | MANAGER | EMPLOYEE |
|------------|:-----:|:-------:|:--------:|
| **Upravljanje korisnicima** ||||
| USER_CREATE | ✅ | ❌ | ❌ |
| USER_READ_ALL | ✅ | ❌ | ❌ |
| USER_READ_TEAM | ✅ | ✅ | ❌ |
| USER_READ_SELF | ✅ | ✅ | ✅ |
| USER_UPDATE_ALL | ✅ | ❌ | ❌ |
| USER_UPDATE_SELF | ✅ | ✅ | ✅ |
| USER_DEACTIVATE | ✅ | ❌ | ❌ |
| **Upravljanje ulogama** ||||
| ROLE_CREATE | ✅ | ❌ | ❌ |
| ROLE_READ | ✅ | ✅ | ❌ |
| ROLE_UPDATE | ✅ | ❌ | ❌ |
| ROLE_DELETE | ✅ | ❌ | ❌ |
| ROLE_ASSIGN | ✅ | ❌ | ❌ |
| PERMISSION_MANAGE | ✅ | ❌ | ❌ |
| **Upravljanje zadacima** ||||
| TASK_CREATE | ✅ | ✅ | ❌ |
| TASK_ASSIGN | ✅ | ✅ | ❌ |
| TASK_READ_ALL | ✅ | ❌ | ❌ |
| TASK_READ_TEAM | ✅ | ✅ | ❌ |
| TASK_READ_SELF | ✅ | ✅ | ✅ |
| TASK_UPDATE_ANY | ✅ | ✅ | ❌ |
| TASK_UPDATE_SELF_STATUS | ✅ | ✅ | ✅ |
| TASK_DELETE | ✅ | ✅ | ❌ |
| **Audit i meta-podaci** ||||
| AUDIT_READ_ALL | ✅ | ❌ | ❌ |
| LOGIN_EVENTS_READ_ALL | ✅ | ❌ | ❌ |
| LOGIN_EVENTS_READ_SELF | ✅ | ✅ | ✅ |

---

## 1.8 Poslovna pravila

1. **Hijerarhija timova:** Svaki zaposlenik može imati nadređenog managera (manager_id).
2. **Pristup podacima:** Zaposlenik može pristupiti i uređivati samo vlastite podatke i status vlastitih zadataka.
3. **Upravljanje timom:** Manager može upravljati samo zaposlenicima koji su mu izravno podređeni.
4. **Dodjela zadataka:** Manager može dodijeliti zadatak samo zaposlenicima iz svog tima.
5. **Administratorske ovlasti:** Administrator ima puni pristup svim dijelovima sustava.
6. **Audit evidencija:** Sve promjene uloga i prava pristupa bilježe se u audit log.
7. **Prijave:** Svaka prijava korisnika (uspješna ili neuspješna) evidentira se u sustavu.
8. **Deaktivacija:** Deaktivirani korisnici ne mogu se prijaviti u sustav.
9. **Integritet uloga:** Uloga se ne može obrisati ako je dodijeljena nekom korisniku.
10. **Status zadatka:** Samo dodijeljeni korisnik ili administrator može promijeniti status zadatka.

---

## 1.9 Prikaz funkcionalnosti po ulozi

### Administrator
- Upravljanje korisnicima (kreiranje, uređivanje, deaktivacija)
- Upravljanje ulogama i pravima
- Dodjela uloga korisnicima
- Pregled svih zadataka
- Pregled svih audit zapisa
- Pregled svih prijava u sustav
- Potpuni pristup svim funkcionalnostima

### Manager
- Pregled zaposlenika u vlastitom timu
- Kreiranje i dodjela zadataka članovima tima
- Uređivanje i brisanje vlastitih zadataka
- Pregled zadataka tima
- Ažuriranje statusa vlastitih zadataka
- Pregled i uređivanje vlastitog profila
- Pregled vlastitih prijava u sustav

### Employee
- Pregled vlastitih zadataka
- Ažuriranje statusa vlastitih zadataka
- Pregled i uređivanje vlastitog profila
- Pregled vlastitih prijava u sustav

---

## 1.10 Dijagram slučajeva korištenja (Use Case)

```
┌─────────────────────────────────────────────────────────────────┐
│                    SUSTAV ZA UPRAVLJANJE                        │
│                ZAPOSLENICIMA I ZADACIMA                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐                                                   │
│  │  ADMIN   │──── Upravljanje korisnicima                       │
│  │          │──── Upravljanje ulogama                           │
│  │          │──── Upravljanje pravima                           │
│  │          │──── Pregled svih zadataka                         │
│  │          │──── Pregled audit zapisa                          │
│  └──────────┘                                                   │
│                                                                 │
│  ┌──────────┐                                                   │
│  │ MANAGER  │──── Kreiranje zadataka                            │
│  │          │──── Dodjela zadataka                              │
│  │          │──── Pregled tima                                  │
│  │          │──── Uređivanje profila                            │
│  └──────────┘                                                   │
│                                                                 │
│  ┌──────────┐                                                   │
│  │ EMPLOYEE │──── Pregled zadataka                              │
│  │          │──── Ažuriranje statusa                            │
│  │          │──── Uređivanje profila                            │
│  └──────────┘                                                   │
│                                                                 │
│  ┌──────────────────────────────────────────────┐               │
│  │              ZAJEDNIČKI                       │               │
│  │  ○ Prijava u sustav                          │               │
│  │  ○ Odjava iz sustava                         │               │
│  │  ○ Promjena lozinke                          │               │
│  │  ○ Pregled vlastitih prijava                 │               │
│  └──────────────────────────────────────────────┘               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

# FAZA 2 – Teorijski uvod

## 2.1 Poopćene baze podataka

### Definicija
Poopćavanje (generalizacija) u modeliranju podataka omogućuje definiranje općenitih pojmova i njihovih specijalizacija. Opći entitet sadrži zajedničke atribute, dok specijalizirani entiteti nasljeđuju te atribute i dodaju vlastite specifične karakteristike.

### Primjena u projektu
U kontekstu ovog projekta, svi korisnici sustava dijele zajedničke atribute (ime, prezime, email, lozinka), ali se razlikuju po:
- ovlastima (definiranim kroz uloge),
- načinu korištenja sustava,
- pristupnim pravima.

Model koristi **RBAC pristup** umjesto nasljeđivanja entiteta, čime se postiže fleksibilnija dodjela ovlasti bez potrebe za promjenom strukture baze.

---

## 2.2 Objektno-relacijski model i PostgreSQL

### Objektno-relacijski pristup
Objektno-relacijski pristup bazama podataka kombinira:
- **relacijski model** – tablice, primarni i strani ključevi, normalizacija,
- **objektno-orijentirane koncepte** – tipovi, kompozicija, kompleksni atributi.

### PostgreSQL mogućnosti
PostgreSQL je napredni objektno-relacijski sustav za upravljanje bazama podataka koji nudi:

| Mogućnost | Opis | Primjena u projektu |
|-----------|------|---------------------|
| **ENUM tipovi** | Korisnički definirani tipovi s fiksnim skupom vrijednosti | Status zadatka (NEW, IN_PROGRESS, DONE) |
| **COMPOSITE tipovi** | Složeni tipovi koji grupiraju više vrijednosti | Meta-podaci (created_at, updated_at, created_by) |
| **JSON/JSONB** | Pohrana fleksibilnih struktura | Stare/nove vrijednosti u audit logu |
| **Nasljeđivanje tablica** | Tablice mogu nasljeđivati strukturu drugih tablica | Opcijski za specijalizaciju korisnika |
| **Okidači (Triggers)** | Automatsko izvršavanje koda pri promjenama | Audit log, bilježenje prijava |
| **Pohranjene funkcije** | Poslovna logika na razini baze | Provjera prava, validacija |
| **Materijalizirani pogledi** | Optimizacija upita | Izvještaji i statistike |

---

## 2.3 RBAC – kontrola pristupa temeljena na ulogama

### Definicija
Role-Based Access Control (RBAC) je model kontrole pristupa koji:
- dodjeljuje **prava pristupa ulogama** (ne pojedinačnim korisnicima),
- korisnici dobivaju ovlasti **kroz dodijeljene uloge**,
- omogućuje centralizirano i skalabilno upravljanje ovlastima.

### Komponente RBAC modela

```
┌──────────┐      ┌──────────┐      ┌─────────────┐
│   USER   │ M:N  │   ROLE   │ M:N  │ PERMISSION  │
│          │◄────►│          │◄────►│             │
└──────────┘      └──────────┘      └─────────────┘
     │                 │                   │
     ▼                 ▼                   ▼
 Korisnik         Uloga (npr.        Pravo (npr.
 sustava          ADMIN, MANAGER)    USER_CREATE)
```

### Prednosti RBAC-a
1. **Skalabilnost** – lako dodavanje novih korisnika i uloga
2. **Održivost** – promjena prava na jednom mjestu (uloga)
3. **Sigurnost** – princip minimalnih ovlasti
4. **Auditabilnost** – jasno praćenje tko ima kakve ovlasti
5. **Fleksibilnost** – korisnik može imati više uloga

### RBAC u ovom projektu
- Definirane su tri osnovne uloge: ADMIN, MANAGER, EMPLOYEE
- Svaka uloga ima jasno definirani skup prava
- Korisnik može imati jednu ili više uloga
- Provjera ovlasti vrši se na razini API-ja

---

## 2.4 Aktivne baze i audit

### Aktivne baze podataka
Aktivne baze koriste mehanizme automatskog reagiranja na promjene podataka:
- **okidači (triggers)** – izvršavaju se prije/poslije INSERT, UPDATE, DELETE
- **pravila (rules)** – transformacija upita

### Primjena u projektu

#### Bilježenje prijava
```
Trigger: AFTER INSERT ON login_attempt
Action: INSERT INTO login_event
```

#### Audit log
```
Trigger: AFTER INSERT/UPDATE/DELETE ON users, roles, tasks
Action: INSERT INTO audit_log (entity, action, old_value, new_value)
```

### Prednosti aktivnih baza
- Automatizacija ponavljajućih zadataka
- Konzistentnost podataka
- Centralizirana poslovna logika
- Nemoguće zaobići (za razliku od aplikacijske logike)

---

## 2.5 Normalizacija i integritet podataka

### Normalizacija
Baza podataka u ovom projektu zadovoljava **3. normalnu formu (3NF)**:
- Svaka tablica ima primarni ključ
- Nema parcijalnih ovisnosti
- Nema tranzitivnih ovisnosti

### Integritet podataka
Osigurava se kroz:
- **Primarne ključeve** – jedinstvena identifikacija zapisa
- **Strane ključeve** – povezanost između tablica
- **CHECK ograničenja** – validacija vrijednosti
- **UNIQUE ograničenja** – sprječavanje duplikata
- **NOT NULL** – obvezni atributi

---

## 2.6 Prednosti i ograničenja odabranog pristupa

### Prednosti
| Prednost | Obrazloženje |
|----------|--------------|
| Jasna kontrola pristupa | RBAC model omogućuje preciznu definiciju ovlasti |
| Skalabilnost | Lako dodavanje novih uloga i prava |
| Audit trail | Potpuna evidencija svih promjena |
| Bogate mogućnosti PostgreSQL-a | ENUM, triggers, functions, JSON |
| Fleksibilnost | Korisnik može imati više uloga |
| Sigurnost | Logika na razini baze ne može se zaobići |

### Ograničenja
| Ograničenje | Mitigacija |
|-------------|------------|
| Složenost modela | Dokumentacija i jasna struktura |
| Ovisnost o PostgreSQL-u | Korištenje standardnih SQL konstrukcija gdje je moguće |
| Performanse okidača | Optimizacija i indeksiranje |
| Učenje krivulje | Obuka i dokumentacija |

---

# FAZA 3 – Konceptualni model baze podataka

## 3.1 Cilj faze

Cilj ove faze je izraditi **konceptualni model baze podataka** koji jasno opisuje:
- glavne entitete sustava i njihovu svrhu,
- atribute svakog entiteta s tipovima podataka,
- odnose između entiteta (kardinalnosti),
- ograničenja integriteta.

Konceptualni model služi kao temelj za kasniju **logičku i fizičku implementaciju baze podataka u PostgreSQL-u**.

---

## 3.2 Odabrani pristup modeliranju

Za modeliranje baze koristi se **Entity-Relationship (ER) dijagram** u kombinaciji s **UML klasnim dijagramom**, budući da:
- prirodno podržava objektno-orijentirane i objektno-relacijske koncepte,
- omogućuje jasno prikazivanje veza i kardinalnosti,
- pogodan je za prikaz RBAC modela (korisnici – uloge – prava).

---

## 3.3 Pregled glavnih entiteta

Sustav se sastoji od sljedećih ključnih entiteta:

| Entitet | Tip | Opis |
|---------|-----|------|
| **User** | Glavni | Korisnik sustava (zaposlenik) |
| **Role** | Glavni | Uloga korisnika u sustavu |
| **Permission** | Glavni | Pojedinačno pravo pristupa |
| **UserRole** | Povezni | Veza između korisnika i uloga (M:N) |
| **RolePermission** | Povezni | Veza između uloga i prava (M:N) |
| **Task** | Glavni | Zadatak dodijeljen zaposleniku |
| **LoginEvent** | Audit | Evidencija prijava korisnika |
| **AuditLog** | Audit | Zapis promjena nad osjetljivim podacima |

---

## 3.4 Opis entiteta i atributa (Data Dictionary)

### 3.4.1 User

Predstavlja zaposlenika koji koristi sustav.

| Atribut | Tip | Ograničenja | Opis |
|---------|-----|-------------|------|
| `user_id` | SERIAL | PK | Jedinstveni identifikator korisnika |
| `username` | VARCHAR(50) | UNIQUE, NOT NULL | Korisničko ime za prijavu |
| `email` | VARCHAR(100) | UNIQUE, NOT NULL | E-mail adresa |
| `password_hash` | VARCHAR(255) | NOT NULL | Hash lozinke (bcrypt) |
| `first_name` | VARCHAR(50) | NOT NULL | Ime korisnika |
| `last_name` | VARCHAR(50) | NOT NULL | Prezime korisnika |
| `manager_id` | INTEGER | FK → User, NULL | Nadređeni manager (za hijerarhiju tima) |
| `is_active` | BOOLEAN | NOT NULL, DEFAULT TRUE | Status računa |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Datum kreiranja |
| `updated_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Datum zadnje izmjene |

**Napomene:**
- `manager_id` omogućuje hijerarhijsku strukturu timova
- Samo korisnici s ulogom MANAGER mogu biti referencirani kao manager
- Administrator nema nadređenog managera

---

### 3.4.2 Role

Predstavlja ulogu u sustavu (npr. Admin, Manager, Employee).

| Atribut | Tip | Ograničenja | Opis |
|---------|-----|-------------|------|
| `role_id` | SERIAL | PK | Jedinstveni identifikator uloge |
| `name` | VARCHAR(50) | UNIQUE, NOT NULL | Naziv uloge (ADMIN, MANAGER, EMPLOYEE) |
| `description` | TEXT | NULL | Opis uloge i njenih ovlasti |
| `is_system` | BOOLEAN | NOT NULL, DEFAULT FALSE | Označava sistemske uloge koje se ne mogu brisati |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Datum kreiranja |
| `updated_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Datum zadnje izmjene |

**Napomene:**
- Sistemske uloge (ADMIN, MANAGER, EMPLOYEE) imaju `is_system = TRUE`
- Sistemske uloge ne mogu se brisati

---

### 3.4.3 Permission

Predstavlja pojedinačno pravo pristupa određenoj funkcionalnosti.

| Atribut | Tip | Ograničenja | Opis |
|---------|-----|-------------|------|
| `permission_id` | SERIAL | PK | Jedinstveni identifikator prava |
| `code` | VARCHAR(50) | UNIQUE, NOT NULL | Jedinstveni kod prava (npr. `TASK_CREATE`) |
| `name` | VARCHAR(100) | NOT NULL | Čitljiv naziv prava |
| `description` | TEXT | NULL | Detaljan opis prava |
| `category` | VARCHAR(50) | NOT NULL | Kategorija prava (USER, ROLE, TASK, AUDIT) |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Datum kreiranja |

**Napomene:**
- `code` se koristi u aplikaciji za provjeru ovlasti
- `category` služi za grupiranje prava u sučelju

---

### 3.4.4 UserRole

Povezni entitet koji omogućuje dodjelu jedne ili više uloga korisniku.

| Atribut | Tip | Ograničenja | Opis |
|---------|-----|-------------|------|
| `user_role_id` | SERIAL | PK | Jedinstveni identifikator |
| `user_id` | INTEGER | FK → User, NOT NULL | Referenca na korisnika |
| `role_id` | INTEGER | FK → Role, NOT NULL | Referenca na ulogu |
| `assigned_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Datum dodjele uloge |
| `assigned_by` | INTEGER | FK → User, NOT NULL | Korisnik koji je dodijelio ulogu |

**Ograničenja:**
- UNIQUE (user_id, role_id) – korisnik može imati svaku ulogu samo jednom
- ON DELETE CASCADE za user_id
- ON DELETE RESTRICT za role_id (ne može se obrisati uloga koja je dodijeljena)

---

### 3.4.5 RolePermission

Povezni entitet koji omogućuje dodjelu prava ulogama.

| Atribut | Tip | Ograničenja | Opis |
|---------|-----|-------------|------|
| `role_permission_id` | SERIAL | PK | Jedinstveni identifikator |
| `role_id` | INTEGER | FK → Role, NOT NULL | Referenca na ulogu |
| `permission_id` | INTEGER | FK → Permission, NOT NULL | Referenca na pravo |
| `assigned_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Datum dodjele prava |

**Ograničenja:**
- UNIQUE (role_id, permission_id) – uloga može imati svako pravo samo jednom
- ON DELETE CASCADE za role_id i permission_id

---

### 3.4.6 Task

Predstavlja zadatak unutar sustava.

| Atribut | Tip | Ograničenja | Opis |
|---------|-----|-------------|------|
| `task_id` | SERIAL | PK | Jedinstveni identifikator zadatka |
| `title` | VARCHAR(200) | NOT NULL | Naziv zadatka |
| `description` | TEXT | NULL | Detaljan opis zadatka |
| `status` | task_status | NOT NULL, DEFAULT 'NEW' | Status zadatka (ENUM) |
| `priority` | task_priority | NOT NULL, DEFAULT 'MEDIUM' | Prioritet zadatka (ENUM) |
| `due_date` | DATE | NULL | Rok završetka |
| `created_by` | INTEGER | FK → User, NOT NULL | Korisnik koji je kreirao zadatak |
| `assigned_to` | INTEGER | FK → User, NULL | Korisnik kojem je zadatak dodijeljen |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Datum kreiranja |
| `updated_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Datum zadnje izmjene |
| `completed_at` | TIMESTAMP | NULL | Datum završetka |

**ENUM tipovi:**
```sql
CREATE TYPE task_status AS ENUM ('NEW', 'IN_PROGRESS', 'ON_HOLD', 'COMPLETED', 'CANCELLED');
CREATE TYPE task_priority AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'URGENT');
```

**Napomene:**
- `completed_at` se automatski popunjava kada status postane COMPLETED
- `assigned_to` može biti NULL (neraspoređeni zadatak)

---

### 3.4.7 LoginEvent

Evidencija prijava korisnika u sustav.

| Atribut | Tip | Ograničenja | Opis |
|---------|-----|-------------|------|
| `login_event_id` | SERIAL | PK | Jedinstveni identifikator |
| `user_id` | INTEGER | FK → User, NULL | Referenca na korisnika (NULL ako nepoznat) |
| `username_attempted` | VARCHAR(50) | NOT NULL | Korisničko ime korišteno pri prijavi |
| `login_time` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Vrijeme pokušaja prijave |
| `ip_address` | INET | NOT NULL | IP adresa |
| `user_agent` | TEXT | NULL | Informacije o pregledniku/klijentu |
| `success` | BOOLEAN | NOT NULL | Uspješna / neuspješna prijava |
| `failure_reason` | VARCHAR(100) | NULL | Razlog neuspjeha (ako nije uspješna) |

**Napomene:**
- `user_id` je NULL ako korisničko ime ne postoji u sustavu
- `failure_reason` može biti: 'INVALID_CREDENTIALS', 'ACCOUNT_INACTIVE', 'ACCOUNT_LOCKED'

---

### 3.4.8 AuditLog

Predstavlja zapis promjena nad osjetljivim entitetima.

| Atribut | Tip | Ograničenja | Opis |
|---------|-----|-------------|------|
| `audit_log_id` | SERIAL | PK | Jedinstveni identifikator |
| `entity_name` | VARCHAR(50) | NOT NULL | Naziv entiteta (User, Role, Task) |
| `entity_id` | INTEGER | NOT NULL | ID zapisa koji je promijenjen |
| `action` | audit_action | NOT NULL | Vrsta akcije (ENUM) |
| `changed_by` | INTEGER | FK → User, NULL | Korisnik koji je izvršio promjenu |
| `changed_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Vrijeme promjene |
| `old_value` | JSONB | NULL | Prethodno stanje (za UPDATE i DELETE) |
| `new_value` | JSONB | NULL | Novo stanje (za INSERT i UPDATE) |
| `ip_address` | INET | NULL | IP adresa korisnika |

**ENUM tip:**
```sql
CREATE TYPE audit_action AS ENUM ('INSERT', 'UPDATE', 'DELETE');
```

**Napomene:**
- `changed_by` može biti NULL za sistemske promjene
- `old_value` i `new_value` koriste JSONB za fleksibilnost

---

## 3.5 Odnosi između entiteta (ER dijagram)

### 3.5.1 Tekstualni prikaz odnosa

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                                ER DIJAGRAM                                        │
├──────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│                         ┌───────────────────────────┐                            │
│                         │      Permission           │                            │
│                         │───────────────────────────│                            │
│                         │ permission_id  SER  PK    │                            │
│                         │ code           VC(50)     │                            │
│                         │ name           VC(100)    │                            │
│                         │ description    TXT        │                            │
│                         │ category       VC(50)     │                            │
│                         │ created_at     TS         │                            │
│                         └──────────┬────────────────┘                            │
│                                    │                                             │
│                                    │ M                                           │
│                                    │                                             │
│                         ┌──────────┴────────────────┐                            │
│                         │    RolePermission         │                            │
│                         │───────────────────────────│                            │
│                         │ role_permission_id SER PK │                            │
│                         │ role_id         INT  FK   │                            │
│                         │ permission_id   INT  FK   │                            │
│                         │ assigned_at     TS        │                            │
│                         └──────────┬────────────────┘                            │
│                                    │                                             │
│                                    │ M                                           │
│                                    │                                             │
│ ┌───────────────────────┐  ┌───────┴────────────┐  ┌──────────────────────────┐  │
│ │    LoginEvent         │  │       Role         │  │       AuditLog           │  │
│ │───────────────────────│  │────────────────────│  │──────────────────────────│  │
│ │ login_event_id SER PK │  │ role_id     SER PK │  │ audit_log_id    SER  PK  │  │
│ │ user_id        INT FK │  │ name        VC(50) │  │ entity_name     VC(50)   │  │
│ │ username_atmp  VC(50) │  │ description TXT    │  │ entity_id       INT      │  │
│ │ login_time     TS     │  │ is_system   BOOL   │  │ action          ENUM     │  │
│ │ ip_address     INET   │  │ created_at  TS     │  │ changed_by      INT  FK  │  │
│ │ user_agent     TXT    │  │ updated_at  TS     │  │ changed_at      TS       │  │
│ │ success        BOOL   │  └─────────┬──────────┘  │ old_value       JSON     │  │
│ │ failure_reason VC(100)│            │             │ new_value       JSON     │  │
│ └───────┬───────────────┘            │ M           │ ip_address      INET     │  │
│         │                            │             └──────────┬───────────────┘  │
│         │ M                  ┌───────┴───────┐              │                   │
│         │                    │   UserRole    │              │ M                 │
│         │                    │───────────────│              │                   │
│         │                    │ user_role_id  │              │                   │
│         │                    │         SER PK│              │                   │
│         │                    │ user_id INT FK│              │                   │
│         │                    │ role_id INT FK│              │                   │
│         │                    │ assigned_at TS│              │                   │
│         │                    │ assigned_by   │              │                   │
│         │                    │         INT FK│              │                   │
│         │                    └───────┬───────┘              │                   │
│         │                            │ M                    │                   │
│         │                            │                      │                   │
│         │                    ┌───────┴────────────┐         │                   │
│         └───────────────────►│       User         │◄────────┘                   │
│                              │────────────────────│                             │
│                              │ user_id       SER  │◄─────┐                      │
│                              │            PK      │      │                      │
│                              │ username    VC(50) │      │                      │
│                              │ email       VC(100)│      │ manager_id           │
│                              │ password_hash      │      │ (self-reference)     │
│                              │            VC(255) │      │                      │
│                              │ first_name  VC(50) │      │                      │
│                              │ last_name   VC(50) │      │                      │
│                              │ manager_id  INT FK │──────┘                      │
│                              │ is_active   BOOL   │                             │
│                              │ created_at  TS     │                             │
│                              │ updated_at  TS     │                             │
│                              └──────────┬─────────┘                             │
│                                         │                                       │
│                                         │ 1                                     │
│                                         │                                       │
│                              ┌──────────┴─────────────┐                         │
│                              │        Task            │                         │
│                              │────────────────────────│                         │
│                              │ task_id       SER  PK  │                         │
│                              │ title         VC(200)  │                         │
│                              │ description   TXT      │                         │
│                              │ status        ENUM     │                         │
│                              │ priority      ENUM     │                         │
│                              │ due_date      DT       │                         │
│                              │ created_by    INT  FK  │                         │
│                              │ assigned_to   INT  FK  │                         │
│                              │ created_at    TS       │                         │
│                              │ updated_at    TS       │                         │
│                              │ completed_at  TS       │                         │
│                              └────────────────────────┘                         │
│                                                                                  │
│  Legenda tipova:                                                                │
│  SER = SERIAL | INT = INTEGER | VC = VARCHAR | TXT = TEXT | BOOL = BOOLEAN     │
│  TS = TIMESTAMP | DT = DATE | INET = IP adresa | JSON = JSONB | ENUM = tip      │
│                                                                                  │
└──────────────────────────────────────────────────────────────────────────────────┘
```

### 3.5.2 Tablica kardinalnosti

| Odnos | Tip | Opis |
|-------|-----|------|
| User ↔ Role | M:N | Korisnik može imati više uloga; uloga može pripadati više korisnika (preko UserRole) |
| Role ↔ Permission | M:N | Uloga može imati više prava; pravo može pripadati više uloga (preko RolePermission) |
| User ↔ Task (created_by) | 1:N | Jedan korisnik može kreirati više zadataka |
| User ↔ Task (assigned_to) | 1:N | Jednom korisniku može biti dodijeljeno više zadataka |
| User ↔ User (manager_id) | 1:N | Jedan manager može imati više podređenih zaposlenika |
| User ↔ LoginEvent | 1:N | Jedan korisnik ima više prijava |
| User ↔ AuditLog | 1:N | Jedan korisnik može uzrokovati više audit zapisa |

---

## 3.6 Ograničenja integriteta

### Primarni ključevi
- Svaki entitet ima jedinstveni primarni ključ (`*_id`)

### Strani ključevi
| Tablica | Strani ključ | Referencira | ON DELETE |
|---------|--------------|-------------|-----------|
| User | manager_id | User(user_id) | SET NULL |
| UserRole | user_id | User(user_id) | CASCADE |
| UserRole | role_id | Role(role_id) | RESTRICT |
| UserRole | assigned_by | User(user_id) | SET NULL |
| RolePermission | role_id | Role(role_id) | CASCADE |
| RolePermission | permission_id | Permission(permission_id) | CASCADE |
| Task | created_by | User(user_id) | RESTRICT |
| Task | assigned_to | User(user_id) | SET NULL |
| LoginEvent | user_id | User(user_id) | SET NULL |
| AuditLog | changed_by | User(user_id) | SET NULL |

### UNIQUE ograničenja
- User: username, email
- Role: name
- Permission: code
- UserRole: (user_id, role_id)
- RolePermission: (role_id, permission_id)

### CHECK ograničenja
- User.email mora sadržavati '@'
- Task.due_date mora biti >= created_at (ako je postavljen)

---

## 3.7 Indeksi (preporuke za optimizaciju)

| Tablica | Indeks | Svrha |
|---------|--------|-------|
| User | idx_user_username | Brza prijava |
| User | idx_user_email | Pretraživanje po emailu |
| User | idx_user_manager | Dohvat članova tima |
| User | idx_user_active | Filtriranje aktivnih korisnika |
| Task | idx_task_status | Filtriranje po statusu |
| Task | idx_task_assigned | Zadaci dodijeljeni korisniku |
| Task | idx_task_created_by | Zadaci koje je korisnik kreirao |
| LoginEvent | idx_login_user | Povijest prijava korisnika |
| LoginEvent | idx_login_time | Sortiranje po vremenu |
| AuditLog | idx_audit_entity | Pretraga po entitetu |
| AuditLog | idx_audit_time | Sortiranje po vremenu |

---

## 3.8 Dijagram - smjernice za izradu

### Preporučeni alati
- **draw.io** (diagrams.net) – besplatan, online
- **Lucidchart** – profesionalni alat
- **DbDiagram.io** – specifičan za baze podataka
- **PlantUML** – tekstualni opis dijagrama

### Elementi za uključiti
1. Sve entitete kao pravokutnike s atributima
2. Primarne ključeve označene (PK)
3. Strane ključeve označene (FK)
4. Linije odnosa s kardinalnostima (1, M, N)
5. ENUM tipove kao zasebne elemente
6. Grupiranje po domenama (User Management, Task Management, Audit)

### Format izvoza
- PNG (za dokumentaciju)
- SVG (za skalabilnost)
- PDF (za prezentacije)

---


