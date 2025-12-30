import React from 'react';
import './TaskDetailsModal.css';

const TaskDetailsModal = ({ task, onClose }) => {
  if (!task) return null;

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
      'HIGH': 'badge-danger',
      'URGENT': 'badge-danger'
    };
    return priorityMap[priority] || 'badge-info';
  };

  const formatDate = (date) => {
    if (!date) return '-';
    return new Date(date).toLocaleString('hr-HR');
  };

  const formatDateOnly = (date) => {
    if (!date) return '-';
    return new Date(date).toLocaleDateString('hr-HR');
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="task-details-modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>{task.title}</h2>
          <button className="close" onClick={onClose}>&times;</button>
        </div>
        
        <div className="modal-body">
          <div className="detail-section">
            <div className="detail-row">
              <div className="detail-item">
                <label>Status:</label>
                <span className={`badge ${getStatusBadge(task.status)}`}>
                  {task.status}
                </span>
              </div>
              <div className="detail-item">
                <label>Prioritet:</label>
                <span className={`badge ${getPriorityBadge(task.priority)}`}>
                  {task.priority}
                </span>
              </div>
            </div>

            <div className="detail-row">
              <div className="detail-item">
                <label>Kreirao:</label>
                <span>{task.creator_name || task.created_by_name || '-'}</span>
              </div>
              <div className="detail-item">
                <label>Dodijeljeno:</label>
                <span>
                  {task.assignee_names && task.assignee_names.length > 0 
                    ? task.assignee_names.join(', ')
                    : (task.assignee_name || task.assigned_to_name || 'Nije dodijeljeno')}
                </span>
              </div>
            </div>

            <div className="detail-row">
              <div className="detail-item">
                <label>Kreirano:</label>
                <span>{formatDate(task.created_at)}</span>
              </div>
              <div className="detail-item">
                <label>Ažurirano:</label>
                <span>{formatDate(task.updated_at)}</span>
              </div>
            </div>

            <div className="detail-row">
              <div className="detail-item">
                <label>Rok izvršenja:</label>
                <span className={task.is_overdue ? 'overdue' : ''}>
                  {formatDateOnly(task.due_date)}
                  {task.is_overdue && <span className="overdue-badge"> ⚠️ Kasni</span>}
                  {task.days_overdue && <span> ({task.days_overdue} dana)</span>}
                </span>
              </div>
              <div className="detail-item">
                <label>Završeno:</label>
                <span>{formatDate(task.completed_at)}</span>
              </div>
            </div>
          </div>

          {task.description && (
            <div className="detail-section">
              <label>Opis:</label>
              <div className="description-box">
                {task.description}
              </div>
            </div>
          )}

          {task.due_status && (
            <div className="detail-section">
              <label>Status roka:</label>
              <span className={`badge ${
                task.due_status === 'OVERDUE' ? 'badge-danger' : 
                task.due_status === 'DUE_SOON' ? 'badge-warning' : 
                'badge-info'
              }`}>
                {task.due_status}
              </span>
            </div>
          )}
        </div>

        <div className="modal-footer">
          <button className="btn btn-secondary" onClick={onClose}>
            Zatvori
          </button>
        </div>
      </div>
    </div>
  );
};

export default TaskDetailsModal;
