# PRIRUČNIK ZA IZRADU PROJEKTA  
## Interni sustav za upravljanje zaposlenicima i zadacima

---

## 0. Uvod

Ovaj priručnik služi kao **centralni vodič (canvas)** za izradu projektnog zadatka:

**„Web aplikacija za upravljanje korisničkim računima, ulogama i pravima pristupa u internom sustavu za upravljanje zaposlenicima i zadacima“**.

Projekt je osmišljen kako bi demonstrirao:
- primjenu **poopćenih i objektno-relacijskih baza podataka** (PostgreSQL),
- implementaciju **RBAC modela (Role-Based Access Control)**,
- razvoj **web aplikacije s grafičkim sučeljem**,
- izradu **akademski ispravne dokumentacije**.

Priručnik je strukturiran **po fazama**, pri čemu svaka faza ima jasan cilj, konkretne zadatke i očekivane ishode. Faze se mogu obrađivati **sekvencijalno**, a svaka faza predstavlja jednu cjelinu projekta.

---

## 1. Definicija domene i zahtjeva

### Cilj faze
Jasno definirati **svrhu sustava**, njegovu primjenu u stvarnom svijetu i kontekst u kojem se koriste prava pristupa.

### Opis domene
Sustav predstavlja **interni web portal organizacije** koji služi za:
- upravljanje zaposlenicima,
- upravljanje zadacima,
- kontrolu pristupa funkcionalnostima sustava prema ulozi korisnika.

Prava pristupa koriste se kako bi se osiguralo da:
- administrativni korisnici imaju puni pristup sustavu,
- voditelji timova upravljaju samo svojim zaposlenicima i zadacima,
- zaposlenici imaju pristup isključivo vlastitim podacima i zadacima.

### Glavne uloge
- **Administrator** – upravlja korisnicima, ulogama i pravima pristupa  
- **Manager** – upravlja zaposlenicima i zadacima unutar tima  
- **Employee** – pregled vlastitih zadataka i osobnih podataka  

### Ishod faze
- jasno definirana svrha prava pristupa  
- opis aplikacijske domene (materijal za dokumentaciju)  

---

## 2. Teorijski uvod

### Cilj faze
Objasniti teorijsku pozadinu korištenog pristupa bazama podataka i modela autorizacije.

### Sadržaj faze
- poopćene baze podataka  
- objektno-relacijski model  
- RBAC (Role-Based Access Control)  
- prednosti PostgreSQL-a u odnosu na klasične relacijske baze  

### Fokus
Teoriju uvijek povezivati s konkretnom domenom (zaposlenici, zadaci, ovlasti).

### Ishod faze
- gotovo poglavlje **Teorijski uvod** u LaTeX dokumentaciji  

---

## 3. Konceptualni model baze podataka

### Cilj faze
Vizualno i formalno prikazati strukturu baze podataka.

### Aktivnosti
- izrada UML klasnog dijagrama  
- definiranje entiteta:
  - User  
  - Role  
  - Permission  
  - Task  
  - AuditLog  
- definiranje odnosa i nasljeđivanja  

### Ishod faze
- UML dijagram spreman za dokumentaciju  
- jasan temelj za SQL implementaciju  

---

## 4. Logički i objektno-relacijski model (PostgreSQL)

### Cilj faze
Implementirati napredni model baze koristeći objektno-relacijske značajke PostgreSQL-a.

### Aktivnosti
- definiranje ENUM tipova (npr. status zadatka)  
- definiranje COMPOSITE tipova (meta-podaci)  
- nasljeđivanje tablica (različiti tipovi korisnika)  
- implementacija ograničenja integriteta  

### Ishod faze
- potpuno definiran SQL model baze  

---

## 5. Funkcije, procedure i okidači

### Cilj faze
Implementirati poslovnu logiku na razini baze podataka.

### Aktivnosti
- funkcije za provjeru prava pristupa  
- procedure za dodjelu uloga  
- okidači za:
  - automatsko bilježenje prijava  
  - evidenciju promjena (audit log)  

### Ishod faze
- demonstracija naprednih mogućnosti PostgreSQL-a  

---

## 6. Backend aplikacija (FastAPI)

### Cilj faze
Implementirati aplikacijski sloj sustava.

### Aktivnosti
- autentikacija (login / registracija)  
- autorizacija (RBAC provjere)  
- API rute za:
  - korisnike  
  - uloge  
  - zadatke  
- povezivanje s PostgreSQL bazom  

### Ishod faze
- funkcionalni REST API  

---

## 7. Frontend aplikacija (React)

### Cilj faze
Omogućiti grafičko korištenje sustava kroz React aplikaciju koja prikazuje sve funkcionalnosti PostgreSQL baze.

### Aktivnosti
- implementacija React aplikacije s React Router-om  
- autentikacija s JWT tokenima  
- stranice:
  - Login (prijava korisnika)
  - Dashboard (statistike i pregled)
  - Users (upravljanje korisnicima - CRUD)
  - Tasks (upravljanje zadacima - CRUD)
  - Roles (dodjela i upravljanje ulogama)
  - AuditLogs (pregled svih promjena u bazi)
