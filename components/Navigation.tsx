import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Home, Map, MessageSquarePlus, User, Siren } from 'lucide-react';

export const Navigation: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();

  const isActive = (path: string) => location.pathname === path;

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-slate-200 h-16 pb-safe flex items-center justify-around z-50 shadow-lg">
      <button 
        onClick={() => navigate('/')} 
        className={`flex flex-col items-center justify-center w-16 h-full ${isActive('/') ? 'text-red-600' : 'text-slate-400'}`}
      >
        <Home size={24} />
        <span className="text-[10px] font-medium mt-1">Home</span>
      </button>

      <button 
        onClick={() => navigate('/map')} 
        className={`flex flex-col items-center justify-center w-16 h-full ${isActive('/map') ? 'text-red-600' : 'text-slate-400'}`}
      >
        <Map size={24} />
        <span className="text-[10px] font-medium mt-1">Nearby</span>
      </button>

      <div className="relative -top-5">
        <button 
          onClick={() => navigate('/report')} 
          className="bg-red-600 hover:bg-red-700 text-white w-16 h-16 rounded-full flex items-center justify-center shadow-red-500/50 shadow-lg transition-transform active:scale-95"
        >
          <Siren size={32} />
        </button>
      </div>

      <button 
        onClick={() => navigate('/first-aid')} 
        className={`flex flex-col items-center justify-center w-16 h-full ${isActive('/first-aid') ? 'text-red-600' : 'text-slate-400'}`}
      >
        <MessageSquarePlus size={24} />
        <span className="text-[10px] font-medium mt-1">Guide</span>
      </button>

      <button 
        onClick={() => navigate('/profile')} 
        className={`flex flex-col items-center justify-center w-16 h-full ${isActive('/profile') ? 'text-red-600' : 'text-slate-400'}`}
      >
        <User size={24} />
        <span className="text-[10px] font-medium mt-1">Profile</span>
      </button>
    </div>
  );
};