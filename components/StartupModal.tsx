
import React, { useState } from 'react';
import { DEFAULT_COMPANIES } from '../constants';
import { Allocation } from '../types';

interface StartupModalProps {
  onConfirm: (company: string, allocation: string) => void;
  onCancel: () => void;
}

export const StartupModal: React.FC<StartupModalProps> = ({ onConfirm, onCancel }) => {
  const [company, setCompany] = useState('');
  const [allocation, setAllocation] = useState(Allocation.PRODUCTION);

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/40 backdrop-blur-sm">
      <div className="bg-[#1e1e1e] w-[400px] rounded-2xl shadow-2xl border border-white/10 p-6 text-white flex flex-col gap-6 animate-in fade-in zoom-in duration-200">
        <div className="flex flex-col items-center text-center">
          <div className="w-16 h-16 bg-blue-600 rounded-2xl flex items-center justify-center mb-4 shadow-lg shadow-blue-500/20">
            <svg className="w-8 h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <h2 className="text-xl font-semibold">Ready to start?</h2>
          <p className="text-gray-400 text-sm mt-1">Configure your session or leave blank to edit later.</p>
        </div>

        <div className="space-y-4">
          <div className="space-y-1.5">
            <label className="text-xs font-medium text-gray-400 uppercase tracking-wider ml-1">Company</label>
            <div className="relative">
              <input 
                type="text" 
                list="companies"
                className="w-full bg-white/5 border border-white/10 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/50"
                placeholder="Select or type company name"
                value={company}
                onChange={(e) => setCompany(e.target.value)}
              />
              <datalist id="companies">
                {DEFAULT_COMPANIES.map(c => <option key={c} value={c} />)}
              </datalist>
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="text-xs font-medium text-gray-400 uppercase tracking-wider ml-1">Allocation</label>
            <select 
              className="w-full bg-white/5 border border-white/10 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/50 appearance-none"
              value={allocation}
              onChange={(e) => setAllocation(e.target.value as Allocation)}
            >
              <option value={Allocation.PRODUCTION}>Production</option>
              <option value={Allocation.EDITING}>Editing</option>
            </select>
          </div>
        </div>

        <div className="flex gap-3 mt-2">
          <button 
            onClick={onCancel}
            className="flex-1 px-4 py-2.5 rounded-xl bg-white/5 hover:bg-white/10 border border-white/5 text-sm font-medium transition-colors"
          >
            Cancel
          </button>
          <button 
            onClick={() => onConfirm(company, allocation)}
            className="flex-1 px-4 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-500 text-sm font-medium shadow-lg shadow-blue-600/20 transition-all active:scale-95"
          >
            Start Session
          </button>
        </div>
      </div>
    </div>
  );
};
