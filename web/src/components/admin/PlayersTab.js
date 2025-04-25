import React, { useState } from 'react';
import {
  Table,
  Group,
  Text,
  ActionIcon,
  Tooltip,
  Modal,
  Button,
  Stack,
  Paper,
  Tabs,
  Badge,
  Grid,
  ScrollArea
} from '@mantine/core';
import {
  IconUserCircle,
  IconMapPin,
  IconMessageDots,
  IconBriefcase
} from '@tabler/icons-react';

const PlayersTab = ({ players, adminRank }) => {
  const [selectedPlayer, setSelectedPlayer] = useState(null);
  const [modalOpen, setModalOpen] = useState(false);
  const [modalTab, setModalTab] = useState('info');
  const [processingAction, setProcessingAction] = useState(false);
  
  // Make sure players is always an array
  const safePlayers = Array.isArray(players) ? players : [];
  
  console.log("PlayersTab rendering with players:", safePlayers);
  
  // Function to check if admin has specific permissions
  const hasPermission = (permission) => {
    if (!adminRank) return false;
    
    switch (permission) {
      case 'summon_player':
        return ['moderator', 'administrator', 'management', 'leitung'].includes(adminRank);
      case 'view_inventory':
        return ['moderator', 'administrator', 'management', 'leitung'].includes(adminRank);
      default:
        return false;
    }
  };

  // Function to handle viewing player details
  const handleViewPlayer = (player) => {
    setSelectedPlayer(player);
    setModalOpen(true);
    
    // If we have permission to view inventory and the inventory isn't loaded yet
    if (hasPermission('view_inventory') && !player.inventory) {
      fetch('https://project-sentinel/getPlayerInventory', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
          playerId: player.id
        }),
      });
    }
  };

  // Function to teleport to player
  const handleTeleportToPlayer = (playerId) => {
    setProcessingAction(true);
    
    fetch('https://project-sentinel/teleportToPlayer', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: JSON.stringify({
        playerId: playerId
      }),
    })
    .then(() => {
      setProcessingAction(false);
      setModalOpen(false);
    })
    .catch(error => {
      console.error('Error teleporting to player:', error);
      setProcessingAction(false);
    });
  };

  // Function to summon player to admin
  const handleSummonPlayer = (playerId) => {
    if (!hasPermission('summon_player')) return;
    
    setProcessingAction(true);
    
    fetch('https://project-sentinel/summonPlayer', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: JSON.stringify({
        targetId: playerId
      }),
    })
    .then(() => {
      setProcessingAction(false);
      setModalOpen(false);
    })
    .catch(error => {
      console.error('Error summoning player:', error);
      setProcessingAction(false);
    });
  };

  // Function to send DM to player via Discord
  const handleSendDiscordDM = (player) => {
    // This would open a dialog to send a Discord DM
    // For simplicity, we'll just send a test message
    setProcessingAction(true);
    
    fetch('https://project-sentinel/sendDiscordDM', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: JSON.stringify({
        playerId: player.id,
        message: "You have been contacted by an administrator. Please respond in-game."
      }),
    })
    .then(() => {
      setProcessingAction(false);
      // Could show a success notification here
    })
    .catch(error => {
      console.error('Error sending Discord DM:', error);
      setProcessingAction(false);
    });
  };

  // Render inventory items
  const renderInventory = (inventory) => {
    if (!inventory || inventory.length === 0) {
      return (
        <Text color="dimmed" align="center" my={20}>
          No items in inventory or data not available.
        </Text>
      );
    }

    return (
      <ScrollArea style={{ height: 250 }}>
        <Table striped>
          <thead>
            <tr>
              <th>Item</th>
              <th>Count</th>
            </tr>
          </thead>
          <tbody>
            {inventory.map((item, index) => (
              <tr key={index}>
                <td>{item.label || item.name}</td>
                <td>{item.count}</td>
              </tr>
            ))}
          </tbody>
        </Table>
      </ScrollArea>
    );
  };

  return (
    <>
      <Paper p="md" radius="md">
        <Text size="xl" weight={700} mb="md">Online Players ({safePlayers.length})</Text>
        
        {safePlayers.length === 0 ? (
          <Text color="dimmed" align="center" my={50}>
            No players currently online.
          </Text>
        ) : (
          <Table striped highlightOnHover>
            <thead>
              <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {safePlayers.map((player) => (
                <tr key={player.id}>
                  <td>{player.id}</td>
                  <td>{player.name || "Unknown"}</td>
                  <td>
                    <Group spacing={4}>
                      <Tooltip label="View Player">
                        <ActionIcon onClick={() => handleViewPlayer(player)} color="blue">
                          <IconUserCircle size={16} />
                        </ActionIcon>
                      </Tooltip>
                    </Group>
                  </td>
                </tr>
              ))}
            </tbody>
          </Table>
        )}
      </Paper>

      {/* Player details modal */}
      <Modal
        opened={modalOpen}
        onClose={() => setModalOpen(false)}
        title={<Text size="lg" weight={700}>Player: {selectedPlayer?.name}</Text>}
        size="lg"
      >
        {selectedPlayer && (
          <>
            <Tabs value={modalTab} onTabChange={setModalTab}>
              <Tabs.List>
                <Tabs.Tab value="info" icon={<IconUserCircle size={14} />}>
                  Player Info
                </Tabs.Tab>
                
                {hasPermission('view_inventory') && (
                  <Tabs.Tab value="inventory" icon={<IconBriefcase size={14} />}>
                    Inventory
                  </Tabs.Tab>
                )}
              </Tabs.List>

              <Tabs.Panel value="info" pt="md">
                <Stack spacing="md">
                  <Group position="apart">
                    <Text weight={500}>Player ID:</Text>
                    <Badge size="lg">{selectedPlayer.id}</Badge>
                  </Group>
                  
                  <Group position="apart">
                    <Text weight={500}>Name:</Text>
                    <Text>{selectedPlayer.name}</Text>
                  </Group>
                  
                  <Group position="apart">
                    <Text weight={500}>Identifier:</Text>
                    <Text size="sm" sx={{ wordBreak: 'break-all' }}>{selectedPlayer.identifier}</Text>
                  </Group>
                  
                  <Grid mt="md">
                    <Grid.Col span={4}>
                      <Button
                        leftIcon={<IconMapPin size={16} />}
                        onClick={() => handleTeleportToPlayer(selectedPlayer.id)}
                        fullWidth
                        loading={processingAction}
                      >
                        Teleport to Player
                      </Button>
                    </Grid.Col>
                    
                    {hasPermission('summon_player') && (
                      <Grid.Col span={4}>
                        <Button
                          leftIcon={<IconUserCircle size={16} />}
                          onClick={() => handleSummonPlayer(selectedPlayer.id)}
                          color="green"
                          fullWidth
                          loading={processingAction}
                        >
                          Summon Player
                        </Button>
                      </Grid.Col>
                    )}
                    
                    <Grid.Col span={4}>
                      <Button
                        leftIcon={<IconMessageDots size={16} />}
                        onClick={() => handleSendDiscordDM(selectedPlayer)}
                        color="violet"
                        fullWidth
                        loading={processingAction}
                      >
                        Discord DM
                      </Button>
                    </Grid.Col>
                  </Grid>
                </Stack>
              </Tabs.Panel>
              
              {hasPermission('view_inventory') && (
                <Tabs.Panel value="inventory" pt="md">
                  <Text weight={500} mb="md">Player Inventory:</Text>
                  {renderInventory(selectedPlayer.inventory)}
                </Tabs.Panel>
              )}
            </Tabs>
          </>
        )}
      </Modal>
    </>
  );
};

export default PlayersTab;