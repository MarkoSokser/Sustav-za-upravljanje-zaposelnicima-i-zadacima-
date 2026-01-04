# FAZA 7 - Frontend Aplikacija (React)

##  Pregled

Faza 7 obuhvaća razvoj React frontend aplikacije koja vizualno prikazuje sve funkcionalnosti PostgreSQL baze podataka razvijene u prethodnim fazama. Frontend omogućava korisniku da koristi sve značajke baze kroz jednostavno i intuitivno korisničko sučelje.

##  Struktura frontend projekta

```
frontend/
├── public/
│   └── index.html
├── src/
│   ├── components/          # Reusable komponente
│   │   ├── Layout.js        # Glavni layout s navigacijom
│   │   ├── Layout.css
│   │   └── ProtectedRoute.js
│   ├── context/
│   │   └── AuthContext.js   # Authentication context
│   ├── pages/               # Stranice aplikacije
│   │   ├── Login.js
│   │   ├── Dashboard.js
│   │   ├── Users.js
│   │   ├── Tasks.js
│   │   ├── Roles.js
│   │   └── AuditLogs.js
│   ├── services/
│   │   └── api.js           # API pozivi
│   ├── App.js
│   ├── index.js
│   └── index.css            # Globalni stilovi
├── package.json
└── README.md
```

##  Tehnologije

| Tehnologija | Verzija | Svrha |
|-------------|---------|-------|
| React | 18.2 | UI framework |
| React Router | 6.20 | Client-side routing |
| Axios | 1.6.2 | HTTP klijent |
| CSS3 | - | Stilizacija |

##  Instalacija i pokretanje

### 1. Instalacija dependencies

```powershell
cd frontend
npm install
```

### 2. Pokretanje development servera

```powershell
npm start
```

Aplikacija će se otvoriti na `http://localhost:3000`

### 3. Build za produkciju

```powershell
npm run build
```

##  Autentikacija i sigurnost

### JWT Token autentikacija

Frontend koristi JWT tokene za autentikaciju:

1. **Login** - Korisnik se prijavljuje s username i password
2. **Token storage** - JWT token se sprema u `localStorage`
3. **Request interceptor** - Axios automatski dodaje token u svaki zahtjev
4. **Response interceptor** - Automatsko odjavljanje pri 401 grešci

```javascript
// Primjer iz AuthContext.js
const login = async (username, password) => {
  const response = await authAPI.login(username, password);
  const { access_token, user: userData } = response.data;
  
  localStorage.setItem('token', access_token);
  localStorage.setItem('user', JSON.stringify(userData));
  setUser(userData);
};
```

### Protected Routes

Sve rute osim login stranice su zaštićene:

```javascript
<Route path="/" element={
  <ProtectedRoute>
    <Layout />
  </ProtectedRoute>
}>
```

##  Stranice i funkcionalnosti

### 1.  Login stranica (`/login`)

**Prikaz funkcionalnosti baze:**
- Procedura: `log_login_attempt()`
- Tablica: `login_events`
- Funkcija: `validate_email`

**Funkcionalnosti:**
- Prijava korisnika
- Validacija kredencijala
- Automatsko bilježenje login pokušaja u bazu
- Preusmjeravanje na dashboard nakon uspješne prijave

**Pristupni podaci za testiranje:**

| Uloga | Korisničko ime | Lozinka |
|-------|----------------|---------|
| **ADMIN** | admin | Admin123! |
| **MANAGER** | ivan_manager | IvanM2024! |
| **MANAGER** | ana_manager | AnaK2024! |
| **EMPLOYEE** | marko_dev | Marko2024! |
| **EMPLOYEE** | petra_dev | Petra2024! |
| **EMPLOYEE** | luka_dev | Luka2024! |
| **EMPLOYEE** | maja_design | Maja2024! |
| **EMPLOYEE** | tomislav_design | Tomi2024! |

---

### 1.1  Promjena lozinke 

**Funkcionalnost:** Korisnik može promijeniti svoju lozinku putem modala u headeru (ikona 🔑).

**Validacija:**
- Trenutna lozinka mora biti ispravna
- Nova lozinka: minimalno 8 znakova, veliko slovo, malo slovo, broj

**Backend endpoint:** `POST /api/auth/change-password`

---

### 2.  Dashboard (`/dashboard`)

**Prikaz funkcionalnosti baze:**
- Funkcija: `get_task_statistics()`
- Funkcija: `get_user_tasks(user_id)`
- Funkcija: `get_overdue_tasks()`
- View: `v_tasks_details`

