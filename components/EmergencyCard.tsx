import React from 'react';
import { LucideIcon } from 'lucide-react';

interface EmergencyCardProps {
  title: string;
  icon: LucideIcon;
  color: string;
  onClick: () => void;
}

export const EmergencyCard: React.FC<EmergencyCardProps> = ({ title, icon: Icon, color, onClick }) => {
  return (
    <div
      onClick={onClick}
      className={`relative overflow-hidden rounded-2xl p-4 h-32 flex flex-col justify-between mb-4 shadow-sm cursor-pointer transition-transform active:scale-95 ${color}`}
    >
      <div className="absolute -right-4 -bottom-4 opacity-20">
        <Icon size={100} color="white" />
      </div>
      <Icon size={32} color="white" />
      <span className="text-lg font-bold text-white text-left">{title}</span>
    </div>
  );
};