- demonstracija svih PostgreSQL značajki:
  - ENUM tipovi (task_status, task_priority)
  - Procedure (create_user, create_task, assign_role)
  - Funkcije (get_user_tasks, get_overdue_tasks)
  - Triggeri (automatski audit log)
  - Viewovi (v_users_with_roles, v_tasks_details)
  - RBAC model (provjera permisija)

### Implementirane komponente
- `AuthContext` - Context za autentikaciju i state management
- `ProtectedRoute` - Zaštita ruta s provjerom autentikacije
- `Layout` - Glavni layout s navigacijom
- API service (Axios) - Centralizirana komunikacija s backendom
- Modali za kreiranje/uređivanje entiteta
- Badge komponente za statuse i prioritete
- Filteri i sortiranje podataka

### Ishod faze
- ✅ Funkcionalno React web sučelje
- ✅ Prikaz svih funkcionalnosti baze podataka
- ✅ JWT autentikacija i RBAC kontrola pristupa
- ✅ Jednostavno i intuitivno korisničko iskustvo
- ✅ README i detaljni priručnik (Faza_7_Prirucnik.md)  

---

## 8. Automatizacija i repozitorij

### Cilj faze
Osigurati jednostavnu instalaciju i profesionalnu prezentaciju projekta.

### Aktivnosti
- SQL skripta za inicijalizaciju baze  
- README dokument  
- javni GitHub repozitorij (GPL licenca)  

### Ishod faze
- projekt spreman za predaju  

---

## 9. Dokumentacija (LaTeX)

### Cilj faze
Izraditi cjelovitu akademsku dokumentaciju.

### Sadržaj
- opis domene  
- teorijski uvod  
- model baze  
- implementacija  
- primjeri korištenja  
- zaključak  

### Ishod faze
- završna dokumentacija prema pravilniku  

---

## 10. Završna provjera i evaluacija

### Cilj faze
Provjeriti usklađenost projekta sa svim zahtjevima.

### Aktivnosti
- testiranje sustava  
- provjera kriterija  
- završne dorade  

---

## Kako koristiti ovaj priručnik

Svaka faza se može obrađivati **zasebno**. Preporučeni redoslijed rada je od faze 1 prema fazi 10.

U sljedećim koracima projekt će se razvijati **fazu po fazu**, koristeći ovaj priručnik kao referentnu točku.

---

---

## Status implementacije

✅ **Faza 1** - Definicija domene i zahtjeva - ZAVRŠENO  
✅ **Faza 2** - Teorijski uvod - ZAVRŠENO  
✅ **Faza 3** - Konceptualni model baze podataka - ZAVRŠENO  
✅ **Faza 4** - Logički i objektno-relacijski model - ZAVRŠENO  
✅ **Faza 5** - Funkcije, procedure i okidači - ZAVRŠENO  
✅ **Faza 6** - Backend aplikacija (FastAPI) - ZAVRŠENO  
✅ **Faza 7** - Frontend aplikacija (React) - **ZAVRŠENO**  
✅ **Faza 8** - Automatizacija i repozitorij - ZAVRŠENO  
⏳ **Faza 9** - Dokumentacija (LaTeX) - U TIJEKU  
⏳ **Faza 10** - Završna provjera - SLJEDEĆE

---

## Ključne značajke implementacije

### 🔐 RBAC + Individualne permisije
Sustav koristi hibridni model kontrole pristupa:
- **Uloge (roles)** - grupne permisije (ADMIN, MANAGER, EMPLOYEE)
- **Direktne permisije (user_permissions)** - individualno dodijeljene/oduzete permisije

### ✅ Tijek odobravanja zadataka
Zadaci prolaze kroz strukturirani tijek:
```
TODO → IN_PROGRESS → PENDING_APPROVAL → COMPLETED
                  ↘ CANCELLED
```
- **Zaposlenik** može predložiti završetak (→ PENDING_APPROVAL)
- **Manager/Admin** može odobriti završetak (→ COMPLETED)

### 🔑 Promjena lozinke
Svi korisnici mogu promijeniti svoju lozinku putem sigurnog modala.

### 📊 10 PostgreSQL tablica
users, roles, permissions, role_permissions, user_roles, user_permissions, tasks, task_assignees, audit_log, login_events  

---

## Detaljni priručnici po fazama

Za svaku fazu postoji **detaljan priručnik** u `Prirucnici/` direktoriju:

- `Faza_1_2_3_Prirucnik.md` - Domene, teorija i konceptualni model
- `Faza_4_Prirucnik.md` - SQL implementacija baze
- `Faza_5_Prirucnik.md` - Funkcije, procedure i triggeri
- `Faza_6_Prirucnik.md` - Backend FastAPI
- `Faza_7_Prirucnik.md` - Frontend React

### Dodatna dokumentacija
- `images/ERA_diagram.md` - Ažurirani ERA dijagram s 10 tablica
- `PRISTUPNI_PODACI.md` - Pristupni podaci za sve korisnike
- `database/04_multi_assignees_migration.sql` - Migracija za višestruke assignee

---

**Sljedeći korak:**  
Faza 9 – LaTeX dokumentacija za završni rad.