**Funkcionalnosti:**
- Prikazuje statistike zadataka (ukupno, u tijeku, završeno, kasni)
- Prikazuje zadatke trenutnog korisnika
- Upozorenje na zadatke koji kasne
- Dobrodošlica s prikazom uloga korisnika

**SQL pozadina:**
```sql
-- Poziva se get_task_statistics() za statistike
SELECT * FROM get_task_statistics();

-- Poziva se get_user_tasks() za korisničke zadatke
SELECT * FROM get_user_tasks(user_id);

-- Poziva se get_overdue_tasks() za zadatke koji kasne
SELECT * FROM get_overdue_tasks();
```

---

### 3.  Korisnici (`/users`)

**Prikaz funkcionalnosti baze:**
- View: `v_users_with_roles`
- Procedura: `sp_create_user`
- Procedura: `sp_update_user`
- Procedura: `sp_deactivate_user`
- Funkcija: `validate_email(email)`
- Domena: `email_address`
- Domena: `username_type`
- Trigger: `trg_audit_users` (automatski audit log)
- Trigger: `trg_update_users_timestamp`

**Funkcionalnosti:**
- **Prikaz svih korisnika** - Koristi `v_users_with_roles` view
- **Kreiranje korisnika** - Poziva `sp_create_user` proceduru
- **Uređivanje korisnika** - Koristi `sp_update_user`
- **Deaktivacija/aktivacija** - `sp_deactivate_user` / `sp_activate_user`
- **Brisanje korisnika** - Soft delete
- **Filter po aktivnosti** - SQL WHERE klauzula

**Permisije:**
- USER_READ_ALL - Pregled korisnika
- USER_CREATE - Kreiranje
- USER_UPDATE - Uređivanje
- USER_DELETE - Brisanje

**SQL pozadina:**
```sql
-- Prikaz korisnika
SELECT * FROM v_users_with_roles WHERE is_active = true;

-- Kreiranje korisnika (poziva proceduru)
CALL sp_create_user(
  'username', 'email@test.com', 'password', 
  'Ime', 'Prezime', NULL, NULL
);

-- Trigger automatski kreira audit log zapis
-- trg_audit_users se automatski pokreće
```

---

### 4.  Zadaci (`/tasks`)

**Prikaz funkcionalnosti baze:**
- View: `v_tasks_details`
- Procedura: `create_task()`
- Procedura: `update_task_status()`
- Tablica: `task_assignees` (višestruka dodjela)
- Funkcija: `get_user_tasks(user_id)`
- Funkcija: `get_overdue_tasks()`
- ENUM: `task_status` (NEW, IN_PROGRESS, ON_HOLD, PENDING_APPROVAL, COMPLETED, CANCELLED)
- ENUM: `task_priority` (LOW, MEDIUM, HIGH, URGENT)
- Trigger: `trg_audit_tasks`
- Trigger: `trg_update_tasks_timestamp`

**Funkcionalnosti:**
- **Prikaz svih zadataka** - View `v_tasks_details`
- **Moji zadaci** - Endpoint `/my` s task_assignees
- **Kreiranje zadatka** - Procedura `create_task()`
- **Višestruka dodjela** - Tablica `task_assignees`
- **Promjena statusa** - S workflow odobravanja
- **Filter po statusu** - ENUM `task_status`
- **Filter po prioritetu** - ENUM `task_priority`

**Workflow odobravanja zadataka :**

```
┌─────────┐     ┌─────────────┐     ┌───────────────────┐     ┌───────────┐
│   NEW   │ ──► │ IN_PROGRESS │ ──► │ PENDING_APPROVAL  │ ──► │ COMPLETED │
└─────────┘     └─────────────┘     └───────────────────┘     └───────────┘
                      │                      │
                      ▼                      │ (Manager vraća)
                ┌──────────┐                 │
                │ ON_HOLD  │ ◄───────────────┘
                └──────────┘
```

**Pravila:**
| Uloga | Može staviti |
|-------|--------------|
| Employee | NEW → IN_PROGRESS → ON_HOLD → PENDING_APPROVAL |
| Manager/Admin | PENDING_APPROVAL → COMPLETED (odobravanje) |
| Manager/Admin | PENDING_APPROVAL → IN_PROGRESS (vraćanje na doradu) |

**Permisije:**
- TASK_READ_ALL - Pregled svih zadataka
- TASK_READ_SELF - Pregled svojih zadataka
- TASK_CREATE - Kreiranje
- TASK_UPDATE - Uređivanje
- TASK_UPDATE_SELF_STATUS - Promjena statusa svojih zadataka
- TASK_ASSIGN - Dodjela zadataka
- TASK_DELETE - Brisanje

