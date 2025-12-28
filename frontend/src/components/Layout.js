import React from 'react';
import { Outlet, Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import './Layout.css';

const Layout = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const isActive = (path) => {
    return location.pathname === path ? 'active' : '';
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
    </div>
  );
};

export default Layout;
