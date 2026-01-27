import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Ambulance, Flame, Zap, ShieldAlert, Activity } from 'lucide-react';
import { EmergencyCard } from '../components/EmergencyCard';

const Home: React.FC = () => {
  const navigate = useNavigate();

  const handleQuickReport = (type: string) => {
    navigate(`/report?type=${type}`);
  };

  return (
    <div className="min-h-screen bg-slate-50 px-4 pt-6 pb-24">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">ResQ</h1>
          <p className="text-slate-500 text-sm">Emergency Response System</p>
        </div>
        <div className="h-10 w-10 bg-red-100 rounded-full flex items-center justify-center">
          <Activity size={20} className="text-red-600" />
        </div>
      </div>

      {/* Main SOS Call To Action */}
      <div className="mb-8">
        <button 
          onClick={() => navigate('/report')}
          className="w-full bg-red-600 rounded-3xl p-6 shadow-xl text-left transition-transform active:scale-95"
        >
          <div className="flex items-center justify-between mb-4">
            <span className="text-3xl font-bold text-white">SOS</span>
            <div className="w-4 h-4 bg-white rounded-full opacity-80 animate-pulse" />
          </div>
          <span className="text-red-100 font-medium">Tap to report emergency immediately</span>
        </button>
      </div>

      <h2 className="text-lg font-semibold text-slate-800 mb-4">What's happening?</h2>
      
      <div className="grid grid-cols-2 gap-4">
        <EmergencyCard 
          title="Medical" 
          icon={Ambulance} 
          color="bg-blue-500" 
          onClick={() => handleQuickReport('Medical')}
        />
        <EmergencyCard 
          title="Fire" 
          icon={Flame} 
          color="bg-orange-500" 
          onClick={() => handleQuickReport('Fire')}
        />
        <EmergencyCard 
          title="Accident" 
          icon={Zap} 
          color="bg-yellow-500" 
          onClick={() => handleQuickReport('Accident')}
        />
        <EmergencyCard 
          title="Crime" 
          icon={ShieldAlert} 
          color="bg-slate-700" 
          onClick={() => handleQuickReport('Crime')}
        />
      </div>

      <div className="mt-8 bg-white rounded-xl p-4 shadow-sm border border-slate-100 mb-10">
        <h3 className="font-semibold text-slate-800 mb-2">Active Alerts</h3>
        <p className="text-sm text-slate-500 text-center py-4">
          No active emergency alerts in your vicinity.
        </p>
      </div>
    </div>
  );
};

export default Home;