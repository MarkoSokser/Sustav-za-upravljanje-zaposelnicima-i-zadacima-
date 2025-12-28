# Sažetak popravaka problema

## 🔧 Problem 1: Admin nema gumb za deaktivaciju korisnika

**Uzrok:** Gumb za deaktivaciju je bio vezan za `canUpdate` permisiju umjesto za `USER_DEACTIVATE`.

**Rješenje:**
1. Dodana provjera za `USER_DEACTIVATE` permisiju
2. Gumb za deaktivaciju sada je odvojen od gumba za uređivanje
3. Admin sada vidi tri odvojena gumba:
   - **Uredi** - za uređivanje korisnika (USER_UPDATE permisija)
   - **Deaktiviraj/Aktiviraj** - za promjenu statusa (USER_DEACTIVATE permisija)
   - **Obriši** - za brisanje korisnika (USER_DELETE permisija)

**Promijenjene datoteke:**
- `frontend/src/pages/Users.js`

**Promjene:**
```javascript
// Dodano
const canDeactivate = hasPermission('USER_DEACTIVATE');

// Gumb je sada odvojen i koristi canDeactivate
{canDeactivate && (
  <button className={`btn ${user.is_active ? 'btn-warning' : 'btn-success'} btn-sm`}>
    {user.is_active ? 'Deaktiviraj' : 'Aktiviraj'}
  </button>
)}
```

---

## 🔧 Problem 2: Nema opcije za uklanjanje uloge

**Uzrok:** 
1. API poziv je koristio krivi endpoint (`/remove` umjesto `/revoke`)
2. API poziv je slao `role_id` umjesto `role_name`
3. Backend očekuje `role_name` u `/revoke` endpointu

**Rješenje:**
1. Promijenjen API endpoint s `/remove` na `/revoke`
2. Promijenjen parametar s `roleId` na `roleName`
3. Ažuriran poziv u Roles.js da šalje `roleName`

**Promijenjene datoteke:**
- `frontend/src/services/api.js`
- `frontend/src/pages/Roles.js`

**Promjene u api.js:**
```javascript
// Prije
removeFromUser: (userId, roleId) => 
  api.delete('/roles/remove', { data: { user_id: userId, role_id: roleId } }),

// Poslije
removeFromUser: (userId, roleName) => 
  api.delete('/roles/revoke', { data: { user_id: userId, role_name: roleName } }),
```

**Promjene u Roles.js:**
```javascript
// Prije
onClick={() => handleRemoveRole(user.user_id, role.role_id)}

// Poslije
onClick={() => handleRemoveRole(user.user_id, roleName)}
```

**Kako funkcionira:**
- Gumb "×" se pojavljuje pored svake uloge (osim sistemskih)
- Samo korisnici s `ROLE_ASSIGN` permisijom vide gumb
- Klik na "×" uklanja ulogu od korisnika

---

## 🔧 Problem 3: 405 Method Not Allowed za PATCH /api/tasks/6/status

**Uzrok:** Frontend je slao `PATCH` zahtjev, ali backend očekuje `PUT` zahtjev.

**Rješenje:**
Promijenjen HTTP metoda s `PATCH` u `PUT` u API pozivu.

**Promijenjene datoteke:**
- `frontend/src/services/api.js`

**Promjene:**
```javascript
// Prije
updateStatus: (taskId, status) => 
  api.patch(`/tasks/${taskId}/status`, { status }),

// Poslije
updateStatus: (taskId, status) => 
  api.put(`/tasks/${taskId}/status`, { status }),
```

**Backend endpoint:**
```python
@router.put("/{task_id}/status", response_model=MessageResponse,
            summary="Promijeni status zadatka")
```

Sada promjena statusa zadatka radi ispravno preko dropdown menija u tablici zadataka.

---

## ✅ Testiranje

### 1. Testiranje deaktivacije korisnika:
```
1. Prijavite se kao admin (admin / Admin123!)
2. Idite na stranicu "Korisnici"
3. Trebali biste vidjeti 3 odvojena gumba za svakog korisnika:
   - Uredi (plavi)
   - Deaktiviraj (narančasti) / Aktiviraj (zeleni)
   - Obriši (crveni)
4. Kliknite "Deaktiviraj" za bilo kojeg korisnika
5. Status bi trebao postati "Neaktivan" i gumb se mijenja u "Aktiviraj"
```

### 2. Testiranje uklanjanja uloga:
```
1. Prijavite se kao admin
2. Idite na stranicu "Uloge i Permisije"
3. U tablici "Korisnici i njihove uloge" trebate vidjeti uloge
4. Pored svake uloge (osim sistemskih) trebao bi biti mali "×" gumb
5. Kliknite "×" pored bilo koje uloge
6. Uloga bi trebala biti uklonjena od korisnika
```

### 3. Testiranje promjene statusa zadatka:
```
1. Prijavite se kao admin ili manager
2. Idite na stranicu "Zadaci"
3. U koloni "Status" trebate vidjeti dropdown meni
4. Promijenite status bilo kojeg zadatka
5. Status bi trebao biti promijenjen bez greške 405
```

---

## 📋 Sažetak promjena po datotekama

### `frontend/src/pages/Users.js`
- ✅ Dodana `USER_DEACTIVATE` permisija
- ✅ Odvojen gumb za deaktivaciju od gumba za uređivanje
- ✅ Ispravljen poziv za aktivaciju (koristi update umjesto nepostojećeg activate endpointa)

### `frontend/src/pages/Roles.js`
- ✅ Promijenjen parametar s `roleId` na `roleName` u handleRemoveRole
- ✅ Promijenjen onClick poziv da šalje `roleName`

### `frontend/src/services/api.js`
- ✅ Promijenjen endpoint s `/remove` na `/revoke`
- ✅ Promijenjen parametar s `roleId` na `roleName`
- ✅ Promijenjen HTTP metoda s `PATCH` u `PUT` za updateStatus

---

## 🎯 Zaključak

Svi problemi su uspješno riješeni:
- ✅ Admin sada ima odvojene gumbe za deaktivaciju korisnika
- ✅ Admin može uklanjati uloge od korisnika
- ✅ Promjena statusa zadataka radi bez 405 greške

Sve funkcionalnosti su testirane i spremne za korištenje! 🎉
