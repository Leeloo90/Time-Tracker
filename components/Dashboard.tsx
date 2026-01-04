
import React from 'react';
import { TimeEntry } from '../types';

interface DashboardProps {
  entries: TimeEntry[];
  setEntries: React.Dispatch<React.SetStateAction<TimeEntry[]>>;
  activeDisplay: { app: string; project: string } | null;
}

export const Dashboard: React.FC<DashboardProps> = ({ entries, setEntries, activeDisplay }) => {
  
  const updateEntry = (id: string, field: keyof TimeEntry, value: string) => {
    setEntries(prev => prev.map(entry => 
      entry.id === id ? { ...entry, [field]: value } : entry
    ));
  };

  const deleteEntry = (id: string) => {
    setEntries(prev => prev.filter(e => e.id !== id));
  };

  const exportToCSV = () => {
    const headers = ['Day', 'Company', 'Allocation', 'Application', 'Project', 'Start', 'Finish', 'Hours', 'Overview'];
    const rows = entries.map(e => {
      const hours = (e.durationMs / (1000 * 60 * 60)).toFixed(2);
      return [
        e.day,
        e.company,
        e.allocation,
        e.application,
        e.project,
        e.timeStart,
        e.timeFinish,
        hours,
        e.overview
      ].map(val => `"${val}"`).join(',');
    });

    const csvContent = [headers.join(','), ...rows].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `AutoTime_Export_${new Date().toISOString().split('T')[0]}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="p-6 border-b border-gray-100 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 tracking-tight">Work History</h1>
          <p className="text-xs text-gray-500 mt-0.5">Real-time tracked sessions & project mapping</p>
        </div>
        <div className="flex gap-3">
          <button 
            onClick={exportToCSV}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 transition-colors shadow-sm"
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a2 2 0 002 2h12a2 2 0 002-2v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
            </svg>
            Export to CSV
          </button>
        </div>
      </div>

      {/* Active Tracking Status Bar */}
      {activeDisplay && (
        <div className="px-6 py-2.5 bg-blue-50 border-b border-blue-100 text-blue-800 text-[11px] flex items-center gap-3 font-semibold uppercase tracking-wider">
          <span className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-blue-600"></span>
          </span>
          Currently Logging: <span className="text-blue-900 font-extrabold">{activeDisplay.app}</span>
          <span className="text-blue-400 font-normal ml-auto">PROJECT: {activeDisplay.project}</span>
        </div>
      )}

      {/* Table Container */}
      <div className="flex-1 overflow-auto relative">
        <table className="w-full border-collapse min-w-[1100px] text-left">
          <thead className="sticky top-0 bg-white z-10 border-b border-gray-200">
            <tr className="text-[10px] font-bold text-gray-400 uppercase tracking-widest">
              <th className="px-6 py-4 w-32">Day</th>
              <th className="px-4 py-4 w-40">Company</th>
              <th className="px-4 py-4 w-32">Allocation</th>
              <th className="px-4 py-4 w-44">App</th>
              <th className="px-4 py-4">Project</th>
              <th className="px-4 py-4 w-24">Hours</th>
              <th className="px-4 py-4 w-64">Overview</th>
              <th className="px-4 py-4 w-10"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {entries.length === 0 ? (
              <tr>
                <td colSpan={8} className="px-6 py-24 text-center">
                   <div className="flex flex-col items-center gap-3">
                      <div className="w-12 h-12 bg-gray-50 rounded-full flex items-center justify-center">
                        <svg className="w-6 h-6 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                      </div>
                      <p className="text-sm text-gray-400 font-medium">No activity recorded for this session.</p>
                   </div>
                </td>
              </tr>
            ) : (
              entries.map((entry) => (
                <tr key={entry.id} className="group hover:bg-gray-50/80 transition-colors border-l-4 border-l-transparent hover:border-l-blue-400">
                  <td className="px-6 py-4 text-sm text-gray-500 font-medium">{entry.day}</td>
                  <td className="px-4 py-4">
                    <input 
                      className="bg-transparent border-b border-transparent focus:border-blue-400 focus:outline-none w-full text-sm text-gray-800"
                      value={entry.company}
                      onChange={(e) => updateEntry(entry.id, 'company', e.target.value)}
                    />
                  </td>
                  <td className="px-4 py-4">
                    <input 
                      className="bg-transparent border-b border-transparent focus:border-blue-400 focus:outline-none w-full text-sm text-gray-800"
                      value={entry.allocation}
                      onChange={(e) => updateEntry(entry.id, 'allocation', e.target.value)}
                    />
                  </td>
                  <td className="px-4 py-4">
                    <span className="px-2 py-1 rounded bg-gray-100 text-gray-600 text-[10px] font-bold border border-gray-200">
                      {entry.application}
                    </span>
                  </td>
                  <td className="px-4 py-4">
                    <input 
                      className="bg-transparent border-b border-transparent focus:border-blue-400 focus:outline-none w-full text-sm font-semibold text-gray-900"
                      value={entry.project}
                      onChange={(e) => updateEntry(entry.id, 'project', e.target.value)}
                    />
                  </td>
                  <td className="px-4 py-4 text-sm text-gray-700 font-mono font-bold">
                    {(entry.durationMs / (1000 * 60 * 60)).toFixed(2)}
                  </td>
                  <td className="px-4 py-4">
                    <input 
                      className="bg-transparent border-b border-transparent focus:border-blue-400 focus:outline-none w-full text-sm text-gray-600 placeholder:text-gray-300 italic"
                      placeholder="Click to add overview..."
                      value={entry.overview}
                      onChange={(e) => updateEntry(entry.id, 'overview', e.target.value)}
                    />
                  </td>
                  <td className="px-4 py-4 text-right">
                    <button 
                      onClick={() => deleteEntry(entry.id)}
                      className="opacity-0 group-hover:opacity-100 p-1 text-gray-300 hover:text-red-500 transition-all rounded hover:bg-red-50"
                    >
                      <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                      </svg>
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};
