import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const ProtectedRoute = ({ children, requiredPermission = null }) => {
  const { isAuthenticated, loading, hasPermission } = useAuth();

  if (loading) {
    return <div className="loading">Učitavanje...</div>;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (requiredPermission && !hasPermission(requiredPermission)) {
    return <div className="container"><h2>Nemate pristup ovoj stranici</h2></div>;
  }

  return children;
};

export default ProtectedRoute;
