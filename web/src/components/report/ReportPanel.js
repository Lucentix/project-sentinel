import React, { useState } from 'react';
import styled from 'styled-components';
import { 
  Paper, 
  Title, 
  TextInput, 
  Textarea, 
  Button, 
  Group,
  Text,
  Box, 
  Notification
} from '@mantine/core';
import { IconX, IconCheck, IconSend } from '@tabler/icons-react';

const ReportContainer = styled(Paper)`
  width: 500px;
  padding: 20px;
  background-color: rgba(28, 28, 36, 0.95);
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.5);
`;

const CloseButton = styled.button`
  position: absolute;
  top: 15px;
  right: 15px;
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.7);
  font-size: 24px;
  cursor: pointer;
  padding: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 16px;
  transition: background-color 0.2s, color 0.2s;
  
  &:hover {
    background-color: rgba(255, 255, 255, 0.1);
    color: white;
  }
`;

const FormHeader = styled(Box)`
  margin-bottom: 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  padding-bottom: 15px;
`;

const ReportPanel = ({ onClose }) => {
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [notification, setNotification] = useState(null);
  const [processing, setProcessing] = useState(false);
  const [wordCount, setWordCount] = useState(0);

  const handleContentChange = (e) => {
    const text = e.target.value;
    setContent(text);
    
    const words = text.trim().split(/\s+/).filter(word => word.length > 0);
    setWordCount(words.length);
  };

  const submitReport = () => {
    if (!title.trim()) {
      setNotification({
        type: 'error',
        message: 'Please provide a report title.'
      });
      return;
    }

    if (wordCount < 7) {
      setNotification({
        type: 'error',
        message: 'Report content must contain at least 7 words.'
      });
      return;
    }

    setProcessing(true);

    fetch('https://project-sentinel/submitReport', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: JSON.stringify({
        title: title.trim(),
        content: content.trim(), // Make sure we're using 'content' as the field name
      }),
    })
    .then(response => response.json())
    .then(response => {
      setProcessing(false);
      
      if (response.success) {
        setNotification({
          type: 'success',
          message: response.message || 'Report submitted successfully!'
        });
        
        setTitle('');
        setContent('');
        setWordCount(0);
        
        setTimeout(() => {
          onClose();
        }, 2000);
      } else {
        setNotification({
          type: 'error',
          message: response.message || 'Failed to submit report. Please try again.'
        });
      }
    })
    .catch(error => {
      console.error('Error submitting report:', error);
      setProcessing(false);
      setNotification({
        type: 'error',
        message: 'An error occurred. Please try again later.'
      });
    });
  };

  return (
    <ReportContainer className="fade-in">
      <CloseButton onClick={onClose}>
        <IconX size={24} />
      </CloseButton>

      <FormHeader>
        <Title order={2} align="center" color="white">
          Submit a Report
        </Title>
        <Text color="dimmed" size="sm" align="center" mt={5}>
          Report bugs or request assistance from server staff
        </Text>
      </FormHeader>

      {notification && (
        <Notification
          title={notification.type === 'error' ? 'Error' : 'Success'}
          color={notification.type === 'error' ? 'red' : 'green'}
          icon={notification.type === 'error' ? <IconX /> : <IconCheck />}
          onClose={() => setNotification(null)}
          mb="md"
        >
          {notification.message}
        </Notification>
      )}

      <TextInput
        label="Report Title"
        placeholder="Brief description of the issue"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        required
        mb="md"
      />

      <Textarea
        label="Report Content"
        placeholder="Please describe your issue in detail (minimum 7 words)"
        value={content}
        onChange={handleContentChange}
        minRows={5}
        required
        mb="md"
      />
      
      <Text size="xs" color={wordCount >= 7 ? "dimmed" : "red"} mb="md">
        {wordCount}/7 words minimum {wordCount < 7 ? '(please add more details)' : ''}
      </Text>

      <Group position="center" mt="xl">
        <Button
          leftIcon={<IconSend size={16} />}
          onClick={submitReport}
          loading={processing}
          disabled={!title.trim() || wordCount < 7}
          color="blue"
          size="md"
        >
          Submit Report
        </Button>
      </Group>
    </ReportContainer>
  );
};

export default ReportPanel;