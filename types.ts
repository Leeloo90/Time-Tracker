
export enum Allocation {
  PRODUCTION = 'Production',
  EDITING = 'Editing',
}

export interface TimeEntry {
  id: string;
  day: string; // DD/MM/YYYY
  company: string;
  allocation: string;
  application: string;
  project: string;
  timeStart: string; // HH:mm:ss
  timeFinish: string; // HH:mm:ss
  overview: string;
  durationMs: number;
}

export interface ActivityState {
  app: string;
  project: string;
  startTime: number;
  lastActive: number;
}

export interface PendingSwitch {
  app: string;
  project: string;
  switchTime: number;
}
