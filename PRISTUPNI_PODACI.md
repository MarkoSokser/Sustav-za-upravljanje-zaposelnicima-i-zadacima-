# Pristupni podaci za korisnike

## Administrator
- **Korisničko ime:** `admin`
- **Lozinka:** `Admin123!`
- **Email:** admin@example.com
- **Uloga:** ADMIN

## Manageri

### Ivan Horvat
- **Korisničko ime:** `ivan_manager`
- **Lozinka:** `IvanM2024!`
- **Email:** ivan.horvat@example.com
- **Uloga:** MANAGER

### Ana Kovač
- **Korisničko ime:** `ana_manager`
- **Lozinka:** `AnaK2024!`
- **Email:** ana.kovac@example.com
- **Uloga:** MANAGER

## Zaposlenici - Development Team

### Marko Novak
- **Korisničko ime:** `marko_dev`
- **Lozinka:** `Marko2024!`
- **Email:** marko.novak@example.com
- **Uloga:** EMPLOYEE
- **Manager:** Ivan Horvat

### Petra Jurić
- **Korisničko ime:** `petra_dev`
- **Lozinka:** `Petra2024!`
- **Email:** petra.juric@example.com
- **Uloga:** EMPLOYEE
- **Manager:** Ivan Horvat

### Luka Barić
- **Korisničko ime:** `luka_dev`
- **Lozinka:** `Luka2024!`
- **Email:** luka.baric@example.com
- **Uloga:** EMPLOYEE
- **Manager:** Ivan Horvat

## Zaposlenici - Design Team

### Maja Pavić
- **Korisničko ime:** `maja_design`
- **Lozinka:** `Maja2024!`
- **Email:** maja.pavic@example.com
- **Uloga:** EMPLOYEE
- **Manager:** Ana Kovač

### Tomislav Knez
- **Korisničko ime:** `tomislav_design`
- **Lozinka:** `Tomi2024!`
- **Email:** tomislav.knez@example.com
- **Uloga:** EMPLOYEE
- **Manager:** Ana Kovač

## Deaktivirani korisnik

### Old Employee
- **Korisničko ime:** `old_employee`
- **Lozinka:** `Old2024!`
- **Email:** old.employee@example.com
- **Uloga:** EMPLOYEE
- **Status:** NEAKTIVAN

---

## Napomene

1. **Sve lozinke su promijenjene** iz "testni" u jedinstvene, sigurne lozinke
2. **Format lozinki:** Početno slovo + godina + poseban znak
3. **Za testiranje:** Preporučamo korištenje admin, ivan_manager ili marko_dev računa
4. **Sigurnost:** Ove lozinke su samo za razvojno okruženje - u produkciji koristite jače lozinke
5. **Promjena lozinke:** Svi korisnici mogu promijeniti svoju lozinku kroz modal u aplikaciji

## Potrebno nakon instalacije

Nakon što pokrenete SQL skripte, sve ove lozinke će biti aktivne:
```bash
# Redoslijed izvršavanja SQL skripti
database/01_schema.sql
database/02_seed_data.sql
database/03_functions_procedures.sql
database/04_multi_assignees_migration.sql
```

## Tijek odobravanja zadataka

| Uloga | Može postaviti status |
|-------|----------------------|
| **EMPLOYEE** | TODO, IN_PROGRESS, PENDING_APPROVAL, CANCELLED |
| **MANAGER** | TODO, IN_PROGRESS, PENDING_APPROVAL, COMPLETED, CANCELLED |
| **ADMIN** | Sve statuse |

**Napomena:** EMPLOYEE može predložiti završetak (PENDING_APPROVAL), ali samo MANAGER/ADMIN može odobriti (COMPLETED).
