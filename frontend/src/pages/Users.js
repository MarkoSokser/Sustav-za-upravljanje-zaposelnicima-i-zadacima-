import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { usersAPI, rolesAPI } from '../services/api';
import { formatErrorMessage } from '../utils/errorHandler';
import './Users.css';

const Users = () => {
  const { hasPermission, user: currentUser, isManager } = useAuth();
  const [users, setUsers] = useState([]);
  const [teamMembers, setTeamMembers] = useState([]);
  const [roles, setRoles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [selectedUser, setSelectedUser] = useState(null);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [viewMode, setViewMode] = useState('all'); // 'all', 'team', 'self'

  const [formData, setFormData] = useState({
    username: '',
    email: '',
    password: '',
    first_name: '',
    last_name: '',
    manager_id: '',
  });

  useEffect(() => {
    loadUsers();
    loadRoles();
    if (isManager() && currentUser) {
      loadTeam();
    }
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const loadTeam = async () => {
    try {
      const response = await usersAPI.getTeam(currentUser.user_id);
      setTeamMembers(response.data);
    } catch (error) {
      console.error('Greška pri učitavanju tima:', error);
    }
  };

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
      manager_id: '',
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
      manager_id: user.manager_id || '',
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
      // Pripremi podatke - konvertiraj manager_id u broj ili null
      const dataToSend = { ...formData };
      if (dataToSend.manager_id === '' || dataToSend.manager_id === null) {
        dataToSend.manager_id = null;
      } else {
        dataToSend.manager_id = parseInt(dataToSend.manager_id);
      }

      if (isEditing) {
        // Update user - ne šaljemo password ako je prazan
        if (!dataToSend.password) {
          delete dataToSend.password;
        }
        await usersAPI.update(selectedUser.user_id, dataToSend);
        setSuccess('Korisnik uspješno ažuriran');
      } else {
        // Create user
        await usersAPI.create(dataToSend);
        setSuccess('Korisnik uspješno kreiran');
      }
      
      loadUsers();
      setTimeout(() => {
        setShowModal(false);
        setSuccess('');
      }, 1500);
    } catch (error) {
      console.error('User save error:', error);
      setError(formatErrorMessage(error, 'Greška pri spremanju korisnika.'));
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
      console.error('User delete error:', error);
      setError(formatErrorMessage(error, 'Greška pri brisanju korisnika.'));
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
      console.error('User status change error:', error);
      setError(formatErrorMessage(error, 'Greška pri promjeni statusa korisnika.'));
    }
  };

  const handleAddToTeam = async (userId) => {
    try {
      await usersAPI.addToTeam(userId);
      setSuccess('Korisnik uspješno dodan u vaš tim');
      loadUsers();
      loadTeam();
      setTimeout(() => setSuccess(''), 3000);
    } catch (error) {
      console.error('Add to team error:', error);
      setError(formatErrorMessage(error, 'Greška pri dodavanju u tim.'));
    }
  };

  const handleRemoveFromTeam = async (userId) => {
    try {
      await usersAPI.removeFromTeam(userId);
      setSuccess('Korisnik uspješno uklonjen iz tima');
      loadUsers();
      loadTeam();
      setTimeout(() => setSuccess(''), 3000);
    } catch (error) {
      console.error('Remove from team error:', error);
      setError(formatErrorMessage(error, 'Greška pri uklanjanju iz tima.'));
    }
  };

  if (loading) {
    return <div className="loading">Učitavanje...</div>;
  }

  const canCreate = hasPermission('USER_CREATE');
  const canUpdate = hasPermission('USER_UPDATE') || hasPermission('USER_UPDATE_ALL');
  const canUpdateSelf = hasPermission('USER_UPDATE_SELF');
  const canDelete = hasPermission('USER_DELETE');
  const canDeactivate = hasPermission('USER_DEACTIVATE');

  return (
    <div className="users-page">
      <div className="page-header">
        <h1>Korisnici</h1>
        <div style={{display: 'flex', gap: '10px', flexWrap: 'wrap'}}>
          {/* Gumbi za prebacivanje pogleda */}
          {hasPermission('USER_READ_ALL') && (
            <button 
              className={`btn ${viewMode === 'all' ? 'btn-primary' : 'btn-secondary'}`}
              onClick={() => setViewMode('all')}
            >
              Svi korisnici
            </button>
          )}
          {isManager() && teamMembers.length > 0 && (
            <button 
              className={`btn ${viewMode === 'team' ? 'btn-primary' : 'btn-secondary'}`}
              onClick={() => setViewMode('team')}
            >
              Moj tim ({teamMembers.length})
            </button>
          )}
          {!hasPermission('USER_READ_ALL') && (
            <button 
              className={`btn ${viewMode === 'self' ? 'btn-primary' : 'btn-secondary'}`}
              onClick={() => setViewMode('self')}
            >
              Moj profil
            </button>
          )}
          {canCreate && (
            <button className="btn btn-primary" onClick={handleCreate}>
              + Novi korisnik
            </button>
          )}
        </div>
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
              <th>Uloge</th>
              <th>Nadređeni</th>
              <th>Status</th>
              <th>Akcije</th>
            </tr>
          </thead>
          <tbody>
            {(viewMode === 'team' ? teamMembers : users).map(user => (
              <tr key={user.user_id}>
                <td>{user.username}</td>
                <td>{user.first_name || user.full_name?.split(' ')[0]} {user.last_name || user.full_name?.split(' ').slice(1).join(' ')}</td>
                <td>{user.email}</td>
                <td>
                  {user.roles?.map(role => (
                    <span key={role} className="badge badge-info" style={{marginRight: '5px'}}>
                      {role}
                    </span>
                  )) || '-'}
                </td>
                <td>
                  {user.manager_full_name || '-'}
                </td>
                <td>
                  <span className={`badge ${user.is_active ? 'badge-success' : 'badge-danger'}`}>
                    {user.is_active ? 'Aktivan' : 'Neaktivan'}
                  </span>
                </td>
                <td>
                  <div className="action-buttons">
                    {/* Prikaži Uredi ako ima USER_UPDATE ili ako je vlastiti profil */}
                    {(canUpdate || (canUpdateSelf && user.user_id === currentUser?.user_id)) && (
                      <button 
                        className="btn btn-primary btn-sm" 
                        onClick={() => handleEdit(user)}
                      >
                        Uredi
                      </button>
                    )}
                    {canDeactivate && user.user_id !== currentUser?.user_id && (
                      <button 
                        className={`btn ${user.is_active ? 'btn-warning' : 'btn-success'} btn-sm`}
                        onClick={() => handleToggleActive(user.user_id, user.is_active)}
                      >
                        {user.is_active ? 'Deaktiviraj' : 'Aktiviraj'}
                      </button>
                    )}
                    {canDelete && user.user_id !== currentUser?.user_id && (
                      <button 
                        className="btn btn-danger btn-sm"
                        onClick={() => handleDelete(user.user_id)}
                      >
                        Obriši
                      </button>
                    )}
                    {/* Gumb za dodavanje u tim - samo za managere u "Svi korisnici" pogledu */}
                    {isManager() && viewMode === 'all' && 
                     user.user_id !== currentUser?.user_id && 
                     user.manager_id !== currentUser?.user_id && (
                      <button 
                        className="btn btn-info btn-sm"
                        onClick={() => handleAddToTeam(user.user_id)}
                        title="Dodaj ovog korisnika u svoj tim"
                      >
                        + Moj tim
                      </button>
                    )}
                    {/* Gumb za uklanjanje iz tima - samo u pogledu tima */}
                    {isManager() && viewMode === 'team' && (
                      <button 
                        className="btn btn-warning btn-sm"
                        onClick={() => handleRemoveFromTeam(user.user_id)}
                        title="Ukloni iz tima"
                      >
                        Ukloni
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
        <div className="users-modal-overlay">
          <div className="users-modal-content">
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
                  <label>Nadređeni (Manager)</label>
                  <select
                    value={formData.manager_id}
                    onChange={(e) => setFormData({...formData, manager_id: e.target.value})}
                  >
                    <option value="">-- Bez nadrređenog --</option>
                    {users
                      .filter(u => u.is_active && u.user_id !== selectedUser?.user_id)
                      .filter(u => u.roles?.some(r => ['ADMIN', 'MANAGER'].includes(r)))
                      .map(u => (
                        <option key={u.user_id} value={u.user_id}>
                          {u.first_name} {u.last_name} ({u.roles?.join(', ')})
                        </option>
                      ))
                    }
                  </select>
                </div>
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
