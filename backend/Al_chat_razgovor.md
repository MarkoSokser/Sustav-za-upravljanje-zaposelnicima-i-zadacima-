
## 4. Backend (FastAPI + Python) - Kompleksne implementacije

### 4.1 Dependency Injection za provjeru permisija (require_permission)

**Ja:** Imam puno API ruta koje trebaju provjeravati različite permisije. Kako napraviti reusable mehanizam za provjeru permisija u FastAPI-ju, a da ne ponavljam isti kod na svakoj ruti?

**AI :**
> FastAPI ima moćan Dependency Injection sustav. Za dinamičke provjere koristi **dependency factory** - funkcija koja vraća drugu funkciju:
> 
> ```python
> def require_permission(permission_code: str):
>     async def permission_checker(
>         current_user: dict = Depends(get_current_active_user),
>         conn = Depends(get_db_dependency)
>     ) -> dict:
>         # Provjera logika ovdje
>         if not has_permission:
>             raise HTTPException(status_code=403)
>         return current_user
>     return permission_checker
> ```
> 
> Korištenje na ruti:
> ```python
> @router.get("/", dependencies=[Depends(require_permission("TASK_READ_ALL"))])
> # ili
> current_user: dict = Depends(require_permission("TASK_CREATE"))
> ```
> 
> Prednosti:
> - Jedna definicija, beskonačno korištenje
> - Jasno dokumentirano koja permisija je potrebna
> - Automatski vraća current_user za daljnje korištenje

**Ja:** Zašto vraćam `permission_checker` funkciju, a ne direktno provjeravam?

**AI :**
> To je **closure** pattern. `require_permission("TASK_CREATE")` se poziva pri definiciji rute, NE pri svakom requestu. 
> 
> Kad napišeš `Depends(require_permission("TASK_CREATE"))`:
> 1. `require_permission("TASK_CREATE")` se izvršava JEDNOM pri startupu
> 2. Vraća `permission_checker` funkciju s "zapamćenim" `permission_code`
> 3. FastAPI poziva `permission_checker` na SVAKOM requestu
> 
> Bez ovog patterna, morao bi pisati:
> ```python
> @router.get("/")
> async def route(user = Depends(get_current_user), conn = Depends(get_db)):
>     if not check_permission(conn, user['id'], "TASK_CREATE"):  # Ponavljanje!
>         raise HTTPException(403)
> ```

**Moja implementacija:**
Kreirao sam `require_permission()` factory koji koristi closure za pamćenje permission koda.

---

### 4.2 Kombinacija direktnih permisija i permisija iz uloga

**Ja:** U bazi imam `user_permissions` tablicu za direktne dodjele i `role_permissions` za dodjele kroz uloge. Direktne dodjele imaju prioritet. Kako to implementirati u Pythonu tako da radi s PostgreSQL funkcijama?

