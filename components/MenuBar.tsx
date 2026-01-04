
import React, { useState } from 'react';

interface MenuBarProps {
  isWorking: boolean;
  onToggleWork: () => void;
  onShowDashboard: () => void;
}

export const MenuBar: React.FC<MenuBarProps> = ({ isWorking, onToggleWork, onShowDashboard }) => {
  const [showMenu, setShowMenu] = useState(false);

  return (
    <div className="h-7 bg-white/10 backdrop-blur-lg flex items-center px-4 justify-between text-[13px] text-white select-none border-b border-white/10">
      <div className="flex items-center gap-4">
        <div className="font-bold flex items-center gap-1 cursor-default">
          <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3">
             <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" />
          </svg>
          AutoTime
        </div>
        <div className="hover:bg-white/10 px-2 rounded cursor-default" onClick={onShowDashboard}>Dashboard</div>
      </div>
      
      <div className="relative">
        <div 
          className={`flex items-center gap-2 px-2 rounded cursor-pointer hover:bg-white/10 ${isWorking ? 'text-green-400' : 'text-gray-400'}`}
          onClick={() => setShowMenu(!showMenu)}
        >
          <div className={`w-2 h-2 rounded-full ${isWorking ? 'bg-green-400 animate-pulse' : 'bg-gray-500'}`}></div>
          {isWorking ? 'Tracking Active' : 'Idle'}
        </div>

        {showMenu && (
          <>
            <div className="fixed inset-0 z-40" onClick={() => setShowMenu(false)}></div>
            <div className="absolute right-0 mt-1 w-56 bg-[#2d2d2d]/95 backdrop-blur-xl border border-white/10 rounded-lg shadow-2xl z-50 p-1 text-gray-200">
              <button 
                onClick={() => { onToggleWork(); setShowMenu(false); }}
                className="w-full text-left px-3 py-1.5 hover:bg-blue-600 rounded flex justify-between items-center group"
              >
                <span>{isWorking ? 'Stop Workday' : 'Start Workday'}</span>
                <span className="text-gray-500 group-hover:text-white/70">⌥S</span>
              </button>
              <div className="h-px bg-white/10 my-1"></div>
              <button 
                onClick={() => { onShowDashboard(); setShowMenu(false); }}
                className="w-full text-left px-3 py-1.5 hover:bg-blue-600 rounded"
              >
                Open Dashboard
              </button>
              <button className="w-full text-left px-3 py-1.5 hover:bg-blue-600 rounded">Settings...</button>
              <div className="h-px bg-white/10 my-1"></div>
              <button className="w-full text-left px-3 py-1.5 hover:bg-blue-600 rounded">Quit AutoTime</button>
            </div>
          </>
        )}
      </div>
    </div>
  );
};
