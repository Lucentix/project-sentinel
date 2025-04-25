import { useEffect } from 'react';

export const useNuiEvent = (action, handler) => {
  useEffect(() => {
    console.log(`[NUI] Setting up event listener for action: ${action}`);
    window.addEventListener('message', onMessageReceived);

    function onMessageReceived(event) {
      const { data } = event;
      console.log(`[NUI] Message received:`, data);

      if (data && data.action === action) {
        console.log(`[NUI] Handling action: ${action}`);
        
        // For arrays, ensure we're directly passing the array, not a wrapper object
        if (action === 'receiveReports' && data.reports) {
          handler({ reports: data.reports });
        } else if (action === 'receiveOnlinePlayers' && data.players) {
          handler({ players: data.players });
        } else if (action === 'receiveServerStats' && data.stats) {
          handler({ stats: data.stats });
        } else {
          // Default handler for other events
          handler(data);
        }
      }
    }

    return () => window.removeEventListener('message', onMessageReceived);
  }, [action, handler]);
};

export const debugData = (mockData) => {
  if (process.env.NODE_ENV === 'development') {
    console.log('[NUI] Dispatching debug data:', mockData);
    mockData.forEach(payload => {
      window.dispatchEvent(
        new MessageEvent('message', {
          data: payload
        })
      );
    });
  }
};