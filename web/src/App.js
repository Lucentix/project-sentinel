import React, { useState, useEffect, useCallback } from 'react';
import styled from 'styled-components';
import { useNuiEvent } from './hooks/useNuiEvent';
import ReportPanel from './components/report/ReportPanel';
import AdminPanel from './components/admin/AdminPanel';

const AppContainer = styled.div`
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  position: relative;
`;

function App() {
  const [visible, setVisible] = useState(false);
  const [currentView, setCurrentView] = useState(null);
  const [adminRank, setAdminRank] = useState(null);

  const handleClose = useCallback(() => {
    setVisible(false);
    
    if (currentView === 'report') {
      fetch('https://project-sentinel/closeReportUI', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({}),
      });
    } else if (currentView === 'admin') {
      fetch('https://project-sentinel/closeAdminPanel', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({}),
      });
    }
  }, [currentView]);

  useNuiEvent('openReportUI', () => {
    setCurrentView('report');
    setVisible(true);
  });

  useNuiEvent('openAdminPanel', (data) => {
    setAdminRank(data.adminRank);
    setCurrentView('admin');
    setVisible(true);
  });

  useEffect(() => {
    const handleEscapeKey = (event) => {
      if (event.key === 'Escape' && visible) {
        handleClose();
      }
    };

    window.addEventListener('keydown', handleEscapeKey);
    return () => window.removeEventListener('keydown', handleEscapeKey);
  }, [visible, handleClose]);

  if (!visible) return null;

  return (
    <AppContainer className="fade-in">
      {currentView === 'report' && <ReportPanel onClose={handleClose} />}
      {currentView === 'admin' && <AdminPanel adminRank={adminRank} onClose={handleClose} />}
    </AppContainer>
  );
}

export default App;