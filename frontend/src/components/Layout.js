import React, { useState } from 'react';
import { Outlet, Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { authAPI } from '../services/api';
import './Layout.css';

const Layout = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  
  // State za modal promjene lozinke
  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const [passwordForm, setPasswordForm] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: ''
  });
  const [passwordError, setPasswordError] = useState('');
  const [passwordSuccess, setPasswordSuccess] = useState('');
  const [changingPassword, setChangingPassword] = useState(false);

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const isActive = (path) => {
    return location.pathname === path ? 'active' : '';
  };

  const handlePasswordChange = async (e) => {
    e.preventDefault();
    setPasswordError('');
    setPasswordSuccess('');
    
    // Validacija
    if (passwordForm.newPassword !== passwordForm.confirmPassword) {
      setPasswordError('Nova lozinka i potvrda se ne podudaraju');
      return;
    }
    
    if (passwordForm.newPassword.length < 8) {
      setPasswordError('Nova lozinka mora imati najmanje 8 znakova');
      return;
    }
    
    setChangingPassword(true);
    
    try {
      await authAPI.changePassword(passwordForm.currentPassword, passwordForm.newPassword);
      setPasswordSuccess('Lozinka uspješno promijenjena!');
      setPasswordForm({ currentPassword: '', newPassword: '', confirmPassword: '' });
      setTimeout(() => {
        setShowPasswordModal(false);
        setPasswordSuccess('');
      }, 2000);
    } catch (error) {
      const message = error.response?.data?.detail || 'Greška pri promjeni lozinke';
      setPasswordError(message);
    } finally {
      setChangingPassword(false);
    }
  };

  return (
    <div className="layout">
      <header className="header">
        <div className="header-content">
          <h1>Interni sustav za upravljanje</h1>
          <div className="user-info">
            <span>
              {user?.first_name} {user?.last_name} ({user?.username})
            </span>
            <button 
              onClick={() => setShowPasswordModal(true)} 
              className="btn btn-outline"
              title="Promijeni lozinku"
            >
              🔑
            </button>
            <button onClick={handleLogout} className="btn btn-secondary">
              Odjava
            </button>
          </div>
        </div>
      </header>

      <div className="main-container">
        <nav className="sidebar">
          <ul>
            <li>
              <Link to="/dashboard" className={isActive('/dashboard')}>
                📊 Dashboard
              </Link>
            </li>
            <li>
              <Link to="/users" className={isActive('/users')}>
                👥 Korisnici
              </Link>
            </li>
            <li>
              <Link to="/tasks" className={isActive('/tasks')}>
                📋 Zadaci
              </Link>
            </li>
            <li>
              <Link to="/roles" className={isActive('/roles')}>
                🔐 Uloge i Permisije
              </Link>
            </li>
            <li>
              <Link to="/audit" className={isActive('/audit')}>
                📝 Audit Logovi
              </Link>
            </li>
          </ul>
        </nav>

        <main className="content">
          <Outlet />
        </main>
      </div>
      
      {/* Modal za promjenu lozinke */}
      {showPasswordModal && (
        <div className="modal-overlay" onClick={() => setShowPasswordModal(false)}>
          <div className="modal password-modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h2>🔑 Promjena lozinke</h2>
              <button className="close-btn" onClick={() => setShowPasswordModal(false)}>×</button>
            </div>
            <form onSubmit={handlePasswordChange}>
              <div className="modal-body">
                {passwordError && <div className="error-message">{passwordError}</div>}
                {passwordSuccess && <div className="success-message">{passwordSuccess}</div>}
                
                <div className="form-group">
                  <label>Trenutna lozinka</label>
                  <input
                    type="password"
                    value={passwordForm.currentPassword}
                    onChange={(e) => setPasswordForm({...passwordForm, currentPassword: e.target.value})}
                    required
                  />
                </div>
                
                <div className="form-group">
                  <label>Nova lozinka</label>
                  <input
                    type="password"
                    value={passwordForm.newPassword}
                    onChange={(e) => setPasswordForm({...passwordForm, newPassword: e.target.value})}
                    required
                    minLength={8}
                  />
                  <small className="hint">Najmanje 8 znakova, veliko slovo, malo slovo i broj</small>
                </div>
                
                <div className="form-group">
                  <label>Potvrdi novu lozinku</label>
                  <input
                    type="password"
                    value={passwordForm.confirmPassword}
                    onChange={(e) => setPasswordForm({...passwordForm, confirmPassword: e.target.value})}
                    required
                  />
                </div>
              </div>
              
              <div className="modal-footer">
                <button 
                  type="button" 
                  className="btn btn-secondary"
                  onClick={() => setShowPasswordModal(false)}
                >
                  Odustani
                </button>
                <button 
                  type="submit" 
                  className="btn btn-primary"
                  disabled={changingPassword}
                >
                  {changingPassword ? 'Spremanje...' : 'Promijeni lozinku'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Layout;
