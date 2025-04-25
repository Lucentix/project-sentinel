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

  console.log('[React] App rendering, visible:', visible, 'view:', currentView);

  const handleClose = useCallback(() => {
    console.log('[React] Handling close event');
    setVisible(false);
    
    if (currentView === 'report') {
      console.log('[React] Sending closeReportUI event to server');
      fetch('https://project-sentinel/closeReportUI', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({}),
      });
    } else if (currentView === 'admin') {
      console.log('[React] Sending closeAdminPanel event to server');
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
    console.log('[React] Received openReportUI event');
    setCurrentView('report');
    setVisible(true);
  });

  useNuiEvent('openAdminPanel', (data) => {
    console.log('[React] Received openAdminPanel event with data:', data);
    setAdminRank(data.adminRank);
    setCurrentView('admin');
    setVisible(true);
  });

  useEffect(() => {
    const handleEscapeKey = (event) => {
      if (event.key === 'Escape' && visible) {
        console.log('[React] Escape key pressed, closing panel');
        handleClose();
      }
    };

    window.addEventListener('keydown', handleEscapeKey);
    return () => window.removeEventListener('keydown', handleEscapeKey);
  }, [visible, handleClose]);

  // For debugging - remove in production
  useEffect(() => {
    if (process.env.NODE_ENV === 'production') {
      console.log('[React] Development mode detected, setting up debug listeners');
      
      // Debug command to simulate opening admin panel
      const debugOpenAdmin = (e) => {
        if (e.key === 'F8') {
          console.log('[React Debug] Simulating admin panel open with rank: administrator');
          setAdminRank('administrator');
          setCurrentView('admin');
          setVisible(true);
        }
      };
      
      window.addEventListener('keydown', debugOpenAdmin);
      return () => window.removeEventListener('keydown', debugOpenAdmin);
    }
  }, []);

  if (!visible) {
    console.log('[React] App not visible, returning null');
    return null;
  }

  console.log('[React] Rendering app with view:', currentView);
  return (
    <AppContainer className="fade-in">
      {currentView === 'report' && <ReportPanel onClose={handleClose} />}
      {currentView === 'admin' && <AdminPanel adminRank={adminRank} onClose={handleClose} />}
    </AppContainer>
  );
}

export default App;