**AI :**
> Logika provjere treba biti:
> 
> ```
> 1. Provjeri postoji li direktna dodjela u user_permissions
>    - Ako postoji i granted=TRUE → dozvoljeno
>    - Ako postoji i granted=FALSE → zabranjeno
> 2. Ako nema direktne dodjele → provjeri kroz role_permissions
> ````
> 
> Zatim uvjetno provjeri direktnu permisiju samo ako tablica postoji.

**Ja:** Zašto koristiti `information_schema` umjesto `try/except`?

**AI :**
> `information_schema` je SQL standard i:
> - Ne izaziva exception/rollback
> - Radi unutar iste transakcije
> - Vraća čisti boolean
> 
> `try/except` na SQL grešci:
> - Izaziva rollback u PostgreSQL
> - Prekida transakciju
> - Kompleksnije za handling

**Moja implementacija:**
Kreirao sam `check_permission()` i `get_user_permissions_list()` funkcije koje dinamički provjeravaju postojanje tablice i kombiniraju izvore permisija.

---

### 4.3 Workflow za odobrenje zadataka (PENDING_APPROVAL)

**Ja:** Imam kompleksan workflow: Employee ne može direktno označiti zadatak kao COMPLETED - mora ga staviti na PENDING_APPROVAL, pa Manager/Admin odobrava. Kako to implementirati na API razini?

**AI :**
> Trebaš kombinaciju provjera:
> 
> 1. **Provjeri ulogu korisnika** - koristi JOIN s roles tablicom
> 2. **Provjeri trenutni status zadatka** - dohvati prije promjene
> 3. **Primijeni pravila** prema ulozi i statusu
> 
> Pseudokod:
> ```python
> # 1. Dohvati trenutni status
> current_status = get_task_status(task_id)
> 
> # 2. Provjeri je li manager/admin
> is_manager_or_admin = check_roles(user_id, ['ADMIN', 'MANAGER'])
> 
> # 3. Pravila
> if new_status == 'COMPLETED':
>     if not is_manager_or_admin:
>         raise Error("Koristite PENDING_APPROVAL")
>     if current_status != 'PENDING_APPROVAL':
>         raise Error("Zadatak mora biti u PENDING_APPROVAL")
> ```
> 
> Za provjeru uloga, koristi EXISTS s JOIN-om - brže je od dohvaćanja svih uloga:
> ```sql
> SELECT EXISTS (
>     SELECT 1 FROM user_roles ur
>     JOIN roles r ON ur.role_id = r.role_id
>     WHERE ur.user_id = %s AND r.name IN ('ADMIN', 'MANAGER')
> ) AS is_manager_or_admin
> ```

**Ja:** Trebam li ovu logiku staviti u API ili u PostgreSQL proceduru?

**AI :**
> Najbolje je **oboje**:
> 
> 1. **API sloj** - user-friendly poruke greške, rani return za očite slučajeve
> 2. **Baza** - finalna validacija, osigurava konzistentnost čak i ako netko pristupi direktno bazi
> 
> API može dati poruku "Koristite status 'Čeka odobrenje'", dok baza samo vraća generičku grešku. Bolje korisničko iskustvo.

**Moja implementacija:**
Kreirao sam `update_task_status` endpoint s dvostrukom validacijom - na API razini za UX i pozivom PostgreSQL procedure za integritet.

---

### 4.4 Dinamički SQL s uvjetnim filterima

**Ja:** Imam GET /tasks endpoint koji prima puno opcionalnih query parametara (status, priority, assigned_to, created_by). Kako graditi SQL upit dinamički bez SQL injection ranjivosti?

**AI :**
> Koristi **parametrizirane upite** s dinamičkim građenjem WHERE klauzule:
> 
> ```python
> query = "SELECT * FROM table WHERE 1=1"  # 1=1 trik za lakše dodavanje AND
> params = []
> 
> if status_filter:
>     query += " AND status = %s"
>     params.append(status_filter.value)  # .value za Enum
> 
> if priority:
>     query += " AND priority = %s"
>     params.append(priority.value)
> 
> # Izvršenje
> cur.execute(query, params)
> ```
> 
> Ključno:
> - NIKAD ne koristiti f-string za vrijednosti: `f"WHERE status = '{status}'"` ❌
> - UVIJEK koristiti `%s` placeholder s params listom
> - Za Enum vrijednosti koristi `.value` atribut

**Ja:** Zašto `WHERE 1=1`? Izgleda čudno.

**AI :**
> `WHERE 1=1` je trik koji olakšava dinamičko građenje:
> 
> Bez toga:
> ```python
> query = "SELECT * FROM table"
> conditions = []
> if filter1: conditions.append("col1 = %s")
> if filter2: conditions.append("col2 = %s")
> if conditions:
>     query += " WHERE " + " AND ".join(conditions)
> ```
> 
> S `1=1`:
> ```python
> query = "SELECT * FROM table WHERE 1=1"
> if filter1: query += " AND col1 = %s"
> if filter2: query += " AND col2 = %s"
> ```
> 
> Jednostavnije, manje koda, manja šansa za grešku. Optimizator baze ionako eliminira `1=1`.

**Moja implementacija:**
Koristim ovaj pattern u `get_all_tasks` endpointu za dinamičko filtriranje.

---

### 4.5 Višestruka dodjela zadataka s backward compatibility

**Ja:** Dodao sam novu `task_assignees` tablicu za višestruku dodjelu, ali stari `assigned_to` stupac još postoji. Kako održavati oba sinkronizirana?

**AI :**
> Strategija **backward compatibility**:
> 
> 1. **Pri kreiranju**: Ako imaš listu assignee-a, prvog stavi u `assigned_to`, sve u `task_assignees`
> 2. **Pri čitanju**: Koristi VIEW koji kombinira oba izvora s ARRAY_AGG
> 3. **Pri ažuriranju**: Uvijek ažuriraj oba
> 
> ```python
> # Kreiranje
> first_assignee = assigned_to_ids[0] if assigned_to_ids else assigned_to
> 
> # Spremi u staru kolonu
> UPDATE tasks SET assigned_to = first_assignee
> 
> # Spremi sve u novu tablicu
> for user_id in assigned_to_ids:
>     INSERT INTO task_assignees ... ON CONFLICT DO NOTHING
> ```
> 
> `ON CONFLICT DO NOTHING` spriječava duplikate ako se isti korisnik pokuša dodati više puta.

**Ja:** Što ako netko koristi stari API koji šalje samo `assigned_to`?

**AI :**
> Onda:
> 1. Provjeri postoji li `assigned_to_ids` u requestu
> 2. Ako ne, koristi `assigned_to` kao fallback
> 3. Dodaj tog korisnika i u `task_assignees` za konzistentnost
> 
> ```python
> user_ids = []
> if assignment.assignee_ids:
>     user_ids = assignment.assignee_ids
> elif assignment.assignee_id:
>     user_ids = [assignment.assignee_id]
> ```
> 
> Tako stari klijenti i dalje rade, a novi mogu koristiti višestruku dodjelu.

**Moja implementacija:**
Kreirao sam `assign_task` i `update_task` endpointe koji podržavaju oba načina dodjele uz sinkronizaciju.

---

### 4.6 Pydantic validatori za kompleksna pravila

**Ja:** Kako implementirati validaciju lozinke (veliko slovo, malo slovo, broj) u Pydantic modelu?

**AI :**
> Koristi `@field_validator` dekorator u Pydantic v2:
> 
> ```python
> from pydantic import BaseModel, field_validator
> 
> class UserCreate(BaseModel):
>     password: str
>     
>     @field_validator('password')
>     @classmethod
>     def validate_password(cls, v):
>         if not any(c.isupper() for c in v):
>             raise ValueError('Mora sadržavati veliko slovo')
>         if not any(c.islower() for c in v):
>             raise ValueError('Mora sadržavati malo slovo')
>         if not any(c.isdigit() for c in v):
>             raise ValueError('Mora sadržavati broj')
>         return v
> ```
> 
> Napomene:
> - U Pydantic v2 koristi `@field_validator`, ne `@validator`
> - Mora imati `@classmethod` dekorator
> - `v` je vrijednost polja koja se validira
> - `raise ValueError` automatski se pretvara u HTTP 422

**Ja:** Zašto `any()` s generator expression?

**AI :**
> `any(c.isupper() for c in v)` je:
> - Memory-efikasno (generator, ne lista)
> - Short-circuit evaluacija (prestaje čim nađe True)
> - Čitljivije od regex-a za jednostavne provjere
> 
> Alternativa s regex-om:
> ```python
> import re
> if not re.search(r'[A-Z]', v):
>     raise ValueError('...')
> ```
> 
> Za kompleksnije pattern matching, regex je bolji. Za jednostavne provjere kao ova, `any()` je čitljiviji.

**Moja implementacija:**
Koristim `@field_validator` u `UserCreate` i `ChangePassword` modelima za validaciju lozinki.

