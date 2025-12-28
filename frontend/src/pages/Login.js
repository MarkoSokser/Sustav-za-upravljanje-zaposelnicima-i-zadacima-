import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import './Login.css';

const Login = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  
  const { login, isAuthenticated } = useAuth();
  const navigate = useNavigate();

  // Ako je već prijavljen, preusmjeri na dashboard
  React.useEffect(() => {
    if (isAuthenticated) {
      navigate('/dashboard');
    }
  }, [isAuthenticated, navigate]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    const result = await login(username, password);
    
    if (result.success) {
      navigate('/dashboard');
    } else {
      // Osiguraj da error bude string, ne objekt
      const errorMsg = typeof result.error === 'string' 
        ? result.error 
        : result.error?.message || 'Greška pri prijavi';
      setError(errorMsg);
    }
    
    setLoading(false);
  };

  return (
    <div className="login-container">
      <div className="login-box">
        <h1>Interni sustav</h1>
        <h2>Upravljanje zaposlenicima i zadacima</h2>
        
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="username">Korisničko ime</label>
            <input
              type="text"
              id="username"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
              disabled={loading}
            />
          </div>

          <div className="form-group">
            <label htmlFor="password">Lozinka</label>
            <input
              type="password"
              id="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              disabled={loading}
            />
          </div>

          {error && <div className="error">{error}</div>}

          <button 
            type="submit" 
            className="btn btn-primary btn-block"
            disabled={loading}
          >
            {loading ? 'Prijava u tijeku...' : 'Prijavi se'}
          </button>
        </form>

        <div className="demo-credentials">
          <h3>Demo pristupni podaci:</h3>
          <p><strong>Admin:</strong> admin / password</p>
          <p><strong>Manager:</strong> ivan_manager / password</p>
          <p><strong>Employee:</strong> marko_dev / password</p>
          <p style={{fontSize: '12px', color: '#999', marginTop: '10px'}}>
            Svi korisnici koriste lozinku: <strong>password</strong>
          </p>
        </div>
      </div>
    </div>
  );
};

export default Login;
