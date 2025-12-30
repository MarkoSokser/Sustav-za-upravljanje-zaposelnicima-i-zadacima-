
// Mapiranje poznatih grešaka na prijateljske poruke
const errorMappings = [
  // Task greške
  { pattern: /rok.*prošlosti|due.*past/i, message: 'Rok zadatka ne može biti u prošlosti.' },
  { pattern: /zadatak.*ne postoji|task.*not.*exist/i, message: 'Zadatak nije pronađen.' },
  { pattern: /naslov.*obavezan|title.*required/i, message: 'Naslov zadatka je obavezan.' },
  
  // User greške
  { pattern: /korisnik.*ne postoji|user.*not.*exist/i, message: 'Korisnik nije pronađen.' },
  { pattern: /korisnik.*nije aktivan|user.*not.*active/i, message: 'Odabrani korisnik nije aktivan.' },
  { pattern: /username.*postoji|username.*exists/i, message: 'Korisničko ime je već zauzeto.' },
  { pattern: /email.*postoji|email.*exists/i, message: 'Email adresa je već u uporabi.' },
  
  // Permisije i autorizacija
  { pattern: /nemate.*permisiju|permission.*denied|forbidden/i, message: 'Nemate dozvolu za ovu akciju.' },
  { pattern: /nevazece.*vjerodajnice|invalid.*credentials/i, message: 'Neispravno korisničko ime ili lozinka.' },
  { pattern: /token.*expired|istekao/i, message: 'Vaša sesija je istekla. Prijavite se ponovo.' },
  
  // Uloge
  { pattern: /uloga.*ne postoji|role.*not.*exist/i, message: 'Uloga nije pronađena.' },
  { pattern: /uloga.*zauzeta|role.*in.*use/i, message: 'Uloga se ne može obrisati jer je dodijeljena korisnicima.' },
  
  // Općenite greške
  { pattern: /duplicate|već postoji|already.*exists/i, message: 'Zapis s ovim podacima već postoji.' },
  { pattern: /foreign.*key|referenc/i, message: 'Operacija nije moguća zbog povezanih podataka.' },
  { pattern: /ne može biti prazan|cannot.*empty|required/i, message: 'Obavezno polje nije ispunjeno.' },
];

/**
 * Formatira API grešku u korisnicima prijateljsku poruku
 * @param {Error} error - Axios error objekt
 * @param {string} defaultMessage - Defaultna poruka ako greška nije prepoznata
 * @returns {string} Prijateljska poruka o grešci
 */
export const formatErrorMessage = (error, defaultMessage = 'Operacija nije uspjela. Pokušajte ponovo.') => {
  // Provjeri ima li response
  const detail = error?.response?.data?.detail;
  
  if (!detail) {
    // Mrežna greška
    if (error?.code === 'ERR_NETWORK' || error?.message?.includes('Network')) {
      return 'Greška u povezivanju s serverom. Provjerite internet vezu.';
    }
    return defaultMessage;
  }
  
  // Pretvori detail u string za usporedbu
  let detailStr;
  if (typeof detail === 'string') {
    detailStr = detail;
  } else if (Array.isArray(detail)) {
    // FastAPI validation errors
    detailStr = detail.map(err => err.msg || err.message || '').join(' ');
  } else {
    detailStr = JSON.stringify(detail);
  }
  
  // Pretraži mapiranje grešaka
  for (const { pattern, message } of errorMappings) {
    if (pattern.test(detailStr)) {
      return message;
    }
  }
  
  // Ako nije prepoznata greška, vrati generičku poruku
  // (ne prikazuj sirovu SQL grešku korisniku)
  console.warn('Neprepoznata greška:', detailStr);
  return defaultMessage;
};

export default formatErrorMessage;
