import React, { useState, useEffect, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import { rolesAPI, usersAPI } from '../services/api';
import { formatErrorMessage } from '../utils/errorHandler';
import './Roles.css';

const Roles = () => {
  const { hasPermission, user: currentUser } = useAuth();
  const [roles, setRoles] = useState([]);
  const [permissions, setPermissions] = useState([]);
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  
  const [showAssignModal, setShowAssignModal] = useState(false);
  const [selectedUser, setSelectedUser] = useState('');
  const [selectedRole, setSelectedRole] = useState('');

  // Stanja za individualne permisije
  const [selectedPermissionUser, setSelectedPermissionUser] = useState('');
  const [userDirectPermissions, setUserDirectPermissions] = useState([]);
  const [userEffectivePermissions, setUserEffectivePermissions] = useState([]);
  const [loadingPermissions, setLoadingPermissions] = useState(false);

  // Stanja za kreiranje/uređivanje uloga
  const [showRoleModal, setShowRoleModal] = useState(false);
  const [editingRole, setEditingRole] = useState(null);
  const [roleFormData, setRoleFormData] = useState({ name: '', description: '' });
  
  // Stanja za upravljanje permisijama uloge
  const [showRolePermissionsModal, setShowRolePermissionsModal] = useState(false);
  const [selectedRoleForPermissions, setSelectedRoleForPermissions] = useState(null);

  // Refs za automatsko skrolanje do modala
  const assignModalRef = useRef(null);
  const roleModalRef = useRef(null);
  const rolePermissionsModalRef = useRef(null);

  useEffect(() => {
    loadData();
  }, []);

  // Auto-scroll kada se otvori modal za dodjelu uloge
  useEffect(() => {
    if (showAssignModal && assignModalRef.current) {
      assignModalRef.current.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  }, [showAssignModal]);

  // Auto-scroll kada se otvori modal za kreiranje/uređivanje uloge
  useEffect(() => {
    if (showRoleModal && roleModalRef.current) {
      roleModalRef.current.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  }, [showRoleModal]);

  // Auto-scroll kada se otvori modal za permisije uloge
  useEffect(() => {
    if (showRolePermissionsModal && rolePermissionsModalRef.current) {
      rolePermissionsModalRef.current.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  }, [showRolePermissionsModal]);

  const loadData = async () => {
    setLoading(true);
    try {
      // Ako korisnik nema ROLE_READ permisiju, prikazi samo vlastite uloge
      if (!hasPermission('ROLE_READ')) {
        if (currentUser) {
          // Dohvati vlastite podatke
          const userRes = await usersAPI.getById(currentUser.user_id);
          const userData = userRes.data;
          
          // Prikazi samo vlastite uloge kao pojednostavljene objekte
          const userRoles = (userData.roles || []).map((roleName, idx) => ({
            role_id: idx + 1,
            name: roleName,
            description: '',
            is_system: false,
            permissions: [],
            user_count: 1
          }));
          
          setRoles(userRoles);
          setPermissions([]);
          setUsers([userData]);
        } else {
          setRoles([]);
          setPermissions([]);
          setUsers([]);
        }
      } else {
        const [rolesRes, permsRes, usersRes] = await Promise.all([
          rolesAPI.getAll(),
          rolesAPI.getPermissions(),
          usersAPI.getAll(),
        ]);
        
        setRoles(rolesRes.data);
        setPermissions(permsRes.data);
        setUsers(usersRes.data);
      }
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
      console.error('Role assign error:', error);
      setError(formatErrorMessage(error, 'Greška pri dodjeli uloge.'));
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
      console.error('Role remove error:', error);
      setError(formatErrorMessage(error, 'Greška pri uklanjanju uloge.'));
    }
  };

  // ==================== FUNKCIJE ZA UPRAVLJANJE ULOGAMA ====================
  
  const openCreateRoleModal = () => {
    setEditingRole(null);
    setRoleFormData({ name: '', description: '' });
    setShowRoleModal(true);
  };

  const openEditRoleModal = (role) => {
    setEditingRole(role);
    setRoleFormData({ name: role.name, description: role.description || '' });
    setShowRoleModal(true);
  };

  const closeRoleModal = () => {
    setShowRoleModal(false);
    setEditingRole(null);
    setRoleFormData({ name: '', description: '' });
  };

  const handleSaveRole = async (e) => {
    e.preventDefault();
    setError('');

    try {
      if (editingRole) {
        // Ažuriraj postojeću ulogu
        await rolesAPI.update(editingRole.role_id, roleFormData);
        setSuccess('Uloga uspješno ažurirana');
      } else {
        // Kreiraj novu ulogu
        await rolesAPI.create(roleFormData);
        setSuccess('Uloga uspješno kreirana');
      }
      loadData();
      closeRoleModal();
      setTimeout(() => setSuccess(''), 3000);
    } catch (error) {
      console.error('Role save error:', error);
      setError(formatErrorMessage(error, 'Greška pri spremanju uloge.'));
    }
  };

  const handleDeleteRole = async (role) => {
    if (role.is_system) {
      setError('Sistemske uloge se ne mogu obrisati');
      setTimeout(() => setError(''), 3000);
      return;
    }

    if (role.user_count > 0) {
      if (!window.confirm(`Uloga "${role.name}" ima ${role.user_count} korisnika. Prvo uklonite ulogu sa svih korisnika prije brisanja.`)) {
        return;
      }
      setError('Uloga ima dodijeljene korisnike. Prvo uklonite ulogu sa svih korisnika.');
      setTimeout(() => setError(''), 5000);
      return;
    }

    if (!window.confirm(`Jeste li sigurni da želite obrisati ulogu "${role.name}"?`)) {
      return;
    }

    try {
      await rolesAPI.delete(role.role_id);
      setSuccess('Uloga uspješno obrisana');
      loadData();
      setTimeout(() => setSuccess(''), 3000);
    } catch (error) {
      console.error('Role delete error:', error);
      setError(formatErrorMessage(error, 'Greška pri brisanju uloge.'));
    }
  };

  // ==================== FUNKCIJE ZA PERMISIJE ULOGE ====================

  const openRolePermissionsModal = (role) => {
    setSelectedRoleForPermissions(role);
    setShowRolePermissionsModal(true);
  };

  const closeRolePermissionsModal = () => {
    setShowRolePermissionsModal(false);
    setSelectedRoleForPermissions(null);
  };

  const handleAddPermissionToRole = async (permissionCode) => {
    if (!selectedRoleForPermissions) return;

    try {
      await rolesAPI.addPermissionToRole(selectedRoleForPermissions.role_id, permissionCode);
      setSuccess(`Permisija ${permissionCode} dodana ulozi`);
      // Osvježi podatke
      const rolesRes = await rolesAPI.getAll();
      setRoles(rolesRes.data);
      // Ažuriraj selektiranu ulogu
      const updatedRole = rolesRes.data.find(r => r.role_id === selectedRoleForPermissions.role_id);
      if (updatedRole) setSelectedRoleForPermissions(updatedRole);
      setTimeout(() => setSuccess(''), 2000);
    } catch (error) {
      setError(formatErrorMessage(error, 'Greška pri dodavanju permisije'));
    }
  };

  const handleRemovePermissionFromRole = async (permissionCode) => {
    if (!selectedRoleForPermissions) return;

    try {
      await rolesAPI.removePermissionFromRole(selectedRoleForPermissions.role_id, permissionCode);
      setSuccess(`Permisija ${permissionCode} uklonjena s uloge`);
      // Osvježi podatke
      const rolesRes = await rolesAPI.getAll();
      setRoles(rolesRes.data);
      // Ažuriraj selektiranu ulogu
      const updatedRole = rolesRes.data.find(r => r.role_id === selectedRoleForPermissions.role_id);
      if (updatedRole) setSelectedRoleForPermissions(updatedRole);
      setTimeout(() => setSuccess(''), 2000);
    } catch (error) {
      setError(formatErrorMessage(error, 'Greška pri uklanjanju permisije'));
    }
  };

  // Funkcije za individualne permisije
  const loadUserPermissions = async (userId) => {
    if (!userId) {
      setUserDirectPermissions([]);
      setUserEffectivePermissions([]);
      return;
    }

    setLoadingPermissions(true);
    try {
      const [directRes, effectiveRes] = await Promise.all([
        rolesAPI.getUserDirectPermissions(userId),
        rolesAPI.getUserEffectivePermissions(userId)
      ]);
      setUserDirectPermissions(directRes.data);
      setUserEffectivePermissions(effectiveRes.data);
    } catch (error) {
      console.error('Error loading user permissions:', error);
      setError(formatErrorMessage(error, 'Greška pri učitavanju permisija korisnika'));
    } finally {
      setLoadingPermissions(false);
    }
  };

  const handleUserPermissionSelect = (userId) => {
    setSelectedPermissionUser(userId);
    if (userId) {
      loadUserPermissions(parseInt(userId));
    } else {
      setUserDirectPermissions([]);
      setUserEffectivePermissions([]);
    }
  };

  const handleGrantPermission = async (permissionCode) => {
    if (!selectedPermissionUser) return;
    
    try {
      await rolesAPI.assignPermissionToUser(parseInt(selectedPermissionUser), permissionCode, { granted: true });
      setSuccess(`Permisija ${permissionCode} uspješno dodijeljena`);
      loadUserPermissions(parseInt(selectedPermissionUser));
      setTimeout(() => setSuccess(''), 3000);
    } catch (error) {
      setError(formatErrorMessage(error, 'Greška pri dodjeli permisije'));
    }
  };

  const handleDenyPermission = async (permissionCode) => {
    if (!selectedPermissionUser) return;
    
    try {
      await rolesAPI.assignPermissionToUser(parseInt(selectedPermissionUser), permissionCode, { granted: false });
      setSuccess(`Permisija ${permissionCode} uspješno zabranjena`);
      loadUserPermissions(parseInt(selectedPermissionUser));
      setTimeout(() => setSuccess(''), 3000);
    } catch (error) {
      setError(formatErrorMessage(error, 'Greška pri zabrani permisije'));
    }
  };

  const handleResetPermission = async (permissionCode) => {
    if (!selectedPermissionUser) return;
    
    try {
      await rolesAPI.removePermissionFromUser(parseInt(selectedPermissionUser), permissionCode);
      setSuccess(`Permisija ${permissionCode} vraćena na default iz uloge`);
      loadUserPermissions(parseInt(selectedPermissionUser));
      setTimeout(() => setSuccess(''), 3000);
    } catch (error) {
      setError(formatErrorMessage(error, 'Greška pri resetiranju permisije'));
    }
  };

  // Grupiraj permisije po kategoriji
  const getPermissionsByCategory = () => {
    const grouped = {};
    permissions.forEach(perm => {
      if (!grouped[perm.category]) {
        grouped[perm.category] = [];
      }
      grouped[perm.category].push(perm);
    });
    return grouped;
  };

  // Dohvati status permisije za korisnika
  const getPermissionStatus = (permissionCode) => {
    const directPerm = userDirectPermissions.find(p => p.permission_code === permissionCode);
    if (directPerm) {
      return directPerm.granted ? 'granted' : 'denied';
    }
    
    const effectivePerm = userEffectivePermissions.find(p => p.permission_code === permissionCode);
    if (effectivePerm) {
      return 'from-role';
    }
    
    return 'none';
  };

  if (loading) {
    return <div className="loading">Učitavanje...</div>;
  }

  const canAssign = hasPermission('ROLE_ASSIGN');
  const canCreate = hasPermission('ROLE_CREATE');
  const canUpdate = hasPermission('ROLE_UPDATE');
  const canDelete = hasPermission('ROLE_DELETE');

  return (
    <div className="roles-page">
      <div className="page-header">
        <h1>Uloge i Permisije</h1>
        <div className="header-actions">
          {canCreate && (
            <button className="btn btn-success" onClick={openCreateRoleModal}>
              + Nova uloga
            </button>
          )}
          {canAssign && (
            <button className="btn btn-primary" onClick={() => setShowAssignModal(true)}>
              + Dodijeli ulogu
            </button>
          )}
        </div>
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
              <span>🔑 {role.permissions ? [...new Set(role.permissions)].length : 0} permisija</span>
            </div>

            <div className="permissions-list">
              <h4>Permisije:</h4>
              <div className="permissions-tags">
                {role.permissions && role.permissions.length > 0 ? (
                  [...new Set(role.permissions)].map((perm, idx) => (
                    <span key={idx} className="badge badge-info">
                      {perm}
                    </span>
                  ))
                ) : (
                  <span className="text-muted">Nema permisija</span>
                )}
              </div>
            </div>

            {/* Akcije za upravljanje ulogom */}
            {(canUpdate || canDelete) && (
              <div className="role-actions">
                {canUpdate && (
                  <>
                    <button 
                      className="btn btn-secondary btn-sm"
                      onClick={() => openEditRoleModal(role)}
                      title="Uredi ulogu"
                    >
                      ✏️ Uredi
                    </button>
                    <button 
                      className="btn btn-info btn-sm"
                      onClick={() => openRolePermissionsModal(role)}
                      title="Upravljaj permisijama"
                    >
                      🔑 Permisije
                    </button>
                  </>
                )}
                {canDelete && !role.is_system && (
                  <button 
                    className="btn btn-danger btn-sm"
                    onClick={() => handleDeleteRole(role)}
                    title="Obriši ulogu"
                    disabled={role.user_count > 0}
                  >
                    🗑️ Obriši
                  </button>
                )}
              </div>
            )}
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

      {/* Sekcija za individualne permisije korisnika */}
      {canAssign && (
        <div className="card user-permissions-section" style={{marginTop: '30px'}}>
          <h2>🔐 Individualne permisije korisnika</h2>
          <p style={{color: '#666', marginBottom: '20px'}}>
            Ovdje možete dodijeliti ili zabraniti specifične permisije pojedinom korisniku, 
            neovisno o ulogama koje ima. Direktna dodjela ima prioritet nad ulogama.
          </p>
          
          <div className="legend">
            <div className="legend-item">
              <span className="legend-dot granted"></span>
              <span>Direktno dodijeljena</span>
            </div>
            <div className="legend-item">
              <span className="legend-dot denied"></span>
              <span>Direktno zabranjena</span>
            </div>
            <div className="legend-item">
              <span className="legend-dot role"></span>
              <span>Iz uloge</span>
            </div>
            <div className="legend-item">
              <span className="legend-dot none"></span>
              <span>Nema permisiju</span>
            </div>
          </div>

          <div className="user-select-row">
            <label><strong>Odaberi korisnika:</strong></label>
            <select 
              value={selectedPermissionUser} 
              onChange={(e) => handleUserPermissionSelect(e.target.value)}
            >
              <option value="">-- Odaberi korisnika za uređivanje permisija --</option>
              {users.filter(u => !u.roles?.includes('ADMIN')).map(user => (
                <option key={user.user_id} value={user.user_id}>
                  {user.first_name} {user.last_name} ({user.username}) - {user.roles?.join(', ') || 'Bez uloge'}
                </option>
              ))}
            </select>
          </div>

          {loadingPermissions && <div className="loading">Učitavanje permisija...</div>}

          {selectedPermissionUser && !loadingPermissions && (
            <div className="permissions-grid">
              {Object.entries(getPermissionsByCategory()).map(([category, categoryPermissions]) => (
                <div key={category} className="permission-category-card">
                  <h4>📁 {category}</h4>
                  {categoryPermissions.map(perm => {
                    const status = getPermissionStatus(perm.code);
                    return (
                      <div key={perm.code} className="permission-item">
                        <div className="permission-info">
                          <div className="permission-code">{perm.code}</div>
                          <div className="permission-name">{perm.name}</div>
                        </div>
                        <div className="current-status">
                          <span className={`status-badge ${status}`}>
                            {status === 'granted' && '✓ Dodijeljena'}
                            {status === 'denied' && '✗ Zabranjena'}
                            {status === 'from-role' && '↪ Iz uloge'}
                            {status === 'none' && '○ Nema'}
                          </span>
                        </div>
                        <div className="permission-actions">
                          {status !== 'granted' && (
                            <button 
                              className="btn-grant" 
                              onClick={() => handleGrantPermission(perm.code)}
                              title="Dodijeli permisiju"
                            >
                              ✓
                            </button>
                          )}
                          {status !== 'denied' && (
                            <button 
                              className="btn-deny" 
                              onClick={() => handleDenyPermission(perm.code)}
                              title="Zabrani permisiju"
                            >
                              ✗
                            </button>
                          )}
                          {(status === 'granted' || status === 'denied') && (
                            <button 
                              className="btn-reset" 
                              onClick={() => handleResetPermission(perm.code)}
                              title="Vrati na default iz uloge"
                            >
                              ↺
                            </button>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              ))}
            </div>
          )}

          {selectedPermissionUser && !loadingPermissions && permissions.length === 0 && (
            <p className="text-muted">Nema dostupnih permisija za uređivanje.</p>
          )}
        </div>
      )}

      {/* Modal za dodjelu uloga */}
      {showAssignModal && (
        <div className="modal" ref={assignModalRef}>
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

      {/* Modal za kreiranje/uređivanje uloge */}
      {showRoleModal && (
        <div className="modal" ref={roleModalRef}>
          <div className="modal-content">
            <div className="modal-header">
              <h2>{editingRole ? 'Uredi ulogu' : 'Nova uloga'}</h2>
              <button className="close" onClick={closeRoleModal}>&times;</button>
            </div>
            
            <form onSubmit={handleSaveRole}>
              <div className="form-group">
                <label>Naziv uloge *</label>
                <input
                  type="text"
                  value={roleFormData.name}
                  onChange={(e) => setRoleFormData({...roleFormData, name: e.target.value})}
                  placeholder="npr. SUPERVISOR"
                  required
                  disabled={editingRole?.is_system}
                />
                {editingRole?.is_system && (
                  <small className="text-muted">Sistemske uloge ne mogu promijeniti ime</small>
                )}
              </div>

              <div className="form-group">
                <label>Opis</label>
                <textarea
                  value={roleFormData.description}
                  onChange={(e) => setRoleFormData({...roleFormData, description: e.target.value})}
                  placeholder="Opis uloge i njenih ovlasti..."
                  rows={3}
                />
              </div>

              {error && <div className="error">{error}</div>}
              {success && <div className="success">{success}</div>}

              <div className="modal-actions">
                <button type="button" className="btn btn-secondary" onClick={closeRoleModal}>
                  Odustani
                </button>
                <button type="submit" className="btn btn-primary">
                  {editingRole ? 'Spremi promjene' : 'Kreiraj ulogu'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal za upravljanje permisijama uloge */}
      {showRolePermissionsModal && selectedRoleForPermissions && (
        <div className="modal modal-large" ref={rolePermissionsModalRef}>
          <div className="modal-content modal-content-large">
            <div className="modal-header">
              <h2>🔑 Permisije uloge: {selectedRoleForPermissions.name}</h2>
              <button className="close" onClick={closeRolePermissionsModal}>&times;</button>
            </div>
            
            <div className="role-permissions-manager">
              <p className="modal-description">
                Odaberite koje permisije ova uloga ima. Svi korisnici s ovom ulogom 
                automatski dobivaju označene permisije.
              </p>

              {error && <div className="error">{error}</div>}
              {success && <div className="success">{success}</div>}

              <div className="permissions-grid">
                {Object.entries(getPermissionsByCategory()).map(([category, categoryPermissions]) => (
                  <div key={category} className="permission-category-card">
                    <h4>📁 {category}</h4>
                    {categoryPermissions.map(perm => {
                      const roleHasPermission = selectedRoleForPermissions.permissions?.includes(perm.code);
                      return (
                        <div key={perm.code} className="permission-item">
                          <div className="permission-info">
                            <div className="permission-code">{perm.code}</div>
                            <div className="permission-name">{perm.name}</div>
                          </div>
                          <div className="permission-toggle">
                            <label className="toggle-switch">
                              <input
                                type="checkbox"
                                checked={roleHasPermission}
                                onChange={() => {
                                  if (roleHasPermission) {
                                    handleRemovePermissionFromRole(perm.code);
                                  } else {
                                    handleAddPermissionToRole(perm.code);
                                  }
                                }}
                              />
                              <span className="toggle-slider"></span>
                            </label>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                ))}
              </div>

              <div className="modal-actions">
                <button className="btn btn-secondary" onClick={closeRolePermissionsModal}>
                  Zatvori
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Roles;
