import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';
import { MantineProvider } from '@mantine/core';
import { Notifications } from '@mantine/notifications';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <MantineProvider theme={{
      colorScheme: 'dark',
      fontFamily: 'Poppins, sans-serif',
      primaryColor: 'blue',
    }} withGlobalStyles withNormalizeCSS>
      <Notifications position="top-right" zIndex={2077} />
      <App />
    </MantineProvider>
  </React.StrictMode>
);