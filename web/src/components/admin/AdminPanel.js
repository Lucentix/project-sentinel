import React, { useState, useEffect, useCallback } from 'react';
import styled from 'styled-components';
import { 
  Paper,
  Tabs, 
  Title,
  Group,
  Text,
  ActionIcon,
  Loader
} from '@mantine/core';
import { IconX, IconLayoutDashboard, IconFlag, IconUsers, IconLock } from '@tabler/icons-react';
import DashboardTab from './DashboardTab';
import ReportsTab from './ReportsTab';
import PlayersTab from './PlayersTab';
import PermissionsTab from './PermissionsTab';
import { useNuiEvent } from '../../hooks/useNuiEvent';

const AdminContainer = styled(Paper)`
  width: 80%;
  height: 80%;
  max-width: 1400px;
  max-height: 900px;
  padding: 20px;
  background-color: rgba(28, 28, 36, 0.95);
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.5);
  display: flex;
  flex-direction: column;
  position: relative;
`;

const HeaderBar = styled(Group)`
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
`;

const CloseButton = styled(ActionIcon)`
  position: absolute;
  top: 15px;
  right: 15px;
`;

const AdminPanel = ({ adminRank, onClose }) => {
  console.log('[React] AdminPanel rendering with rank:', adminRank);
  
  const [activeTab, setActiveTab] = useState('dashboard');
  const [serverStats, setServerStats] = useState({ 
    players: { online: 0, max: 32 }, 
    reports: { total: 0, open: 0, inProgress: 0, closed: 0 }
  });
  const [reports, setReports] = useState([]);
  const [players, setPlayers] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  
  const hasPermission = useCallback((tab) => {
    console.log('[React] Checking permission for tab:', tab, 'with rank:', adminRank);
    if (!adminRank) return false;
    
    switch (tab) {
      case 'dashboard':
        return true;
      case 'reports':
        return ['supporter', 'moderator', 'administrator', 'management', 'leitung'].includes(adminRank);
      case 'players':
        return ['moderator', 'administrator', 'management', 'leitung'].includes(adminRank);
      case 'permissions':
        return ['administrator', 'management', 'leitung'].includes(adminRank);
      default:
        return false;
    }
  }, [adminRank]);

  useNuiEvent('receiveServerStats', (data) => {
    console.log('[React] Received server stats:', data);
    if (data && typeof data === 'object') {
      setServerStats(data);
    } else {
      console.error('[React] Invalid server stats received:', data);
    }
  });
  
  useNuiEvent('receiveReports', (data) => {
    console.log('[React] Received reports:', data);
    if (Array.isArray(data)) {
      setReports(data);
    } else {
      console.error('[React] Invalid reports data received:', data);
      setReports([]);
    }
  });
  
  useNuiEvent('receiveOnlinePlayers', (data) => {
    console.log('[React] Received online players:', data);
    if (Array.isArray(data)) {
      setPlayers(data);
    } else {
      console.error('[React] Invalid players data received:', data);
      setPlayers([]);
    }
  });
  
  useNuiEvent('receivePlayerInventory', (data) => {
    console.log('[React] Received player inventory:', data);
    if (data && data.playerId) {
      setPlayers(prevPlayers => {
        if (!Array.isArray(prevPlayers)) return prevPlayers;
        return prevPlayers.map(player => {
          if (player.id === data.playerId) {
            return { ...player, inventory: data.inventory || [] };
          }
          return player;
        });
      });
    }
  });

  useEffect(() => {
    console.log('[React] AdminPanel component mounted with rank:', adminRank);
    if (!adminRank) return;
    
    setIsLoading(true);
    console.log('[React] Fetching initial data...');
    
    console.log('[React] Requesting server stats');
    fetch('https://project-sentinel/getServerStats', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: JSON.stringify({}),
    })
    .then(() => console.log('[React] getServerStats request sent'))
    .catch(err => console.error('[React] Error sending getServerStats request:', err));
    
    if (hasPermission('reports')) {
      console.log('[React] Requesting reports');
      fetch('https://project-sentinel/getReports', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({}),
      })
      .then(() => console.log('[React] getReports request sent'))
      .catch(err => console.error('[React] Error sending getReports request:', err));
    }
    
    if (hasPermission('players')) {
      console.log('[React] Requesting online players');
      fetch('https://project-sentinel/getOnlinePlayers', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({}),
      })
      .then(() => console.log('[React] getOnlinePlayers request sent'))
      .catch(err => console.error('[React] Error sending getOnlinePlayers request:', err));
    }
    
    setTimeout(() => {
      console.log('[React] Finished loading timer, setting isLoading to false');
      setIsLoading(false);
    }, 1500);
    
  }, [adminRank, hasPermission]);

  const getRankColor = () => {
    switch (adminRank) {
      case 'supporter':
        return '#4CAF50';
      case 'moderator':
        return '#2196F3';
      case 'administrator':
        return '#F44336';
      case 'management':
        return '#9C27B0';
      case 'leitung':
        return '#FF9800';
      default:
        return '#757575';
    }
  };
  
  const getRankLabel = () => {
    switch (adminRank) {
      case 'supporter':
        return 'Supporter';
      case 'moderator':
        return 'Moderator';
      case 'administrator':
        return 'Administrator';
      case 'management':
        return 'Management';
      case 'leitung':
        return 'Leitung';
      default:
        return 'Unknown';
    }
  };

  const handleTabChange = (value) => {
    console.log('[React] Changing tab to:', value);
    if (hasPermission(value)) {
      setActiveTab(value);
    } else {
      console.log('[React] Permission denied for tab:', value);
    }
  };

  console.log('[React] Rendering AdminPanel with activeTab:', activeTab, 'isLoading:', isLoading);
  return (
    <AdminContainer className="fade-in">
      <CloseButton onClick={onClose} variant="subtle" color="gray">
        <IconX size={18} />
      </CloseButton>
      
      <HeaderBar position="apart">
        <Title order={2} color="white">Project Sentinel Admin Panel</Title>
        <Group spacing={6}>
          <Text size="sm" color="dimmed">Logged in as:</Text>
          <Text 
            size="sm" 
            weight={700} 
            sx={{ color: getRankColor() }}
          >
            {getRankLabel()}
          </Text>
        </Group>
      </HeaderBar>

      {isLoading ? (
        <Group position="center" sx={{ height: '100%' }}>
          <Loader size="xl" color="blue" variant="dots" />
        </Group>
      ) : (
        <Tabs value={activeTab} onTabChange={handleTabChange} style={{ height: '100%' }}>
          <Tabs.List>
            <Tabs.Tab 
              value="dashboard" 
              icon={<IconLayoutDashboard size={16} />}
            >
              Dashboard
            </Tabs.Tab>
            
            {hasPermission('reports') && (
              <Tabs.Tab 
                value="reports" 
                icon={<IconFlag size={16} />}
              >
                Reports
              </Tabs.Tab>
            )}
            
            {hasPermission('players') && (
              <Tabs.Tab 
                value="players" 
                icon={<IconUsers size={16} />}
              >
                Players
              </Tabs.Tab>
            )}
            
            {hasPermission('permissions') && (
              <Tabs.Tab 
                value="permissions" 
                icon={<IconLock size={16} />}
              >
                Permissions
              </Tabs.Tab>
            )}
          </Tabs.List>

          <Tabs.Panel value="dashboard" pt="md" sx={{ height: 'calc(100% - 42px)', overflowY: 'auto' }}>
            <DashboardTab stats={serverStats} adminRank={adminRank} />
          </Tabs.Panel>
          
          {hasPermission('reports') && (
            <Tabs.Panel value="reports" pt="md" sx={{ height: 'calc(100% - 42px)', overflowY: 'auto' }}>
              <ReportsTab reports={reports} adminRank={adminRank} />
            </Tabs.Panel>
          )}
          
          {hasPermission('players') && (
            <Tabs.Panel value="players" pt="md" sx={{ height: 'calc(100% - 42px)', overflowY: 'auto' }}>
              <PlayersTab players={players} adminRank={adminRank} />
            </Tabs.Panel>
          )}
          
          {hasPermission('permissions') && (
            <Tabs.Panel value="permissions" pt="md" sx={{ height: 'calc(100% - 42px)', overflowY: 'auto' }}>
              <PermissionsTab adminRank={adminRank} />
            </Tabs.Panel>
          )}
        </Tabs>
      )}
    </AdminContainer>
  );
};

export default AdminPanel;