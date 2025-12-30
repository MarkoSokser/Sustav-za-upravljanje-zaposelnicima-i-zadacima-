import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { usersAPI, rolesAPI } from '../services/api';
import './Users.css';

const Users = () => {
  const { hasPermission, user: currentUser } = useAuth();
  const [users, setUsers] = useState([]);
  const [roles, setRoles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [selectedUser, setSelectedUser] = useState(null);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const [formData, setFormData] = useState({
    username: '',
    email: '',
    password: '',
    first_name: '',
    last_name: '',
    phone: '',
    department: '',
  });

  useEffect(() => {
    loadUsers();
    loadRoles();
  }, []);

  const loadUsers = async () => {
    setLoading(true);
    try {
      // Ako korisnik nema USER_READ_ALL, prikazi samo vlastite podatke
      if (!hasPermission('USER_READ_ALL')) {
        if (currentUser) {
          // Dohvati vlastite podatke preko /users/{id}
          const response = await usersAPI.getById(currentUser.user_id);
          setUsers([response.data]);
        } else {
          setUsers([]);
        }
      } else {
        const response = await usersAPI.getAll();
        setUsers(response.data);
      }
    } catch (error) {
      if (error.response?.status === 403) {
        setError('Nemate pristup ovoj stranici. Potrebne su dodatne permisije.');
      } else {
        setError('Greška pri učitavanju korisnika');
      }
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const loadRoles = async () => {
    // Samo ucitaj uloge ako ima permisiju
    if (!hasPermission('ROLE_READ')) {
      return;
    }
    try {
      const response = await rolesAPI.getAll();
      setRoles(response.data);
    } catch (error) {
      console.error('Greška pri učitavanju uloga:', error);
    }
  };

  const handleCreate = () => {
    setIsEditing(false);
    setSelectedUser(null);
    setFormData({
      username: '',
      email: '',
      password: '',
      first_name: '',
      last_name: '',
      phone: '',
      department: '',
    });
    setShowModal(true);
    setError('');
    setSuccess('');
  };

  const handleEdit = (user) => {
    setIsEditing(true);
    setSelectedUser(user);
    setFormData({
      username: user.username,
      email: user.email,
      password: '',
      first_name: user.first_name,
      last_name: user.last_name,
      phone: user.phone || '',
      department: user.department || '',
    });
    setShowModal(true);
    setError('');
    setSuccess('');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    try {
      if (isEditing) {
        // Update user - ne šaljemo password ako je prazan
        const updateData = { ...formData };
        if (!updateData.password) {
          delete updateData.password;
        }
        await usersAPI.update(selectedUser.user_id, updateData);
        setSuccess('Korisnik uspješno ažuriran');
      } else {
        // Create user
        await usersAPI.create(formData);
        setSuccess('Korisnik uspješno kreiran');
      }
      
      loadUsers();
      setTimeout(() => {
        setShowModal(false);
        setSuccess('');
      }, 1500);
    } catch (error) {
      // Parsiranje FastAPI validation errors
      let errorMsg = 'Greška pri spremanju korisnika';
      if (error.response?.data?.detail) {
        const detail = error.response.data.detail;
        if (typeof detail === 'string') {
          errorMsg = detail;
        } else if (Array.isArray(detail)) {
          // Validation errors - ekstrakcija poruka
          errorMsg = detail.map(err => {
            const field = err.loc?.join('.') || 'polje';
            const msg = err.msg || err.message || 'nepoznata greška';
            return `${field}: ${msg}`;
          }).join('; ');
        }
      }
      setError(errorMsg);
    }
  };

  const handleDelete = async (userId) => {
    if (!window.confirm('Jeste li sigurni da želite obrisati ovog korisnika?')) {
      return;
    }

    try {
      await usersAPI.delete(userId);
      setSuccess('Korisnik uspješno obrisan');
      loadUsers();
      setTimeout(() => setSuccess(''), 3000);
    } catch (error) {
      const errorMsg = error.response?.data?.detail || 'Greška pri brisanju korisnika';
      setError(typeof errorMsg === 'string' ? errorMsg : JSON.stringify(errorMsg));
    }
  };

  const handleToggleActive = async (userId, isActive) => {
    try {
      if (isActive) {
        // Deaktiviraj korisnika
        await usersAPI.deactivate(userId);
        setSuccess('Korisnik uspješno deaktiviran');
      } else {
        // Aktiviraj korisnika
        await usersAPI.activate(userId);
        setSuccess('Korisnik uspješno aktiviran');
      }
      loadUsers();
      setTimeout(() => setSuccess(''), 3000);
    } catch (error) {
      const errorMsg = error.response?.data?.detail || 'Greška pri promjeni statusa korisnika';
      setError(typeof errorMsg === 'string' ? errorMsg : JSON.stringify(errorMsg));
    }
  };

  if (loading) {
    return <div className="loading">Učitavanje...</div>;
  }

  const canCreate = hasPermission('USER_CREATE');
  const canUpdate = hasPermission('USER_UPDATE') || hasPermission('USER_UPDATE_ALL');
  const canDelete = hasPermission('USER_DELETE');
  const canDeactivate = hasPermission('USER_DEACTIVATE');

  return (
    <div className="users-page">
      <div className="page-header">
        <h1>Korisnici</h1>
        {canCreate && (
          <button className="btn btn-primary" onClick={handleCreate}>
            + Novi korisnik
          </button>
        )}
      </div>

      {error && <div className="error">{error}</div>}
      {success && <div className="success">{success}</div>}

      <div className="card">
        <table className="table">
          <thead>
            <tr>
              <th>Korisničko ime</th>
              <th>Ime i prezime</th>
              <th>Email</th>
              <th>Odjel</th>
              <th>Uloge</th>
              <th>Status</th>
              <th>Akcije</th>
            </tr>
          </thead>
          <tbody>
            {users.map(user => (
              <tr key={user.user_id}>
                <td>{user.username}</td>
                <td>{user.first_name} {user.last_name}</td>
                <td>{user.email}</td>
                <td>{user.department || '-'}</td>
                <td>
                  {user.roles?.map(role => (
                    <span key={role} className="badge badge-info" style={{marginRight: '5px'}}>
                      {role}
                    </span>
                  ))}
                </td>
                <td>
                  <span className={`badge ${user.is_active ? 'badge-success' : 'badge-danger'}`}>
                    {user.is_active ? 'Aktivan' : 'Neaktivan'}
                  </span>
                </td>
                <td>
                  <div className="action-buttons">
                    {canUpdate && (
                      <button 
                        className="btn btn-primary btn-sm" 
                        onClick={() => handleEdit(user)}
                      >
                        Uredi
                      </button>
                    )}
                    {canDeactivate && (
                      <button 
                        className={`btn ${user.is_active ? 'btn-warning' : 'btn-success'} btn-sm`}
                        onClick={() => handleToggleActive(user.user_id, user.is_active)}
                      >
                        {user.is_active ? 'Deaktiviraj' : 'Aktiviraj'}
                      </button>
                    )}
                    {canDelete && (
                      <button 
                        className="btn btn-danger btn-sm"
                        onClick={() => handleDelete(user.user_id)}
                      >
                        Obriši
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Modal za kreiranje/uređivanje */}
      {showModal && (
        <div className="modal">
          <div className="modal-content">
            <div className="modal-header">
              <h2>{isEditing ? 'Uredi korisnika' : 'Novi korisnik'}</h2>
              <button className="close" onClick={() => setShowModal(false)}>&times;</button>
            </div>
            
            <form onSubmit={handleSubmit}>
              <div className="form-row">
                <div className="form-group">
                  <label>Korisničko ime *</label>
                  <input
                    type="text"
                    value={formData.username}
                    onChange={(e) => setFormData({...formData, username: e.target.value})}
                    required
                    disabled={isEditing}
                  />
                </div>
                <div className="form-group">
                  <label>Email *</label>
                  <input
                    type="email"
                    value={formData.email}
                    onChange={(e) => setFormData({...formData, email: e.target.value})}
                    required
                  />
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Ime *</label>
                  <input
                    type="text"
                    value={formData.first_name}
                    onChange={(e) => setFormData({...formData, first_name: e.target.value})}
                    required
                  />
                </div>
                <div className="form-group">
                  <label>Prezime *</label>
                  <input
                    type="text"
                    value={formData.last_name}
                    onChange={(e) => setFormData({...formData, last_name: e.target.value})}
                    required
                  />
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Lozinka {!isEditing && '*'}</label>
                  <input
                    type="password"
                    value={formData.password}
                    onChange={(e) => setFormData({...formData, password: e.target.value})}
                    required={!isEditing}
                    placeholder={isEditing ? 'Ostavite prazno ako ne želite mijenjati' : ''}
                  />
                </div>
                <div className="form-group">
                  <label>Telefon</label>
                  <input
                    type="text"
                    value={formData.phone}
                    onChange={(e) => setFormData({...formData, phone: e.target.value})}
                  />
                </div>
              </div>

              <div className="form-group">
                <label>Odjel</label>
                <input
                  type="text"
                  value={formData.department}
                  onChange={(e) => setFormData({...formData, department: e.target.value})}
                />
              </div>

              {error && <div className="error">{error}</div>}
              {success && <div className="success">{success}</div>}

              <div className="modal-actions">
                <button type="button" className="btn btn-secondary" onClick={() => setShowModal(false)}>
                  Odustani
                </button>
                <button type="submit" className="btn btn-primary">
                  {isEditing ? 'Spremi' : 'Kreiraj'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Users;
