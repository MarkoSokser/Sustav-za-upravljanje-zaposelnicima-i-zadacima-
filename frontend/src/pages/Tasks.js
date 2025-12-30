import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { tasksAPI, usersAPI } from '../services/api';
import TaskDetailsModal from '../components/TaskDetailsModal';
import { formatErrorMessage } from '../utils/errorHandler';
import './Tasks.css';

const Tasks = () => {
  const { hasPermission, user } = useAuth();
  const [tasks, setTasks] = useState([]);
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [selectedTask, setSelectedTask] = useState(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [taskDetails, setTaskDetails] = useState(null);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  // Automatski postavi 'my' ako korisnik nema TASK_READ_ALL permisiju
  const canReadAll = hasPermission('TASK_READ_ALL');
  const canCreate = hasPermission('TASK_CREATE');
  const [viewMode, setViewMode] = useState(canReadAll ? 'all' : 'my'); // 'all', 'my', or 'created'
  
  // Filteri
  const [statusFilter, setStatusFilter] = useState('');
  const [priorityFilter, setPriorityFilter] = useState('');

  const [formData, setFormData] = useState({
    title: '',
    description: '',
    priority: 'MEDIUM',
    due_date: '',
    assigned_to_ids: [], // Promijenjeno u listu za višestruku dodjelu
  });

  useEffect(() => {
    loadTasks();
    loadUsers();
  }, [statusFilter, priorityFilter, viewMode]); // eslint-disable-line react-hooks/exhaustive-deps

  const loadTasks = async () => {
    setLoading(true);
    setError('');
    try {
      let response;
      
      if (viewMode === 'my') {
        // Učitaj samo zadatke dodijeljene meni
        response = await tasksAPI.getMyTasks();
      } else if (viewMode === 'created') {
        // Učitaj zadatke koje sam ja kreirao (filtriraj na frontendu)
        const allTasks = await tasksAPI.getAll({});
        const myCreatedTasks = allTasks.data.filter(task => task.creator_id === user?.user_id);
        response = { data: myCreatedTasks };
      } else if (hasPermission('TASK_READ_ALL')) {
        // Učitaj sve zadatke s filterima
        const params = {};
        if (statusFilter) params.status = statusFilter;
        if (priorityFilter) params.priority = priorityFilter;
        response = await tasksAPI.getAll(params);
      } else {
        // Fallback - učitaj samo moje zadatke
        response = await tasksAPI.getMyTasks();
      }
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
    // Samo ucitaj korisnike ako ima permisiju (za dropdown dodjele zadataka)
    if (!hasPermission('USER_READ_ALL')) {
      // Ako nema permisiju, postavi samo sebe kao opciju
      if (user) {
        setUsers([{
          user_id: user.user_id,
          username: user.username,
          first_name: user.first_name,
          last_name: user.last_name
        }]);
      }
      return;
    }
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
      assigned_to_ids: [], // Prazna lista za višestruku dodjelu
    });
    setShowModal(true);
    setError('');
    setSuccess('');
  };

  const handleViewDetails = (task) => {
    setTaskDetails(task);
    setShowDetailsModal(true);
  };

  const handleEdit = (task) => {
    setIsEditing(true);
    setSelectedTask(task);
    setFormData({
      title: task.title,
      description: task.description || '',
      priority: task.priority,
      due_date: task.due_date ? task.due_date.split('T')[0] : '',
      // Koristi assignee_ids ako postoji, inače stari assigned_to
      assigned_to_ids: task.assignee_ids || (task.assigned_to ? [task.assigned_to] : []),
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
        // Šalje listu assignee-a
        assigned_to_ids: formData.assigned_to_ids.map(id => parseInt(id)),
      };
      
      // Ukloni praznu listu ako nema assignee-a
      if (submitData.assigned_to_ids.length === 0) {
        delete submitData.assigned_to_ids;
      }

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
      console.error('Task save error:', error);
      setError(formatErrorMessage(error));
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
      console.error('Task delete error:', error);
      setError(formatErrorMessage(error));
    }
  };

  const handleStatusChange = async (taskId, newStatus) => {
    try {
      await tasksAPI.updateStatus(taskId, newStatus);
      setSuccess('Status uspješno ažuriran');
      loadTasks();
      setTimeout(() => setSuccess(''), 3000);
    } catch (error) {
      console.error('Status change error:', error);
      setError(formatErrorMessage(error));
      setTimeout(() => setError(''), 5000);
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

  const canUpdate = hasPermission('TASK_UPDATE') || hasPermission('TASK_UPDATE_ANY');
  const canUpdateSelfStatus = hasPermission('TASK_UPDATE_SELF_STATUS');
  const canDelete = hasPermission('TASK_DELETE');
  const canReadSelf = hasPermission('TASK_READ_SELF');

  return (
    <div className="tasks-page">
      <div className="page-header">
        <h1>Zadaci</h1>
        <div style={{display: 'flex', gap: '10px', flexWrap: 'wrap'}}>
          {/* Gumbi za prebacivanje pogleda - prikazuje se ako ima TASK_READ_ALL */}
          {canReadAll && (
            <>
              <button 
                className={`btn ${viewMode === 'all' ? 'btn-primary' : 'btn-secondary'}`}
                onClick={() => setViewMode('all')}
              >
                Svi zadaci
              </button>
              <button 
                className={`btn ${viewMode === 'my' ? 'btn-primary' : 'btn-secondary'}`}
                onClick={() => setViewMode('my')}
              >
                Moji zadaci
              </button>
              {canCreate && (
                <button 
                  className={`btn ${viewMode === 'created' ? 'btn-primary' : 'btn-secondary'}`}
                  onClick={() => setViewMode('created')}
                >
                  Kreirani zadaci
                </button>
              )}
            </>
          )}
          {canCreate && (
            <button className="btn btn-primary" onClick={handleCreate}>
              + Novi zadatak
            </button>
          )}
        </div>
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
                  <strong 
                    style={{cursor: 'pointer', color: '#667eea'}} 
                    onClick={() => handleViewDetails(task)}
                    title="Klikni za detalje"
                  >
                    {task.title}
                  </strong>
                  {task.description && (
                    <div style={{fontSize: '12px', color: '#666', marginTop: '5px'}}>
                      {task.description.substring(0, 50)}...
                    </div>
                  )}
                </td>
                <td>
                  {/* Prikaži dropdown za promjenu statusa ako korisnik ima prava */}
                  {(canUpdate || (canUpdateSelfStatus && task.assignee_ids?.includes(user?.user_id))) && 
                   task.status !== 'COMPLETED' && task.status !== 'CANCELLED' ? (
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
                      {task.status === 'NEW' ? 'Novo' :
                       task.status === 'IN_PROGRESS' ? 'U tijeku' :
                       task.status === 'ON_HOLD' ? 'Na čekanju' :
                       task.status === 'COMPLETED' ? 'Završeno' :
                       task.status === 'CANCELLED' ? 'Otkazano' :
                       task.status}
                    </span>
                  )}
                </td>
                <td>
                  <span className={`badge ${getPriorityBadge(task.priority)}`}>
                    {task.priority}
                  </span>
                </td>
                <td>
                  {/* Prikaz svih dodijeljenih korisnika */}
                  {task.assignee_names && task.assignee_names.length > 0 
                    ? task.assignee_names.join(', ')
                    : (task.assignee_name || '-')}
                </td>
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
                    <button 
                      className="btn btn-info btn-sm" 
                      onClick={() => handleViewDetails(task)}
                      title="Prikaži detalje"
                    >
                      Detalji
                    </button>
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
                <label>Dodijeli korisnicima (možete odabrati više)</label>
                <select
                  multiple
                  value={formData.assigned_to_ids.map(String)}
                  onChange={(e) => {
                    const selectedOptions = Array.from(e.target.selectedOptions, option => option.value);
                    setFormData({...formData, assigned_to_ids: selectedOptions});
                  }}
                  style={{minHeight: '120px'}}
                >
                  {users.map(u => (
                    <option key={u.user_id} value={u.user_id}>
                      {u.first_name} {u.last_name} ({u.username})
                    </option>
                  ))}
                </select>
                <small style={{color: '#666', marginTop: '5px', display: 'block'}}>
                  Držite Ctrl (Windows) ili Cmd (Mac) za odabir više korisnika
                </small>
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

      {/* Modal za detalje zadatka */}
      {showDetailsModal && taskDetails && (
        <TaskDetailsModal 
          task={taskDetails} 
          onClose={() => setShowDetailsModal(false)} 
        />
      )}
    </div>
  );
};

export default Tasks;
