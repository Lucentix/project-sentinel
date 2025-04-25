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
        
        try {
          // Safely extract the data based on the action type
          if (action === 'receiveReports') {
            // Make sure reports is always an array
            const reports = Array.isArray(data.reports) ? data.reports : [];
            handler(reports);
          } 
          else if (action === 'receiveOnlinePlayers') {
            // Make sure players is always an array
            const players = Array.isArray(data.players) ? data.players : [];
            handler(players);
          } 
          else if (action === 'receiveServerStats') {
            // Make sure stats is always an object
            const stats = (typeof data.stats === 'object' && data.stats !== null) ? data.stats : {
              players: { online: 0, max: 32 },
              reports: { total: 0, open: 0, inProgress: 0, closed: 0 },
              server: { name: "Unknown", uptime: 0 }
            };
            handler(stats);
          } 
          else {
            // Default handler for other events
            handler(data);
          }
        } catch (error) {
          console.error(`[NUI] Error processing ${action} event:`, error);
          
          // Report error to client
          fetch('https://project-sentinel/reportError', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
              message: error.toString(),
              stack: error.stack || "No stack available",
              action: action
            })
          }).catch(err => console.error("[NUI] Failed to report error:", err));
          
          // Provide safe default values based on action type
          if (action === 'receiveReports') handler([]);
          else if (action === 'receiveOnlinePlayers') handler([]);
          else if (action === 'receiveServerStats') {
            handler({
              players: { online: 0, max: 32 },
              reports: { total: 0, open: 0, inProgress: 0, closed: 0 }
            });
          }
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