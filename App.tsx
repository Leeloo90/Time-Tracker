
import React, { useState, useEffect, useCallback, useRef } from 'react';
import { MenuBar } from './components/MenuBar';
import { StartupModal } from './components/StartupModal';
import { Dashboard } from './components/Dashboard';
import { SimulatorPanel } from './components/SimulatorPanel';
import { TimeEntry, ActivityState, PendingSwitch, Allocation } from './types';
import { STICKY_THRESHOLD_MS, IDLE_THRESHOLD_MS, BLACKLIST_APPS } from './constants';

const App: React.FC = () => {
  const [isWorkdayActive, setIsWorkdayActive] = useState(false);
  const [showStartupModal, setShowStartupModal] = useState(false);
  const [showDashboard, setShowDashboard] = useState(true);
  
  const [currentCompany, setCurrentCompany] = useState('');
  const [currentAllocation, setCurrentAllocation] = useState('');
  
  const [entries, setEntries] = useState<TimeEntry[]>(() => {
    const saved = localStorage.getItem('autotime_entries');
    return saved ? JSON.parse(saved) : [];
  });

  // Tracking State Refs
  const currentActivityRef = useRef<ActivityState | null>(null);
  const pendingSwitchRef = useRef<PendingSwitch | null>(null);
  const [activeDisplay, setActiveDisplay] = useState<{app: string, project: string} | null>(null);
  const lastInputTimeRef = useRef<number>(Date.now());
  const blacklistedStartTimeRef = useRef<number | null>(null);

  // Persistence
  useEffect(() => {
    localStorage.setItem('autotime_entries', JSON.stringify(entries));
  }, [entries]);

  const parseProjectTitle = (app: string, rawTitle: string): string => {
    if (app === 'DaVinci Resolve') {
      return rawTitle.replace('DaVinci Resolve - ', '').trim();
    }
    if (app === 'Google Chrome' || app === 'Safari') {
      // Logic for browsers: using tab title as project
      return rawTitle.trim();
    }
    return rawTitle.trim();
  };

  const addEntry = useCallback((activity: ActivityState, endTime: number) => {
    // Skip tiny entries (< 10s) to avoid clutter if noise occurs
    if (endTime - activity.startTime < 10000) return;

    const start = new Date(activity.startTime);
    const end = new Date(endTime);
    
    const newEntry: TimeEntry = {
      id: Math.random().toString(36).substr(2, 9),
      day: start.toLocaleDateString('en-GB'),
      company: currentCompany || 'Pending',
      allocation: currentAllocation || 'Unassigned',
      application: activity.app,
      project: activity.project,
      timeStart: start.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', second: '2-digit' }),
      timeFinish: end.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', second: '2-digit' }),
      overview: '',
      durationMs: endTime - activity.startTime,
    };

    setEntries(prev => [newEntry, ...prev]);
  }, [currentCompany, currentAllocation]);

  // Handle Logic Ticks
  useEffect(() => {
    if (!isWorkdayActive) return;

    const interval = setInterval(() => {
      const now = Date.now();
      
      // 1. HID Idle Detection (Keyboard/Mouse)
      if (now - lastInputTimeRef.current > IDLE_THRESHOLD_MS) {
        if (currentActivityRef.current) {
          console.log("Idle detected. Closing session at last active timestamp.");
          addEntry(currentActivityRef.current, lastInputTimeRef.current);
          currentActivityRef.current = null;
          pendingSwitchRef.current = null;
          setActiveDisplay(null);
        }
        return;
      }

      // 2. Blacklist / Disregard Logic
      if (blacklistedStartTimeRef.current) {
        if (now - blacklistedStartTimeRef.current > IDLE_THRESHOLD_MS) {
          console.log("Blacklisted app active for >5m. Terminating previous session.");
          if (currentActivityRef.current) {
            addEntry(currentActivityRef.current, blacklistedStartTimeRef.current);
          }
          currentActivityRef.current = null;
          blacklistedStartTimeRef.current = null;
          setActiveDisplay(null);
        }
      }

      // 3. Sticky Logic for Secondary Apps
      if (pendingSwitchRef.current) {
        const timeSpentSinceSwitch = now - pendingSwitchRef.current.switchTime;
        
        if (timeSpentSinceSwitch > STICKY_THRESHOLD_MS) {
          console.log("Sticky threshold exceeded. Retroactively switching.");
          if (currentActivityRef.current) {
            addEntry(currentActivityRef.current, pendingSwitchRef.current.switchTime);
          }
          currentActivityRef.current = {
            app: pendingSwitchRef.current.app,
            project: pendingSwitchRef.current.project,
            startTime: pendingSwitchRef.current.switchTime,
            lastActive: now,
          };
          pendingSwitchRef.current = null;
          setActiveDisplay({
            app: currentActivityRef.current.app,
            project: currentActivityRef.current.project
          });
        }
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [isWorkdayActive, addEntry]);

  const handleAppSwitch = (app: string, rawProject: string) => {
    if (!isWorkdayActive) return;
    const now = Date.now();
    lastInputTimeRef.current = now;

    const project = parseProjectTitle(app, rawProject);

    // Handle Blacklist (Finder, System Settings)
    if (BLACKLIST_APPS.includes(app)) {
      if (!blacklistedStartTimeRef.current) {
        blacklistedStartTimeRef.current = now;
      }
      // We don't change 'activeDisplay' yet because of the sticky logic,
      // but we stop the primary app's "progress" mentally.
      return; 
    }
    
    // If we were on a blacklisted app but switched back to a tracked one
    blacklistedStartTimeRef.current = null;

    if (!currentActivityRef.current) {
      currentActivityRef.current = { app, project, startTime: now, lastActive: now };
      setActiveDisplay({ app, project });
      return;
    }

    // Return to current primary app
    if (app === currentActivityRef.current.app) {
      pendingSwitchRef.current = null;
      setActiveDisplay({ app, project });
      return;
    }

    // Secondary app switch: Start pending (5-minute sticky rule)
    if (!pendingSwitchRef.current || pendingSwitchRef.current.app !== app) {
      pendingSwitchRef.current = { app, project, switchTime: now };
    }
  };

  const handleStartWorkday = () => {
    setShowStartupModal(true);
  };

  const handleStopWorkday = () => {
    if (currentActivityRef.current) {
      addEntry(currentActivityRef.current, Date.now());
    }
    currentActivityRef.current = null;
    pendingSwitchRef.current = null;
    blacklistedStartTimeRef.current = null;
    setIsWorkdayActive(false);
    setActiveDisplay(null);
  };

  const finalizeStartup = (company: string, allocation: string) => {
    setCurrentCompany(company);
    setCurrentAllocation(allocation);
    setIsWorkdayActive(true);
    setShowStartupModal(false);
  };

  return (
    <div className="desktop-bg overflow-hidden flex flex-col">
      <MenuBar 
        isWorking={isWorkdayActive}
        onToggleWork={isWorkdayActive ? handleStopWorkday : handleStartWorkday}
        onShowDashboard={() => setShowDashboard(true)}
      />

      <div className="flex-1 p-8 flex flex-col md:flex-row gap-6 overflow-hidden">
        {showDashboard && (
          <div className="flex-1 bg-white/95 backdrop-blur-md rounded-xl shadow-2xl overflow-hidden flex flex-col border border-white/20">
            <Dashboard 
              entries={entries} 
              setEntries={setEntries} 
              activeDisplay={activeDisplay}
            />
          </div>
        )}

        <div className="w-80 bg-gray-900/40 backdrop-blur-md rounded-xl p-6 text-white border border-white/10">
          <SimulatorPanel 
            isWorking={isWorkdayActive}
            onSwitch={handleAppSwitch}
            pending={pendingSwitchRef.current}
            active={currentActivityRef.current}
            onInput={() => { lastInputTimeRef.current = Date.now(); }}
          />
        </div>
      </div>

      {showStartupModal && (
        <StartupModal 
          onConfirm={finalizeStartup}
          onCancel={() => setShowStartupModal(false)}
        />
      )}
    </div>
  );
};

export default App;