**SQL pozadina:**
```sql
-- Prikaz zadataka
SELECT * FROM v_tasks_details WHERE status = 'IN_PROGRESS';

-- Višestruka dodjela (nova tablica)
INSERT INTO task_assignees (task_id, user_id, assigned_by) 
VALUES (1, 3, 2);

-- Promjena statusa s provjerom uloge
CALL update_task_status(task_id, 'PENDING_APPROVAL', user_id);
```

---

### 5.  Uloge i Permisije (`/roles`)

**Prikaz funkcionalnosti baze:**
- View: `v_roles_with_permissions`
- Procedura: `assign_role()`
- Procedura: `revoke_role()`
- Funkcija: `user_has_permission(user_id, permission)`
- Tablica: `roles`
- Tablica: `permissions`
- Tablica: `role_permissions` (many-to-many)
- Tablica: `user_roles` (many-to-many)
- **Tablica: `user_permissions`** (direktna dodjela permisija)
- Trigger: `trg_audit_user_roles`

**Funkcionalnosti:**
- **Pregled uloga** - View `v_roles_with_permissions`
- **Prikaz permisija** - Many-to-many relacija
- **Dodjela uloge** - Procedura `sp_assign_role`
- **Uklanjanje uloge** - Procedura `sp_remove_role`
- **Broj korisnika po ulozi** - Agregacija
- **Zaštita sistemskih uloga** - Constraint
- **Direktne permisije** - Dodaj/ukloni individualnu permisiju korisniku


**RBAC Model po ulogama:**
```
ADMIN (role_id=1)
├── USER_READ_ALL
├── USER_CREATE
├── USER_UPDATE
├── USER_DELETE
├── TASK_READ_ALL
├── TASK_CREATE
├── TASK_UPDATE
├── TASK_DELETE
├── ROLE_READ
├── ROLE_ASSIGN
├── AUDIT_READ_ALL
└── SYSTEM_ADMIN

MANAGER (role_id=2)
├── USER_READ_ALL
├── USER_UPDATE
├── TASK_READ_ALL
├── TASK_CREATE
├── TASK_UPDATE
├── ROLE_READ
└── AUDIT_READ_OWN

EMPLOYEE (role_id=3)
├── TASK_READ_OWN
└── USER_READ_OWN
```


**SQL pozadina:**
```sql
-- Prikaz uloga s permisijama
SELECT * FROM v_roles_with_permissions;

-- Dodjela uloge
CALL sp_assign_role(user_id, role_id);

-- Provjera permisije (uključuje direktne)
SELECT user_has_permission(user_id, 'TASK_CREATE');

-- Direktna dodjela permisije
INSERT INTO user_permissions (user_id, permission_id, is_granted, granted_by)
VALUES (4, 12, true, 1);

-- Uklanjanje direktne permisije
DELETE FROM user_permissions WHERE user_id = 4 AND permission_id = 12;
```

---

### 6.  Audit Logovi (`/audit`)

**Prikaz funkcionalnosti baze:**
- Tablica: `audit_log`
- Tablica: `login_events`
- Trigger: `trg_audit_users`
- Trigger: `trg_audit_tasks`
- Trigger: `trg_audit_user_roles`
- ENUM: `audit_action` (INSERT, UPDATE, DELETE)
- Funkcija: Automatsko bilježenje (trigger funkcije)

**Funkcionalnosti:**
- **Pregled audit logova** - Sve promjene u bazi
- **Login eventi** - Svi login pokušaji
- **Filter po entitetu** - users, tasks, user_roles
- **Filter po akciji** - INSERT, UPDATE, DELETE
- **Prikaz starih vrijednosti** - JSONB old_value
- **Prikaz novih vrijednosti** - JSONB new_value
- **Tko je napravio promjenu** - changed_by
- **Vrijeme promjene** - changed_at

**Permisije:**
- AUDIT_READ_ALL - Pregled svih audit logova

**SQL pozadina:**
```sql
-- Pregled audit logova
SELECT * FROM audit_log 
WHERE entity_name = 'users' 
  AND action = 'UPDATE'
ORDER BY changed_at DESC;

-- Login eventi
SELECT * FROM login_events 
WHERE successful = false
ORDER BY attempted_at DESC;

-- Triggeri automatski popunjavaju ove tablice
```

