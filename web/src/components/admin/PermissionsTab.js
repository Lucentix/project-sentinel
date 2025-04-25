import React, { useState, useEffect } from 'react';
import {
  Paper,
  Text,
  Group,
  Button,
  Table,
  Select,
  TextInput,
  Modal,
  Stack,
  Badge,
  ActionIcon,
  Tooltip
} from '@mantine/core';
import {
  IconUserPlus,
  IconEdit,
  IconSearch
} from '@tabler/icons-react';

const PermissionsTab = ({ adminRank }) => {
  const [adminUsers, setAdminUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  
  // Form state
  const [identifier, setIdentifier] = useState('');
  const [rank, setRank] = useState('supporter');
  const [processing, setProcessing] = useState(false);
  
  // Fetch admin users on component mount
  useEffect(() => {
    fetch('https://project-sentinel/getAdminUsers', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: JSON.stringify({}),
    })
    .then(response => response.json())
    .then(response => {
      setAdminUsers(response || []);
      setLoading(false);
    })
    .catch(error => {
      console.error('Error fetching admin users:', error);
      setLoading(false);
    });
  }, []);
  
  // Filter admin users based on search term
  const filteredAdmins = adminUsers.filter(admin => 
    admin.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
    admin.identifier.toLowerCase().includes(searchTerm.toLowerCase()) ||
    admin.rank.toLowerCase().includes(searchTerm.toLowerCase())
  );
  
  // Handle opening the add admin modal
  const handleOpenAddModal = () => {
    setEditMode(false);
    setIdentifier('');
    setRank('supporter');
    setModalOpen(true);
  };
  
  // Handle opening the edit admin modal
  const handleOpenEditModal = (admin) => {
    setEditMode(true);
    setIdentifier(admin.identifier);
    setRank(admin.rank);
    setModalOpen(true);
  };
  
  // Handle adding or updating admin ranks
  const handleSubmit = () => {
    if (!identifier.trim()) return;
    
    setProcessing(true);
    
    fetch('https://project-sentinel/updatePlayerRank', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: JSON.stringify({
        targetIdentifier: identifier,
        newRank: rank
      }),
    })
    .then(() => {
      setProcessing(false);
      setModalOpen(false);
      
      // Update local state
      if (editMode) {
        // Update existing user
        setAdminUsers(prevUsers => prevUsers.map(user => 
          user.identifier === identifier ? {...user, rank} : user
        ));
      } else {
        // Add new user (in a real app, we would get more info from the server)
        setAdminUsers(prevUsers => [...prevUsers, {
          identifier,
          rank,
          name: "Unknown", // This would be updated when proper data is fetched
          assignedBy: "Current Admin",
          updatedAt: new Date().toISOString()
        }]);
      }
    })
    .catch(error => {
      console.error('Error updating player rank:', error);
      setProcessing(false);
    });
  };
  
  // Function to get rank label and color
  const getRankInfo = (adminRank) => {
    switch (adminRank) {
      case 'supporter':
        return { label: 'Supporter', color: '#4CAF50' };
      case 'moderator':
        return { label: 'Moderator', color: '#2196F3' };
      case 'administrator':
        return { label: 'Administrator', color: '#F44336' };
      case 'management':
        return { label: 'Management', color: '#9C27B0' };
      case 'leitung':
        return { label: 'Leitung', color: '#FF9800' };
      default:
        return { label: adminRank, color: '#757575' };
    }
  };
  
  // Format date
  const formatDate = (dateString) => {
    if (!dateString) return 'Unknown';
    return new Date(dateString).toLocaleString();
  };

  return (
    <>
      <Paper p="md" radius="md">
        <Group position="apart" mb="md">
          <Text size="xl" weight={700}>Admin Permissions</Text>
          <Button
            leftIcon={<IconUserPlus size={16} />}
            onClick={handleOpenAddModal}
          >
            Add Admin
          </Button>
        </Group>
        
        <TextInput
          placeholder="Search by name, identifier, or rank"
          icon={<IconSearch size={16} />}
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.currentTarget.value)}
          mb="md"
        />
        
        {loading ? (
          <Text color="dimmed" align="center" my={50}>
            Loading admin users...
          </Text>
        ) : filteredAdmins.length === 0 ? (
          <Text color="dimmed" align="center" my={50}>
            No admin users found.
          </Text>
        ) : (
          <Table striped highlightOnHover>
            <thead>
              <tr>
                <th>Name</th>
                <th>Rank</th>
                <th>Assigned By</th>
                <th>Last Updated</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredAdmins.map((admin) => {
                const rankInfo = getRankInfo(admin.rank);
                return (
                  <tr key={admin.identifier}>
                    <td>{admin.name}</td>
                    <td>
                      <Badge 
                        color={rankInfo.color} 
                        variant="dot"
                        size="lg"
                        sx={{ color: rankInfo.color }}
                      >
                        {rankInfo.label}
                      </Badge>
                    </td>
                    <td>{admin.assignedBy || 'Unknown'}</td>
                    <td>{formatDate(admin.updatedAt)}</td>
                    <td>
                      <Tooltip label="Edit Permissions">
                        <ActionIcon onClick={() => handleOpenEditModal(admin)} color="blue">
                          <IconEdit size={16} />
                        </ActionIcon>
                      </Tooltip>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </Table>
        )}
      </Paper>
      
      {/* Add/Edit Admin Modal */}
      <Modal
        opened={modalOpen}
        onClose={() => setModalOpen(false)}
        title={<Text size="lg" weight={700}>{editMode ? 'Edit Admin Rank' : 'Add New Admin'}</Text>}
      >
        <Stack spacing="md">
          <TextInput
            label="Player Identifier"
            placeholder="Enter player identifier (e.g., license:1234567890...)"
            value={identifier}
            onChange={(e) => setIdentifier(e.currentTarget.value)}
            disabled={editMode}
            required
          />
          
          <Select
            label="Admin Rank"
            value={rank}
            onChange={setRank}
            data={[
              { value: 'supporter', label: 'Supporter' },
              { value: 'moderator', label: 'Moderator' },
              { value: 'administrator', label: 'Administrator' },
              { value: 'management', label: 'Management' },
              { value: 'leitung', label: 'Leitung' },
            ]}
            required
          />
          
          <Group position="right" mt="md">
            <Button variant="outline" onClick={() => setModalOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleSubmit} loading={processing}>
              {editMode ? 'Update' : 'Add'}
            </Button>
          </Group>
        </Stack>
      </Modal>
    </>
  );
};

export default PermissionsTab;