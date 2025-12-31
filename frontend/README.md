# Frontend - Interni sustav za upravljanje zaposlenicima i zadacima

React frontend aplikacija koja prikazuje sve funkcionalnosti PostgreSQL baze podataka.

##  Tehnologije

- **React 18.2** - UI framework
- **React Router 6** - Routing
- **Axios** - HTTP klijent za komunikaciju s backend API-jem
- **CSS3** - Stilizacija

##  Struktura projekta

```
frontend/
├── public/
│   └── index.html              # HTML template
├── src/
│   ├── components/             # Reusable komponente
│   │   ├── Layout.js           # Glavni layout s navigacijom
│   │   └── ProtectedRoute.js   # Zaštita ruta (autentikacija)
│   ├── context/
│   │   └── AuthContext.js      # Context za autentikaciju
│   ├── pages/                  # Stranice aplikacije
│   │   ├── Login.js            # Prijava
│   │   ├── Dashboard.js        # Dashboard sa statistikama
│   │   ├── Users.js            # Upravljanje korisnicima
│   │   ├── Tasks.js            # Upravljanje zadacima
│   │   ├── Roles.js            # Uloge i permisije
│   │   └── AuditLogs.js        # Audit logovi
│   ├── services/
│   │   └── api.js              # API pozivi
│   ├── App.js                  # Glavna aplikacija
│   ├── index.js                # Entry point
│   └── index.css               # Globalni stilovi
└── package.json
```

##  Instalacija i pokretanje

### Preduvjeti
- Node.js 16+ i npm
- Backend API mora biti pokrenut na `http://localhost:8000`

### Instalacija

```powershell
# Pozicioniraj se u frontend direktorij
cd frontend

# Instaliraj dependencies
npm install
```

### Pokretanje

```powershell
# Pokreni development server
npm start
```

Aplikacija će se otvoriti na `http://localhost:3000`

### Build za produkciju

```powershell
npm run build
```

Build će biti kreiran u `build/` direktoriju.

##  Autentikacija

Aplikacija koristi JWT token autentikaciju:
- Token se sprema u `localStorage`
- Automatski se dodaje u svaki API poziv (Authorization header)
- Pri 401 grešci korisnik se automatski odjavljuje

### Demo pristupni podaci

| Uloga | Username | Password | Opis |
|-------|----------|----------|------|
| **ADMIN** | admin | admin123 | Puni pristup svim funkcijama |
| **MANAGER** | jnovak | manager123 | Upravljanje timom i zadacima |
| **EMPLOYEE** | ahorvat | employee123 | Pregled vlastitih zadataka |

##  Stranice i funkcionalnosti

### 1. Login (`/login`)
- Prijava korisnika
- Validacija kredencijala
- JWT token autentikacija

### 2. Dashboard (`/dashboard`)
- Pregled statistika (ukupni zadaci, u tijeku, završeno, kasni)
- Moji zadaci
- Zadaci koji kasne
- Dobrodošlica s prikazom uloga

### 3. Korisnici (`/users`)
**Prikazuje funkcionalnosti baze:**
- View: `v_users_with_roles`
- Procedura: `create_user`
- Funkcija: `validate_email`
- Triggeri za audit log

**Funkcionalnosti:**
- Prikaz svih korisnika s ulogama
- Kreiranje novog korisnika (ADMIN)
- Uređivanje korisnika (ADMIN/MANAGER)
- Deaktivacija/aktivacija korisnika
- Brisanje korisnika (ADMIN)
- Filter po aktivnosti

### 4. Zadaci (`/tasks`)
**Prikazuje funkcionalnosti baze:**
- View: `v_tasks_details`
- Procedura: `create_task`, `update_task_status`, `assign_task`
- Funkcija: `get_user_tasks`, `get_overdue_tasks`
- ENUM tipovi: `task_status`, `task_priority`

**Funkcionalnosti:**
- Prikaz svih zadataka
- Kreiranje novog zadatka
- Uređivanje zadatka
- Promjena statusa (TODO → IN_PROGRESS → COMPLETED)
- Dodjela zadatka korisniku
- Filtriranje po statusu i prioritetu
- Prikaz zadataka koji kasne

### 5. Uloge i Permisije (`/roles`)
**Prikazuje funkcionalnosti baze:**
- View: `v_roles_with_permissions`
- Procedura: `assign_role`, `remove_role`
- Funkcija: `user_has_permission`
- RBAC model

**Funkcionalnosti:**
- Pregled svih uloga s permisijama
- Dodjela uloge korisniku
- Uklanjanje uloge
- Prikaz broja korisnika po ulozi
- Prikaz svih permisija

### 6. Audit Logovi (`/audit`)
**Prikazuje funkcionalnosti baze:**
- Tablica: `audit_log`, `login_events`
- Triggeri: `trg_audit_users`, `trg_audit_tasks`, `trg_audit_user_roles`
- View: Automatsko bilježenje svih promjena

**Funkcionalnosti:**
- Pregled svih promjena u bazi (INSERT, UPDATE, DELETE)
- Prikaz login evenata (uspješni i neuspješni)
- Filtriranje po entitetu i akciji
- Prikaz starih i novih vrijednosti
- Prikaz tko je napravio promjenu i kada

##  UI/UX Features

- **Responzivan dizajn** - Prilagođava se svim veličinama ekrana
- **Intuitivna navigacija** - Sidebar s jasnim ikonama
- **Vizualni feedback** - Badge-ovi za statuse i prioritete
- **Error handling** - Jasne poruke o greškama
- **Loading states** - Indikatori učitavanja
- **Modali** - Za kreiranje i uređivanje entiteta
- **Real-time updates** - Automatsko osvježavanje nakon akcija

##  Permisije i pristup

Aplikacija provjerava permisije za svaku akciju:

| Akcija | Potrebna permisija |
|--------|-------------------|
| Pregled korisnika | USER_READ_ALL |
| Kreiranje korisnika | USER_CREATE |
| Uređivanje korisnika | USER_UPDATE |
| Brisanje korisnika | USER_DELETE |
| Pregled zadataka | TASK_READ_ALL |
| Kreiranje zadatka | TASK_CREATE |
| Uređivanje zadatka | TASK_UPDATE |
| Brisanje zadatka | TASK_DELETE |
| Pregled uloga | ROLE_READ |
| Dodjela uloga | ROLE_ASSIGN |
| Pregled audit logova | AUDIT_READ_ALL |

##  API Integracija

Frontend komunicira s backend API-jem putem Axios klijenta:

```javascript
// Primjer API poziva
import { usersAPI } from './services/api';

// Dohvati sve korisnike
const users = await usersAPI.getAll();

// Kreiraj novog korisnika
await usersAPI.create({
  username: 'novak',
  email: 'novak@example.com',
  password: 'password123',
  first_name: 'Ivan',
  last_name: 'Novak',
});
```

Sve API funkcije su definirane u `src/services/api.js`.