**Primjer audit log zapisa:**
```json
{
  "log_id": 123,
  "entity_name": "users",
  "entity_id": 5,
  "action": "UPDATE",
  "old_value": {
    "email": "stari@email.com",
    "first_name": "Staro Ime"
  },
  "new_value": {
    "email": "novi@email.com",
    "first_name": "Novo Ime"
  },
  "changed_by": 1,
  "changed_at": "2024-12-28T10:30:00"
}
```

---

##  API Integracija

### API Service (`services/api.js`)

Centralizirana konfiguracija svih API poziva:

```javascript
// Base URL
const API_BASE_URL = 'http://localhost:8000/api';

// Axios instance s interceptorima
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: { 'Content-Type': 'application/json' }
});

// Request interceptor - dodaje JWT token
api.interceptors.request.use(config => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor - logout na 401
api.interceptors.response.use(
  response => response,
  error => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);
```

### API Moduli

```javascript
// AUTH API
authAPI.login(username, password)
authAPI.getCurrentUser()
authAPI.logout()

// USERS API
usersAPI.getAll(isActive)
usersAPI.getById(userId)
usersAPI.create(userData)
usersAPI.update(userId, userData)
usersAPI.delete(userId)
usersAPI.deactivate(userId)
usersAPI.activate(userId)

// TASKS API
tasksAPI.getAll(params)
tasksAPI.getById(taskId)
tasksAPI.create(taskData)
tasksAPI.update(taskId, taskData)
tasksAPI.updateStatus(taskId, status)
tasksAPI.assignUser(taskId, userId)
tasksAPI.getMyTasks()
tasksAPI.getOverdue()

// ROLES API
rolesAPI.getAll()
rolesAPI.getById(roleId)
rolesAPI.assignToUser(userId, roleId)
rolesAPI.removeFromUser(userId, roleId)
rolesAPI.getPermissions()

// AUDIT API
auditAPI.getLogs(params)
auditAPI.getLoginEvents(params)
auditAPI.getRecentActivity(limit)
```

##  UI/UX Značajke

### Vizualni elementi

**Badge komponente:**
```javascript
// Status badge-ovi
TODO - plava (info)
IN_PROGRESS - narančasta (warning)
COMPLETED - zelena (success)
CANCELLED - crvena (danger)

// Prioritet badge-ovi
LOW - plava (info)
MEDIUM - narančasta (warning)
HIGH - crvena (danger)
```

**Modali:**
- Kreiranje/uređivanje entiteta
- Form validacija
- Error/success poruke
- Responsive dizajn

**Tablice:**
- Sortiranje
- Filtriranje
- Pagination (za buduća proširenja)
- Akcije po redu

##  Demonstracija funkcionalnosti baze

### Kako frontend prikazuje svaki PostgreSQL element

| PostgreSQL element | Gdje se prikazuje | Kako |
|-------------------|-------------------|------|
| **ENUM tipovi** | Tasks stranica | Dropdown lista za status i prioritet |
| **COMPOSITE tipovi** | Svi viewovi | timestamp_metadata automatski |
| **Domene** | Users stranica | Validacija email_address |
| **Funkcije** | Dashboard, Tasks | get_user_tasks(), get_overdue_tasks() |
| **Procedure** | Sve CRUD operacije | create_user, create_task, assign_role |
| **Triggeri** | Audit stranica | Automatski audit log zapisi |
| **Viewovi** | Users, Tasks, Roles | v_users_with_roles, v_tasks_details |
| **RBAC** | Cijela aplikacija | Provjera permisija prije akcija |

### Testiranje funkcionalnosti

**Testni scenarij 1: Triggeri**
1. Prijavi se kao admin
2. Idi na Users stranicu
3. Uredi korisnika
4. Idi na Audit stranicu
5. **Rezultat**: Vidiš UPDATE zapis u audit logu s old/new vrijednostima

**Testni scenarij 2: Procedure**
1. Prijavi se kao manager
2. Idi na Tasks stranicu
3. Kreiraj novi zadatak
4. **Rezultat**: Procedura `sp_create_task` se poziva, zadatak je kreiran

**Testni scenarij 3: RBAC**
1. Prijavi se kao employee
2. Pokušaj ići na Users stranicu
3. **Rezultat**: Vidiš samo vlastite podatke (permisija USER_READ_OWN)

**Testni scenarij 4: Funkcije**
1. Prijavi se kao bilo koji korisnik
2. Idi na Dashboard
3. **Rezultat**: Vidiš statistike (poziva se `get_task_statistics()`)

**Testni scenarij 5: ENUM tipovi**
1. Idi na Tasks stranicu
2. Kreiraj zadatak
3. Odaberi prioritet iz dropdown-a
4. **Rezultat**: Koristi se `task_priority` ENUM tip



