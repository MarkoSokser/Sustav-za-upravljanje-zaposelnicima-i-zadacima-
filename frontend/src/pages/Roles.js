import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { rolesAPI, usersAPI } from '../services/api';
import './Roles.css';

const Roles = () => {
  const { hasPermission } = useAuth();
  const [roles, setRoles] = useState([]);
  const [permissions, setPermissions] = useState([]);
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  
  const [showAssignModal, setShowAssignModal] = useState(false);
  const [selectedUser, setSelectedUser] = useState('');
  const [selectedRole, setSelectedRole] = useState('');

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [rolesRes, permsRes, usersRes] = await Promise.all([
        rolesAPI.getAll(),
        rolesAPI.getPermissions(),
        usersAPI.getAll(),
      ]);
      
      setRoles(rolesRes.data);
      setPermissions(permsRes.data);
      setUsers(usersRes.data);
    } catch (error) {
      if (error.response?.status === 403) {
        setError('Nemate pristup ovoj stranici. Potrebne su dodatne permisije.');
      } else {
        setError('Greška pri učitavanju podataka');
      }
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const handleAssignRole = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    if (!selectedUser || !selectedRole) {
      setError('Molimo odaberite korisnika i ulogu');
      return;
    }

    try {
      await rolesAPI.assignToUser(parseInt(selectedUser), selectedRole);
      setSuccess('Uloga uspješno dodijeljena');
      loadData();
      setTimeout(() => {
        setShowAssignModal(false);
        setSuccess('');
        setSelectedUser('');
        setSelectedRole('');
      }, 1500);
    } catch (error) {
      // Parsiranje FastAPI validation errors
      let errorMsg = 'Greška pri dodjeli uloge';
      if (error.response?.data?.detail) {
        const detail = error.response.data.detail;
        if (typeof detail === 'string') {
          errorMsg = detail;
        } else if (Array.isArray(detail)) {
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

  const handleRemoveRole = async (userId, roleName) => {
    if (!window.confirm('Jeste li sigurni da želite ukloniti ovu ulogu?')) {
      return;
    }

    try {
      await rolesAPI.removeFromUser(userId, roleName);
      setSuccess('Uloga uspješno uklonjena');
      loadData();
      setTimeout(() => setSuccess(''), 3000);
    } catch (error) {
      const errorMsg = error.response?.data?.detail || 'Greška pri uklanjanju uloge';
      setError(typeof errorMsg === 'string' ? errorMsg : JSON.stringify(errorMsg));
    }
  };

  if (loading) {
    return <div className="loading">Učitavanje...</div>;
  }

  const canAssign = hasPermission('ROLE_ASSIGN');

  return (
    <div className="roles-page">
      <div className="page-header">
        <h1>Uloge i Permisije</h1>
        {canAssign && (
          <button className="btn btn-primary" onClick={() => setShowAssignModal(true)}>
            + Dodijeli ulogu
          </button>
        )}
      </div>

      {error && <div className="error">{error}</div>}
      {success && <div className="success">{success}</div>}

      {/* Pregled uloga */}
      <div className="roles-grid">
        {roles.map(role => (
          <div key={role.role_id} className="card role-card">
            <div className="role-header">
              <h2>{role.name}</h2>
              {role.is_system && <span className="badge badge-warning">Sistemska</span>}
            </div>
            <p>{role.description}</p>
            
            <div className="role-stats">
              <span>👥 {role.user_count} korisnika</span>
              <span>🔑 {role.permissions?.length || 0} permisija</span>
            </div>

            <div className="permissions-list">
              <h4>Permisije:</h4>
              <div className="permissions-tags">
                {role.permissions && role.permissions.length > 0 ? (
                  role.permissions.map((perm, idx) => (
                    <span key={idx} className="badge badge-info">
                      {perm}
                    </span>
                  ))
                ) : (
                  <span className="text-muted">Nema permisija</span>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Korisnici i njihove uloge */}
      <div className="card" style={{marginTop: '30px'}}>
        <h2>Korisnici i njihove uloge</h2>
        <table className="table">
          <thead>
            <tr>
              <th>Korisnik</th>
              <th>Email</th>
              <th>Uloge</th>
              <th>Akcije</th>
            </tr>
          </thead>
          <tbody>
            {users.map(user => (
              <tr key={user.user_id}>
                <td>{user.first_name} {user.last_name}</td>
                <td>{user.email}</td>
                <td>
                  {user.roles && user.roles.length > 0 ? (
                    user.roles.map(roleName => {
                      const role = roles.find(r => r.name === roleName);
                      return role ? (
                        <span 
                          key={role.role_id} 
                          className="badge badge-primary" 
                          style={{marginRight: '5px'}}
                        >
                          {roleName}
                          {canAssign && (
                            <button
                              className="remove-badge"
                              onClick={() => handleRemoveRole(user.user_id, roleName)}
                              title="Ukloni ulogu"
                            >
                              ×
                            </button>
                          )}
                        </span>
                      ) : null;
                    })
                  ) : (
                    <span className="text-muted">Nema uloga</span>
                  )}
                </td>
                <td>
                  {canAssign && (
                    <button 
                      className="btn btn-primary btn-sm"
                      onClick={() => {
                        setSelectedUser(user.user_id.toString());
                        setShowAssignModal(true);
                      }}
                    >
                      Dodijeli ulogu
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Modal za dodjelu uloga */}
      {showAssignModal && (
        <div className="modal">
          <div className="modal-content">
            <div className="modal-header">
              <h2>Dodijeli ulogu korisniku</h2>
              <button className="close" onClick={() => {
                setShowAssignModal(false);
                setSelectedUser('');
                setSelectedRole('');
              }}>&times;</button>
            </div>
            
            <form onSubmit={handleAssignRole}>
              <div className="form-group">
                <label>Korisnik *</label>
                <select
                  value={selectedUser}
                  onChange={(e) => setSelectedUser(e.target.value)}
                  required
                >
                  <option value="">-- Odaberi korisnika --</option>
                  {users.map(user => (
                    <option key={user.user_id} value={user.user_id}>
                      {user.first_name} {user.last_name} ({user.username})
                    </option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label>Uloga *</label>
                <select
                  value={selectedRole}
                  onChange={(e) => setSelectedRole(e.target.value)}
                  required
                >
                  <option value="">-- Odaberi ulogu --</option>
                  {roles.map(role => (
                    <option key={role.role_id} value={role.name}>
                      {role.name} - {role.description}
                    </option>
                  ))}
                </select>
              </div>

              {error && <div className="error">{error}</div>}
              {success && <div className="success">{success}</div>}

              <div className="modal-actions">
                <button 
                  type="button" 
                  className="btn btn-secondary" 
                  onClick={() => {
                    setShowAssignModal(false);
                    setSelectedUser('');
                    setSelectedRole('');
                  }}
                >
                  Odustani
                </button>
                <button type="submit" className="btn btn-primary">
                  Dodijeli
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Roles;
