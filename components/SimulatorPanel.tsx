
import React from 'react';
import { SAMPLE_APPS, STICKY_THRESHOLD_MS } from '../constants';
import { PendingSwitch, ActivityState } from '../types';

interface SimulatorPanelProps {
  isWorking: boolean;
  onSwitch: (app: string, project: string) => void;
  pending: PendingSwitch | null;
  active: ActivityState | null;
  onInput: () => void;
}

const PROJECT_VARIANTS = [
  "Campaign_Video_Final",
  "Product_Launch_Assets",
  "Social_Media_Shorts_v3",
  "Client_Review_Edit",
  "Research_and_Development"
];

export const SimulatorPanel: React.FC<SimulatorPanelProps> = ({ isWorking, onSwitch, pending, active, onInput }) => {
  const [seconds, setSeconds] = React.useState(0);

  React.useEffect(() => {
    const timer = setInterval(() => setSeconds(s => s + 1), 1000);
    return () => clearInterval(timer);
  }, []);

  const progress = pending ? Math.min(100, ((Date.now() - pending.switchTime) / STICKY_THRESHOLD_MS) * 100) : 0;

  const handleAppClick = (appName: string) => {
    onInput();
    const randomProject = PROJECT_VARIANTS[Math.floor(Math.random() * PROJECT_VARIANTS.length)];
    const finalProject = appName === 'DaVinci Resolve' ? `DaVinci Resolve - ${randomProject}` : randomProject;
    onSwitch(appName, finalProject);
  };

  return (
    <div className="h-full flex flex-col gap-6" onMouseMove={onInput} onKeyDown={onInput}>
      <div className="space-y-1">
        <h2 className="text-sm font-bold uppercase tracking-widest text-blue-400">Activity Simulator</h2>
        <p className="text-[11px] text-gray-400">Faking macOS system events for this demo.</p>
      </div>

      <div className="bg-white/5 rounded-lg p-4 space-y-4">
        <div className="flex flex-col gap-2">
           <label className="text-[10px] font-bold text-gray-500 uppercase tracking-tighter">Current Primary</label>
           <div className="text-sm">
             {active ? (
               <div className="flex items-center gap-2">
                 <div className="w-2 h-2 bg-blue-500 rounded-full animate-pulse shadow-[0_0_8px_rgba(59,130,246,0.5)]"></div>
                 <span className="font-semibold text-blue-100">{active.app}</span>
               </div>
             ) : (
               <span className="text-gray-500 italic">None (Stopped)</span>
             )}
           </div>
        </div>

        {pending && (
          <div className="space-y-2 p-3 bg-yellow-500/10 border border-yellow-500/20 rounded-md">
            <div className="flex justify-between items-center text-[10px] font-bold text-yellow-500 uppercase">
               <span>Pending Switch</span>
               <span>{Math.round(progress)}%</span>
            </div>
            <div className="text-xs text-yellow-100 font-medium truncate">Evaluating {pending.app}...</div>
            <div className="w-full bg-white/10 h-1.5 rounded-full overflow-hidden">
               <div className="bg-yellow-500 h-full transition-all duration-1000" style={{ width: `${progress}%` }}></div>
            </div>
            <p className="text-[9px] text-yellow-500/70 italic leading-tight">Switching away for &lt;5m keeps time on {active?.app}.</p>
          </div>
        )}
      </div>

      <div className="flex-1 space-y-3">
        <label className="text-[10px] font-bold text-gray-500 uppercase">Simulate App Switch</label>
        <div className="grid grid-cols-1 gap-2">
          {SAMPLE_APPS.map(app => (
            <button
              key={app.name}
              disabled={!isWorking}
              onClick={() => handleAppClick(app.name)}
              className={`text-left px-3 py-2.5 rounded-lg border text-sm transition-all flex items-center justify-between group
                ${isWorking 
                  ? 'bg-white/5 border-white/10 hover:bg-white/10 hover:border-white/20 active:scale-95' 
                  : 'bg-transparent border-white/5 opacity-40 cursor-not-allowed'}`}
            >
              <span>{app.name}</span>
              <span className="text-[10px] text-gray-500 group-hover:text-blue-400">Activate &rarr;</span>
            </button>
          ))}
          
          <div className="mt-4 pt-4 border-t border-white/10 space-y-2">
            <button
              disabled={!isWorking}
              onClick={() => {
                onInput();
                onSwitch('Finder', 'Desktop');
              }}
              className={`w-full text-center px-3 py-2 rounded-lg text-xs font-bold transition-all
                ${isWorking ? 'bg-orange-500/20 text-orange-400 border border-orange-500/30 hover:bg-orange-500/30' : 'bg-transparent border-white/5 opacity-40 cursor-not-allowed'}`}
            >
              Simulate Finder (Blacklisted)
            </button>
            <p className="text-[9px] text-gray-500 text-center px-2">Blacklisted apps are treated as Idle. 5m in Finder closes the primary session.</p>
          </div>
        </div>
      </div>

      <div className="text-[10px] text-gray-600 text-center font-mono border-t border-white/5 pt-4">
        UPTIME: {Math.floor(seconds / 60)}m {seconds % 60}s
      </div>
    </div>
  );
};
