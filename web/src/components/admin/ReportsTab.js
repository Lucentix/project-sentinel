import React, { useState } from 'react';
import {
  Table,
  Badge,
  Group,
  Text,
  ActionIcon,
  Tooltip,
  Modal,
  Button,
  Textarea,
  Select,
  Stack,
  Paper
} from '@mantine/core';
import {
  IconEye,
  IconMapPin,
  IconUserCircle,
  IconNote,
  IconCopy
} from '@tabler/icons-react';

const ReportsTab = ({ reports = [], adminRank }) => {
  const [selectedReport, setSelectedReport] = useState(null);
  const [modalOpen, setModalOpen] = useState(false);
  const [reportStatus, setReportStatus] = useState('');
  const [reportNotes, setReportNotes] = useState('');
  const [processingAction, setProcessingAction] = useState(false);

  // Function to get the badge color based on report status
  const getStatusColor = (status) => {
    switch (status) {
      case 'open':
        return 'red';
      case 'in_progress':
        return 'blue';
      case 'closed':
        return 'green';
      default:
        return 'gray';
    }
  };

  // Format the status text for display
  const formatStatus = (status) => {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'closed':
        return 'Closed';
      default:
        return 'Unknown';
    }
  };

  // Function to handle clicking on a report to view details
  const handleViewReport = (report) => {
    setSelectedReport(report);
    setReportStatus(report.status);
    setReportNotes(report.notes || '');
    setModalOpen(true);
  };

  // Function to teleport to report location
  const handleTeleportToReport = (reportId) => {
    fetch('https://project-sentinel/teleportToReport', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: JSON.stringify({
        reportId: reportId
      }),
    })
    .then(() => {
      // Close the modal after teleporting
      setModalOpen(false);
    })
    .catch(error => {
      console.error('Error teleporting to report location:', error);
    });
  };

  // Function to teleport to player who submitted the report
  const handleTeleportToPlayer = (playerId) => {
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
      // Close the modal after teleporting
      setModalOpen(false);
    })
    .catch(error => {
      console.error('Error teleporting to player:', error);
    });
  };

  // Function to copy coordinates
  const handleCopyCoords = () => {
    if (selectedReport) {
      fetch('https://project-sentinel/copyCoordinates', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
          coords: selectedReport.coords
        }),
      })
      .then(response => response.json())
      .then(response => {
        if (response.success) {
          // You could add a notification here if desired
          console.log('Coordinates copied to clipboard');
        }
      })
      .catch(error => {
        console.error('Error copying coordinates:', error);
      });
    }
  };

  // Function to update report status
  const handleUpdateReport = () => {
    if (!selectedReport) return;
    
    setProcessingAction(true);
    
    fetch('https://project-sentinel/updateReportStatus', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: JSON.stringify({
        reportId: selectedReport.id,
        status: reportStatus,
        notes: reportNotes
      }),
    })
    .then(() => {
      setProcessingAction(false);
      setModalOpen(false);
      
      // Update the local report data
      const updatedReport = {
        ...selectedReport,
        status: reportStatus,
        notes: reportNotes
      };
      
      // This is just a visual update until the next data refresh
      const reportIndex = reports.findIndex(report => report.id === selectedReport.id);
      if (reportIndex !== -1) {
        reports[reportIndex] = updatedReport;
      }
    })
    .catch(error => {
      console.error('Error updating report status:', error);
      setProcessingAction(false);
    });
  };

  // Format timestamp to readable date/time
  const formatTimestamp = (timestamp) => {
    const date = new Date(timestamp * 1000);
    return date.toLocaleString();
  };

  return (
    <>
      <Paper p="md" radius="md">
        <Text size="xl" weight={700} mb="md">Active Reports</Text>
        
        {reports.length === 0 ? (
          <Text color="dimmed" align="center" my={50}>
            No reports available.
          </Text>
        ) : (
          <Table striped highlightOnHover>
            <thead>
              <tr>
                <th>ID</th>
                <th>Status</th>
                <th>Title</th>
                <th>Reported By</th>
                <th>Submitted</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {reports.map((report) => (
                <tr key={report.id}>
                  <td>#{report.id}</td>
                  <td>
                    <Badge color={getStatusColor(report.status)} variant="filled">
                      {formatStatus(report.status)}
                    </Badge>
                  </td>
                  <td>{report.title}</td>
                  <td>{report.playerName}</td>
                  <td>{formatTimestamp(report.submittedAt)}</td>
                  <td>
                    <Group spacing={4}>
                      <Tooltip label="View Details">
                        <ActionIcon onClick={() => handleViewReport(report)} color="blue">
                          <IconEye size={16} />
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
      
      {/* Report details modal */}
      <Modal
        opened={modalOpen}
        onClose={() => setModalOpen(false)}
        title={<Text size="lg" weight={700}>Report #{selectedReport?.id}</Text>}
        size="lg"
      >
        {selectedReport && (
          <Stack spacing="md">
            <Group position="apart">
              <Text weight={500}>Status:</Text>
              <Badge color={getStatusColor(selectedReport.status)} size="lg">
                {formatStatus(selectedReport.status)}
              </Badge>
            </Group>
            
            <Group position="apart">
              <Text weight={500}>Reported by:</Text>
              <Text>{selectedReport.playerName}</Text>
            </Group>
            
            <Group position="apart">
              <Text weight={500}>Submitted:</Text>
              <Text>{formatTimestamp(selectedReport.submittedAt)}</Text>
            </Group>
            
            <Text weight={500}>Title:</Text>
            <Paper p="md" withBorder>
              <Text>{selectedReport.title}</Text>
            </Paper>
            
            <Text weight={500}>Content:</Text>
            <Paper p="md" withBorder style={{ maxHeight: '150px', overflowY: 'auto' }}>
              <Text>{selectedReport.content}</Text>
            </Paper>

            <Group position="center" spacing="md">
              <Button
                leftIcon={<IconMapPin size={16} />}
                onClick={() => handleTeleportToReport(selectedReport.id)}
              >
                Teleport to Location
              </Button>
              
              <Button
                leftIcon={<IconUserCircle size={16} />}
                onClick={() => handleTeleportToPlayer(selectedReport.playerIdentifier)}
                color="green"
              >
                Teleport to Player
              </Button>

              <Button
                leftIcon={<IconCopy size={16} />}
                onClick={handleCopyCoords}
                color="violet"
              >
                Copy Coordinates
              </Button>
            </Group>

            <Text weight={500}>Update Report:</Text>
            <Select
              label="Status"
              value={reportStatus}
              onChange={setReportStatus}
              data={[
                { value: 'open', label: 'Open' },
                { value: 'in_progress', label: 'In Progress' },
                { value: 'closed', label: 'Closed' }
              ]}
              required
            />
            
            <Textarea
              label="Notes"
              placeholder="Add your notes about this report"
              value={reportNotes}
              onChange={(event) => setReportNotes(event.currentTarget.value)}
              minRows={3}
            />
            
            <Group position="right" mt="md">
              <Button
                leftIcon={<IconNote size={16} />}
                onClick={handleUpdateReport}
                loading={processingAction}
                disabled={reportStatus === selectedReport.status && reportNotes === (selectedReport.notes || '')}
              >
                Update Report
              </Button>
            </Group>
          </Stack>
        )}
      </Modal>
    </>
  );
};

export default ReportsTab;