import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { tasksAPI } from '../services/api';
import TaskDetailsModal from '../components/TaskDetailsModal';
import './Dashboard.css';

const Dashboard = () => {
  const { user } = useAuth();
  const [stats, setStats] = useState(null);
  const [myTasks, setMyTasks] = useState([]);
  const [overdueTasks, setOverdueTasks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [selectedTask, setSelectedTask] = useState(null);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    setLoading(true);
    try {
      // Paralelno učitaj sve podatke
      const [statsRes, myTasksRes, overdueRes] = await Promise.all([
        tasksAPI.getStatistics().catch(() => ({ data: null })),
        tasksAPI.getMyTasks().catch(() => ({ data: [] })),
        tasksAPI.getOverdue().catch(() => ({ data: [] })),
      ]);

      setStats(statsRes.data);
      setMyTasks(myTasksRes.data);
      setOverdueTasks(overdueRes.data);
    } catch (error) {
      console.error('Greška pri učitavanju dashboard podataka:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleTaskClick = (task) => {
    setSelectedTask(task);
    setShowDetailsModal(true);
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

  return (
    <div className="dashboard">
      <h1>Dashboard</h1>
      
      <div className="welcome-card card">
        <h2>Dobrodošli, {user?.first_name}!</h2>
        <p>Uloge: {user?.roles?.length > 0 
          ? (typeof user.roles[0] === 'string' 
              ? user.roles.join(', ') 
              : user.roles.map(r => r.name).join(', '))
          : 'Nema uloga'}</p>
      </div>

      {/* Statistike */}
      {stats && (
        <div className="stats-grid">
          <div className="stat-card card">
            <h3>Ukupno zadataka</h3>
            <div className="stat-number">{stats.total_tasks || 0}</div>
          </div>
          <div className="stat-card card">
            <h3>U tijeku</h3>
            <div className="stat-number">{stats.in_progress || 0}</div>
          </div>
          <div className="stat-card card">
            <h3>Završeno</h3>
            <div className="stat-number">{stats.completed || 0}</div>
          </div>
          <div className="stat-card card">
            <h3>Kasni</h3>
            <div className="stat-number">{stats.overdue || 0}</div>
          </div>
        </div>
      )}

      {/* Moji zadaci */}
      <div className="card">
        <h2>Moji zadaci ({myTasks.length})</h2>
        {myTasks.length > 0 ? (
          <table className="table">
            <thead>
              <tr>
                <th>Naslov</th>
                <th>Status</th>
                <th>Prioritet</th>
                <th>Rok</th>
              </tr>
            </thead>
            <tbody>
              {myTasks.slice(0, 5).map(task => (
                <tr 
                  key={task.task_id} 
                  style={{cursor: 'pointer'}} 
                  onClick={() => handleTaskClick(task)}
                  title="Klikni za detalje"
                >
                  <td style={{color: '#667eea', fontWeight: '500'}}>{task.title}</td>
                  <td>
                    <span className={`badge ${getStatusBadge(task.status)}`}>
                      {task.status}
                    </span>
                  </td>
                  <td>
                    <span className={`badge ${getPriorityBadge(task.priority)}`}>
                      {task.priority}
                    </span>
                  </td>
                  <td>{task.due_date ? new Date(task.due_date).toLocaleDateString('hr-HR') : '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <p>Nemate dodijeljenih zadataka.</p>
        )}
      </div>

      {/* Zadaci koji kasne */}
      {overdueTasks.length > 0 && (
        <div className="card">
          <h2>⚠️ Zadaci koji kasne ({overdueTasks.length})</h2>
          <table className="table">
            <thead>
              <tr>
                <th>Naslov</th>
                <th>Dodijeljeno</th>
                <th>Rok</th>
                <th>Kasni (dana)</th>
              </tr>
            </thead>
            <tbody>
              {overdueTasks.slice(0, 5).map(task => (
                <tr 
                  key={task.task_id}
                  style={{cursor: 'pointer'}} 
                  onClick={() => handleTaskClick(task)}
                  title="Klikni za detalje"
                >
                  <td style={{color: '#667eea', fontWeight: '500'}}>{task.title}</td>
                  <td>{task.assigned_to_name || '-'}</td>
                  <td>{new Date(task.due_date).toLocaleDateString('hr-HR')}</td>
                  <td>
                    <span className="badge badge-danger">{task.days_overdue}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Modal za detalje zadatka */}
      {showDetailsModal && selectedTask && (
        <TaskDetailsModal 
          task={selectedTask} 
          onClose={() => setShowDetailsModal(false)} 
        />
      )}
    </div>
  );
};

export default Dashboard;
