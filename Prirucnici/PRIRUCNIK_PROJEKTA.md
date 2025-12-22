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

## 7. Frontend aplikacija (React ili Nuxt)

### Cilj faze
Omogućiti grafičko korištenje sustava.

### Aktivnosti
- login i dashboard stranice  
- uvjetni prikaz funkcionalnosti prema ulozi  
- forme za upravljanje korisnicima i zadacima  

### Ishod faze
- funkcionalno web grafičko sučelje  

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

**Sljedeći korak:**  
Faza 1 – detaljna razrada aplikacijske domene i RBAC logike.
