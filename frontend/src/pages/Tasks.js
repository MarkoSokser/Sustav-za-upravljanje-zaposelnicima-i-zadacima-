import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { tasksAPI, usersAPI } from '../services/api';
import './Tasks.css';

const Tasks = () => {
  const { hasPermission } = useAuth();
  const [tasks, setTasks] = useState([]);
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [selectedTask, setSelectedTask] = useState(null);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  
  // Filteri
  const [statusFilter, setStatusFilter] = useState('');
  const [priorityFilter, setPriorityFilter] = useState('');

  const [formData, setFormData] = useState({
    title: '',
    description: '',
    priority: 'MEDIUM',
    due_date: '',
    assigned_to: '',
  });

  useEffect(() => {
    loadTasks();
    loadUsers();
  }, [statusFilter, priorityFilter]); // eslint-disable-line react-hooks/exhaustive-deps

  const loadTasks = async () => {
    setLoading(true);
    setError('');
    try {
      const params = {};
      if (statusFilter) params.status = statusFilter;
      if (priorityFilter) params.priority = priorityFilter;
      
      const response = await tasksAPI.getAll(params);
      setTasks(response.data);
    } catch (error) {
      if (error.response?.status === 403) {
        setError('Nemate pristup ovoj stranici. Potrebne su dodatne permisije.');
      } else {
        setError('Greška pri učitavanju zadataka');
      }
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const loadUsers = async () => {
    try {
      const response = await usersAPI.getAll(true); // Samo aktivni
      setUsers(response.data);
    } catch (error) {
      console.error('Greška pri učitavanju korisnika:', error);
    }
  };

  const handleCreate = () => {
    setIsEditing(false);
    setSelectedTask(null);
    setFormData({
      title: '',
      description: '',
      priority: 'MEDIUM',
      due_date: '',
      assigned_to: '',
    });
    setShowModal(true);
    setError('');
    setSuccess('');
  };

  const handleEdit = (task) => {
    setIsEditing(true);
    setSelectedTask(task);
    setFormData({
      title: task.title,
      description: task.description || '',
      priority: task.priority,
      due_date: task.due_date ? task.due_date.split('T')[0] : '',
      assigned_to: task.assigned_to || '',
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
      const submitData = {
        ...formData,
        assigned_to: formData.assigned_to ? parseInt(formData.assigned_to) : null,
      };

      if (isEditing) {
        await tasksAPI.update(selectedTask.task_id, submitData);
        setSuccess('Zadatak uspješno ažuriran');
      } else {
        await tasksAPI.create(submitData);
        setSuccess('Zadatak uspješno kreiran');
      }
      
      loadTasks();
      setTimeout(() => {
        setShowModal(false);
        setSuccess('');
      }, 1500);
    } catch (error) {
      // Parsiranje FastAPI validation errors
      let errorMsg = 'Greška pri spremanju zadatka';
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

  const handleDelete = async (taskId) => {
    if (!window.confirm('Jeste li sigurni da želite obrisati ovaj zadatak?')) {
      return;
    }

    try {
      await tasksAPI.delete(taskId);
      setSuccess('Zadatak uspješno obrisan');
      loadTasks();
      setTimeout(() => setSuccess(''), 3000);
    } catch (error) {
      const errorMsg = error.response?.data?.detail || 'Greška pri brisanju zadatka';
      setError(typeof errorMsg === 'string' ? errorMsg : JSON.stringify(errorMsg));
    }
  };

  const handleStatusChange = async (taskId, newStatus) => {
    try {
      await tasksAPI.updateStatus(taskId, newStatus);
      setSuccess('Status uspješno ažuriran');
      loadTasks();
      setTimeout(() => setSuccess(''), 3000);
    } catch (error) {
      setError('Greška pri promjeni statusa');
    }
  };

  const getStatusBadge = (status) => {
    const statusMap = {
      'NEW': 'badge-info',
      'IN_PROGRESS': 'badge-warning',
      'ON_HOLD': 'badge-warning',
      'COMPLETED': 'badge-success',
      'CANCELLED': 'badge-danger'
    };
    return statusMap[status] || 'badge-info';
  };

  const getPriorityBadge = (priority) => {
    const priorityMap = {
      'LOW': 'badge-info',
      'MEDIUM': 'badge-warning',
      'HIGH': 'badge-danger'
    };
    return priorityMap[priority] || 'badge-info';
  };

  if (loading) {
    return <div className="loading">Učitavanje...</div>;
  }

  const canCreate = hasPermission('TASK_CREATE');
  const canUpdate = hasPermission('TASK_UPDATE');
  const canDelete = hasPermission('TASK_DELETE');

  return (
    <div className="tasks-page">
      <div className="page-header">
        <h1>Zadaci</h1>
        {canCreate && (
          <button className="btn btn-primary" onClick={handleCreate}>
            + Novi zadatak
          </button>
        )}
      </div>

      {error && <div className="error">{error}</div>}
      {success && <div className="success">{success}</div>}

      {/* Filteri */}
      <div className="card filters">
        <div className="filter-group">
          <label>Status:</label>
          <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
            <option value="">Svi</option>
            <option value="NEW">Novo</option>
            <option value="IN_PROGRESS">U tijeku</option>
            <option value="ON_HOLD">Na čekanju</option>
            <option value="COMPLETED">Završeno</option>
            <option value="CANCELLED">Otkazano</option>
          </select>
        </div>
        <div className="filter-group">
          <label>Prioritet:</label>
          <select value={priorityFilter} onChange={(e) => setPriorityFilter(e.target.value)}>
            <option value="">Svi</option>
            <option value="LOW">Nizak</option>
            <option value="MEDIUM">Srednji</option>
            <option value="HIGH">Visok</option>
          </select>
        </div>
      </div>

      <div className="card">
        <table className="table">
          <thead>
            <tr>
              <th>Naslov</th>
              <th>Status</th>
              <th>Prioritet</th>
              <th>Dodijeljeno</th>
              <th>Kreirao</th>
              <th>Rok</th>
              <th>Akcije</th>
            </tr>
          </thead>
          <tbody>
            {tasks.map(task => (
              <tr key={task.task_id}>
                <td>
                  <strong>{task.title}</strong>
                  {task.description && (
                    <div style={{fontSize: '12px', color: '#666', marginTop: '5px'}}>
                      {task.description.substring(0, 50)}...
                    </div>
                  )}
                </td>
                <td>
                  {canUpdate ? (
                    <select 
                      value={task.status}
                      onChange={(e) => handleStatusChange(task.task_id, e.target.value)}
                      className="status-select"
                    >
                      <option value="NEW">Novo</option>
                      <option value="IN_PROGRESS">U tijeku</option>
                      <option value="ON_HOLD">Na čekanju</option>
                      <option value="COMPLETED">Završeno</option>
                      <option value="CANCELLED">Otkazano</option>
                    </select>
                  ) : (
                    <span className={`badge ${getStatusBadge(task.status)}`}>
                      {task.status}
                    </span>
                  )}
                </td>
                <td>
                  <span className={`badge ${getPriorityBadge(task.priority)}`}>
                    {task.priority}
                  </span>
                </td>
                <td>{task.assigned_to_name || '-'}</td>
                <td>{task.created_by_name}</td>
                <td>
                  {task.due_date ? (
                    <span className={new Date(task.due_date) < new Date() && task.status !== 'COMPLETED' ? 'overdue' : ''}>
                      {new Date(task.due_date).toLocaleDateString('hr-HR')}
                    </span>
                  ) : '-'}
                </td>
                <td>
                  <div className="action-buttons">
                    {canUpdate && (
                      <button 
                        className="btn btn-primary btn-sm" 
                        onClick={() => handleEdit(task)}
                      >
                        Uredi
                      </button>
                    )}
                    {canDelete && (
                      <button 
                        className="btn btn-danger btn-sm"
                        onClick={() => handleDelete(task.task_id)}
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
              <h2>{isEditing ? 'Uredi zadatak' : 'Novi zadatak'}</h2>
              <button className="close" onClick={() => setShowModal(false)}>&times;</button>
            </div>
            
            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label>Naslov *</label>
                <input
                  type="text"
                  value={formData.title}
                  onChange={(e) => setFormData({...formData, title: e.target.value})}
                  required
                />
              </div>

              <div className="form-group">
                <label>Opis</label>
                <textarea
                  value={formData.description}
                  onChange={(e) => setFormData({...formData, description: e.target.value})}
                />
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Prioritet *</label>
                  <select
                    value={formData.priority}
                    onChange={(e) => setFormData({...formData, priority: e.target.value})}
                    required
                  >
                    <option value="LOW">Nizak</option>
                    <option value="MEDIUM">Srednji</option>
                    <option value="HIGH">Visok</option>
                  </select>
                </div>
                <div className="form-group">
                  <label>Rok</label>
                  <input
                    type="date"
                    value={formData.due_date}
                    onChange={(e) => setFormData({...formData, due_date: e.target.value})}
                  />
                </div>
              </div>

              <div className="form-group">
                <label>Dodijeli korisniku</label>
                <select
                  value={formData.assigned_to}
                  onChange={(e) => setFormData({...formData, assigned_to: e.target.value})}
                >
                  <option value="">-- Nije dodijeljeno --</option>
                  {users.map(u => (
                    <option key={u.user_id} value={u.user_id}>
                      {u.first_name} {u.last_name} ({u.username})
                    </option>
                  ))}
                </select>
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

export default Tasks;
