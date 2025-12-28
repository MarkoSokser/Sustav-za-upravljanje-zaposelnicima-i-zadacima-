import React, { createContext, useState, useContext, useEffect } from 'react';
import { authAPI } from '../services/api';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Provjeri je li korisnik već prijavljen
    const token = localStorage.getItem('token');
    const savedUser = localStorage.getItem('user');
    
    if (token && savedUser && savedUser !== 'undefined' && savedUser !== 'null') {
      try {
        setUser(JSON.parse(savedUser));
      } catch (error) {
        // Nevažeći JSON - očisti storage
        console.error('Invalid user data in localStorage:', error);
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        setLoading(false);
        return;
      }
      
      // Opciono: Validiraj token sa serverom
      authAPI.getCurrentUser()
        .then(response => {
          setUser(response.data);
          localStorage.setItem('user', JSON.stringify(response.data));
        })
        .catch(() => {
          // Token je istekao
          localStorage.removeItem('token');
          localStorage.removeItem('user');
          setUser(null);
        })
        .finally(() => {
          setLoading(false);
        });
    } else {
      setLoading(false);
    }
  }, []);

  const login = async (username, password) => {
    try {
      // Trim username i password da se izbjegnu greške sa razmacima
      const trimmedUsername = username.trim();
      const trimmedPassword = password.trim();
      
      // 1. Login i dohvati token
      const loginResponse = await authAPI.login(trimmedUsername, trimmedPassword);
      const { access_token } = loginResponse.data;
      
      // 2. Spremi token
      localStorage.setItem('token', access_token);
      
      // 3. Dohvati user podatke sa tokenom
      const userResponse = await authAPI.getCurrentUser();
      const userData = userResponse.data;
      
      // 4. Spremi user podatke
      localStorage.setItem('user', JSON.stringify(userData));
      setUser(userData);
      
      return { success: true };
    } catch (error) {
      // Očisti token ako nešto pođe po zlu
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      
      // Izvuci error poruku iz različitih formata
      let errorMsg = 'Greška pri prijavi';
      
      if (error.response?.data?.detail) {
        // FastAPI error format
        if (typeof error.response.data.detail === 'string') {
          errorMsg = error.response.data.detail;
        } else if (Array.isArray(error.response.data.detail)) {
          // Validation errors array
          errorMsg = error.response.data.detail
            .map(err => err.msg || err.message)
            .join(', ');
        }
      } else if (error.message) {
        errorMsg = error.message;
      }
      
      return { success: false, error: errorMsg };
    }
  };

  const logout = async () => {
    try {
      await authAPI.logout();
    } catch (error) {
      console.error('Greška pri odjavi:', error);
    } finally {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      setUser(null);
    }
  };

  const hasPermission = (permission) => {
    if (!user || !user.permissions) return false;
    return user.permissions.includes(permission);
  };

  const hasRole = (roleName) => {
    if (!user || !user.roles) return false;
    // Podrška za array stringova ["ADMIN"] i array objekata [{name: "ADMIN"}]
    if (Array.isArray(user.roles)) {
      return user.roles.some(role => 
        typeof role === 'string' ? role === roleName : role.name === roleName
      );
    }
    return false;
  };

  const isAdmin = () => hasRole('ADMIN');
  const isManager = () => hasRole('MANAGER') || isAdmin();

  const value = {
    user,
    loading,
    login,
    logout,
    hasPermission,
    hasRole,
    isAdmin,
    isManager,
    isAuthenticated: !!user,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth mora biti korišten unutar AuthProvider-a');
  }
  return context;
};
