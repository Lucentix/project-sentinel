import React from 'react';
import { 
  Grid, 
  Paper, 
  Title, 
  Text, 
  Group,
  RingProgress,
  Stack,
  Divider
} from '@mantine/core';
import { 
  IconUsers, 
  IconFlag,
  IconClipboardCheck,
  IconAlertCircle
} from '@tabler/icons-react';
import { PieChart, Pie, Cell, ResponsiveContainer, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';

const DashboardTab = ({ stats }) => {
  console.log("DashboardTab rendering with stats:", JSON.stringify(stats));
  
  if (!stats || typeof stats !== 'object') {
    return (
      <Text color="dimmed" align="center" mt={50}>
        Loading server statistics...
      </Text>
    );
  }

  // Ensure all nested objects and properties exist with proper defaults
  const players = stats.players || { online: 0, max: 32 };
  const reports = stats.reports || { total: 0, open: 0, inProgress: 0, closed: 0 };
  const server = stats.server || { name: "Unknown", uptime: 0, version: "1.0.0" };
  
  console.log("Processing stats:", {
    players: players,
    reports: reports,
    server: server
  });
  
  // Calculate report percentage safely
  const totalReports = reports.total || 0;
  const openReports = reports.open || 0;
  const inProgressReports = reports.inProgress || 0;
  const closedReports = reports.closed || 0;
  
  // Calculate player percentage safely
  const onlinePlayers = players.online || 0;
  const maxPlayers = players.max || 32;
  const playerPercentage = Math.round((onlinePlayers / maxPlayers) * 100);
  
  // Mock data for charts
  const reportStatusData = [
    { name: 'Open', value: openReports, color: '#FF9800' },
    { name: 'In Progress', value: inProgressReports, color: '#2196F3' },
    { name: 'Closed', value: closedReports, color: '#4CAF50' },
  ];
  
  const playerActivityData = [
    { name: '00:00', players: 18 },
    { name: '02:00', players: 12 },
    { name: '04:00', players: 8 },
    { name: '06:00', players: 5 },
    { name: '08:00', players: 10 },
    { name: '10:00', players: 15 },
    { name: '12:00', players: 22 },
    { name: '14:00', players: 28 },
    { name: '16:00', players: 35 },
    { name: '18:00', players: 42 },
    { name: '20:00', players: 38 },
    { name: '22:00', players: 30 },
  ];

  return (
    <Grid gutter="md">
      {/* First row - Statistical cards */}
      <Grid.Col span={3}>
        <Paper p="md" radius="md" style={{ backgroundColor: 'rgba(33, 150, 243, 0.1)', border: '1px solid rgba(33, 150, 243, 0.2)' }}>
          <Group position="apart">
            <div>
              <Text size="xs" color="dimmed" transform="uppercase" weight={700}>
                Online Players
              </Text>
              <Title order={2}>{onlinePlayers} / {maxPlayers}</Title>
            </div>
            <IconUsers size={32} color="#2196F3" />
          </Group>
          <Text size="xs" color="dimmed" mt="md">
            {playerPercentage}% of server capacity
          </Text>
          <RingProgress
            sections={[{ value: playerPercentage, color: '#2196F3' }]}
            size={80}
            thickness={8}
            roundCaps
            label={
              <Text color="blue" weight={700} align="center" size="lg">
                {playerPercentage}%
              </Text>
            }
            mt="md"
          />
        </Paper>
      </Grid.Col>

      <Grid.Col span={3}>
        <Paper p="md" radius="md" style={{ backgroundColor: 'rgba(76, 175, 80, 0.1)', border: '1px solid rgba(76, 175, 80, 0.2)' }}>
          <Group position="apart">
            <div>
              <Text size="xs" color="dimmed" transform="uppercase" weight={700}>
                Closed Reports
              </Text>
              <Title order={2}>{closedReports}</Title>
            </div>
            <IconClipboardCheck size={32} color="#4CAF50" />
          </Group>
          <Text size="xs" color="dimmed" mt="md">
            {totalReports > 0 ? Math.round((closedReports / totalReports) * 100) : 0}% of total reports
          </Text>
          <RingProgress
            sections={[{ value: totalReports > 0 ? Math.round((closedReports / totalReports) * 100) : 0, color: '#4CAF50' }]}
            size={80}
            thickness={8}
            roundCaps
            label={
              <Text color="green" weight={700} align="center" size="lg">
                {totalReports > 0 ? Math.round((closedReports / totalReports) * 100) : 0}%
              </Text>
            }
            mt="md"
          />
        </Paper>
      </Grid.Col>

      <Grid.Col span={3}>
        <Paper p="md" radius="md" style={{ backgroundColor: 'rgba(255, 152, 0, 0.1)', border: '1px solid rgba(255, 152, 0, 0.2)' }}>
          <Group position="apart">
            <div>
              <Text size="xs" color="dimmed" transform="uppercase" weight={700}>
                In Progress Reports
              </Text>
              <Title order={2}>{inProgressReports}</Title>
            </div>
            <IconFlag size={32} color="#FF9800" />
          </Group>
          <Text size="xs" color="dimmed" mt="md">
            {totalReports > 0 ? Math.round((inProgressReports / totalReports) * 100) : 0}% of total reports
          </Text>
          <RingProgress
            sections={[{ value: totalReports > 0 ? Math.round((inProgressReports / totalReports) * 100) : 0, color: '#FF9800' }]}
            size={80}
            thickness={8}
            roundCaps
            label={
              <Text color="orange" weight={700} align="center" size="lg">
                {totalReports > 0 ? Math.round((inProgressReports / totalReports) * 100) : 0}%
              </Text>
            }
            mt="md"
          />
        </Paper>
      </Grid.Col>

      <Grid.Col span={3}>
        <Paper p="md" radius="md" style={{ backgroundColor: 'rgba(244, 67, 54, 0.1)', border: '1px solid rgba(244, 67, 54, 0.2)' }}>
          <Group position="apart">
            <div>
              <Text size="xs" color="dimmed" transform="uppercase" weight={700}>
                Open Reports
              </Text>
              <Title order={2}>{openReports}</Title>
            </div>
            <IconAlertCircle size={32} color="#F44336" />
          </Group>
          <Text size="xs" color="dimmed" mt="md">
            {totalReports > 0 ? Math.round((openReports / totalReports) * 100) : 0}% of total reports
          </Text>
          <RingProgress
            sections={[{ value: totalReports > 0 ? Math.round((openReports / totalReports) * 100) : 0, color: '#F44336' }]}
            size={80}
            thickness={8}
            roundCaps
            label={
              <Text color="red" weight={700} align="center" size="lg">
                {totalReports > 0 ? Math.round((openReports / totalReports) * 100) : 0}%
              </Text>
            }
            mt="md"
          />
        </Paper>
      </Grid.Col>

      {/* Second row - Charts */}
      <Grid.Col span={6}>
        <Paper p="md" radius="md" style={{ height: '300px' }}>
          <Title order={3} mb="md">Report Status</Title>
          <ResponsiveContainer width="100%" height="85%">
            <PieChart>
              <Pie
                data={reportStatusData}
                cx="50%"
                cy="50%"
                labelLine={false}
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
                label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
              >
                {reportStatusData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip formatter={(value) => [`${value} Reports`, 'Count']} />
              <Legend />
            </PieChart>
          </ResponsiveContainer>
        </Paper>
      </Grid.Col>

      <Grid.Col span={6}>
        <Paper p="md" radius="md" style={{ height: '300px' }}>
          <Title order={3} mb="md">Player Activity (24h)</Title>
          <ResponsiveContainer width="100%" height="85%">
            <LineChart
              data={playerActivityData}
              margin={{ top: 5, right: 30, left: 0, bottom: 5 }}
            >
              <CartesianGrid strokeDasharray="3 3" opacity={0.2} />
              <XAxis dataKey="name" tick={{ fill: '#aaa' }} />
              <YAxis tick={{ fill: '#aaa' }} />
              <Tooltip labelStyle={{ color: '#333' }} />
              <Legend />
              <Line type="monotone" dataKey="players" stroke="#2196F3" strokeWidth={2} />
            </LineChart>
          </ResponsiveContainer>
        </Paper>
      </Grid.Col>

      {/* Third row - Server status */}
      <Grid.Col span={12}>
        <Paper p="md" radius="md">
          <Title order={3} mb="md">Server Information</Title>
          <Divider mb="md" />
          <Grid>
            <Grid.Col span={4}>
              <Stack spacing="xs">
                <Group position="apart">
                  <Text color="dimmed">Server Name:</Text>
                  <Text weight={500}>Project Sentinel</Text>
                </Group>
                <Group position="apart">
                  <Text color="dimmed">Server ID:</Text>
                  <Text weight={500}>SV-01</Text>
                </Group>
              </Stack>
            </Grid.Col>
            <Grid.Col span={4}>
              <Stack spacing="xs">
                <Group position="apart">
                  <Text color="dimmed">Uptime:</Text>
                  <Text weight={500}>2 days 14 hours</Text>
                </Group>
                <Group position="apart">
                  <Text color="dimmed">Status:</Text>
                  <Text weight={500} color="green">Online</Text>
                </Group>
              </Stack>
            </Grid.Col>
            <Grid.Col span={4}>
              <Stack spacing="xs">
                <Group position="apart">
                  <Text color="dimmed">Version:</Text>
                  <Text weight={500}>1.0.0</Text>
                </Group>
                <Group position="apart">
                  <Text color="dimmed">Last Restart:</Text>
                  <Text weight={500}>2023-04-22 08:15</Text>
                </Group>
              </Stack>
            </Grid.Col>
          </Grid>
        </Paper>
      </Grid.Col>
    </Grid>
  );
};

export default DashboardTab;