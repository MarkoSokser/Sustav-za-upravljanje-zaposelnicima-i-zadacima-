import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { auditAPI } from '../services/api';
import './AuditLogs.css';

const AuditLogs = () => {
  const { hasPermission } = useAuth();
  const [auditLogs, setAuditLogs] = useState([]);
  const [loginEvents, setLoginEvents] = useState([]);
  const [activeTab, setActiveTab] = useState('audit'); // 'audit' or 'login'
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  // Filteri za audit logove
  const [entityFilter, setEntityFilter] = useState('');
  const [actionFilter, setActionFilter] = useState('');

  useEffect(() => {
    if (activeTab === 'audit') {
      loadAuditLogs();
    } else {
      loadLoginEvents();
    }
  }, [activeTab, entityFilter, actionFilter]);

  const loadAuditLogs = async () => {
    setLoading(true);
    try {
      const params = {
        limit: 100,
      };
      if (entityFilter) params.entity_name = entityFilter;
      if (actionFilter) params.action = actionFilter;

      const response = await auditAPI.getLogs(params);
      setAuditLogs(response.data);
    } catch (error) {
      setError('Greška pri učitavanju audit logova');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const loadLoginEvents = async () => {
    setLoading(true);
    try {
      const response = await auditAPI.getLoginEvents({ limit: 100 });
      setLoginEvents(response.data);
    } catch (error) {
      setError('Greška pri učitavanju login evenata');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const getActionBadge = (action) => {
    const actionMap = {
      'INSERT': 'badge-success',
      'UPDATE': 'badge-warning',
      'DELETE': 'badge-danger',
    };
    return actionMap[action] || 'badge-info';
  };

  const formatTimestamp = (timestamp) => {
    return new Date(timestamp).toLocaleString('hr-HR');
  };

  const formatJSON = (data) => {
    try {
      return JSON.stringify(data, null, 2);
    } catch {
      return String(data);
    }
  };

  if (!hasPermission('AUDIT_READ_ALL')) {
    return (
      <div className="container">
        <h2>Nemate pristup audit logovima</h2>
        <p>Za pristup ovoj stranici potrebna je permisija AUDIT_READ_ALL.</p>
      </div>
    );
  }

  if (loading) {
    return <div className="loading">Učitavanje...</div>;
  }

  return (
    <div className="audit-page">
      <h1>Audit Logovi</h1>

      {error && <div className="error">{error}</div>}

      {/* Tabovi */}
      <div className="tabs">
        <button 
          className={`tab ${activeTab === 'audit' ? 'active' : ''}`}
          onClick={() => setActiveTab('audit')}
        >
          📝 Audit Logovi ({auditLogs.length})
        </button>
        <button 
          className={`tab ${activeTab === 'login' ? 'active' : ''}`}
          onClick={() => setActiveTab('login')}
        >
          🔑 Login Eventi ({loginEvents.length})
        </button>
      </div>

      {/* Audit logovi */}
      {activeTab === 'audit' && (
        <>
          {/* Filteri */}
          <div className="card filters">
            <div className="filter-group">
              <label>Entitet:</label>
              <select value={entityFilter} onChange={(e) => setEntityFilter(e.target.value)}>
                <option value="">Svi</option>
                <option value="users">Korisnici</option>
                <option value="tasks">Zadaci</option>
                <option value="user_roles">Korisničke uloge</option>
              </select>
            </div>
            <div className="filter-group">
              <label>Akcija:</label>
              <select value={actionFilter} onChange={(e) => setActionFilter(e.target.value)}>
                <option value="">Sve</option>
                <option value="INSERT">INSERT</option>
                <option value="UPDATE">UPDATE</option>
                <option value="DELETE">DELETE</option>
              </select>
            </div>
          </div>

          <div className="card">
            <div className="audit-list">
              {auditLogs.map(log => (
                <div key={log.log_id} className="audit-item">
                  <div className="audit-header">
                    <div>
                      <span className={`badge ${getActionBadge(log.action)}`}>
                        {log.action}
                      </span>
                      <strong>{log.entity_name}</strong>
                      {log.entity_id && <span className="entity-id">#{log.entity_id}</span>}
                    </div>
                    <div className="audit-meta">
                      <span>👤 {log.changed_by_name}</span>
                      <span>🕐 {formatTimestamp(log.changed_at)}</span>
                    </div>
                  </div>
                  
                  {log.old_value && (
                    <details className="audit-details">
                      <summary>Stara vrijednost</summary>
                      <pre>{formatJSON(log.old_value)}</pre>
                    </details>
                  )}
                  
                  {log.new_value && (
                    <details className="audit-details">
                      <summary>Nova vrijednost</summary>
                      <pre>{formatJSON(log.new_value)}</pre>
                    </details>
                  )}
                </div>
              ))}
              
              {auditLogs.length === 0 && (
                <p className="text-muted">Nema audit logova za prikaz.</p>
              )}
            </div>
          </div>
        </>
      )}

      {/* Login eventi */}
      {activeTab === 'login' && (
        <div className="card">
          <table className="table">
            <thead>
              <tr>
                <th>Korisnik</th>
                <th>Email</th>
                <th>IP Adresa</th>
                <th>Uspješno</th>
                <th>Vrijeme</th>
              </tr>
            </thead>
            <tbody>
              {loginEvents.map(event => (
                <tr key={event.event_id}>
                  <td>{event.username}</td>
                  <td>{event.user_email || '-'}</td>
                  <td>
                    <code>{event.ip_address || '-'}</code>
                  </td>
                  <td>
                    <span className={`badge ${event.successful ? 'badge-success' : 'badge-danger'}`}>
                      {event.successful ? '✓ Uspješno' : '✗ Neuspješno'}
                    </span>
                  </td>
                  <td>{formatTimestamp(event.attempted_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
          
          {loginEvents.length === 0 && (
            <p className="text-muted">Nema login evenata za prikaz.</p>
          )}
        </div>
      )}
    </div>
  );
};

export default AuditLogs;
