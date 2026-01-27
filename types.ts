export enum EmergencyType {
  MEDICAL = 'Medical',
  FIRE = 'Fire',
  ACCIDENT = 'Accident',
  CRIME = 'Crime',
  OTHER = 'Other'
}

export interface Coordinates {
  latitude: number;
  longitude: number;
}

export interface IncidentReport {
  id: string;
  type: EmergencyType;
  description: string;
  location: Coordinates | null;
  timestamp: number;
  status: 'pending' | 'dispatched' | 'resolved';
  aiAnalysis?: string;
}

export interface FirstAidGuide {
  title: string;
  steps: string[];
  warning?: string;
}

export interface ChatMessage {
  role: 'user' | 'model';
  text: string;
  timestamp: number;
}