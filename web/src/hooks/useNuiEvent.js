import { useEffect } from 'react';

export const useNuiEvent = (action, handler) => {
  useEffect(() => {
    window.addEventListener('message', onMessageReceived);

    function onMessageReceived(event) {
      const { data } = event;

      if (data && data.action === action) {
        handler(data);
      }
    }

    return () => window.removeEventListener('message', onMessageReceived);
  }, [action, handler]);
};

export const debugData = (mockData) => {
  if (process.env.NODE_ENV === 'development') {
    mockData.forEach(payload => {
      window.dispatchEvent(
        new MessageEvent('message', {
          data: payload
        })
      );
    });
  }
};