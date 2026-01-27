import React from 'react';
import { MapPin, Navigation, Phone } from 'lucide-react';

const responders = [
  { id: 1, type: 'Ambulance', distance: '0.8 km', eta: '4 min' },
  { id: 2, type: 'Responder', distance: '0.3 km', eta: '2 min' },
  { id: 3, type: 'Police', distance: '1.2 km', eta: '6 min' },
];

const NearbyMap: React.FC = () => {
  return (
    <div className="h-screen bg-slate-300 relative flex flex-col">
      <div className="absolute top-0 left-0 right-0 z-10 p-4 pt-12 bg-gradient-to-b from-black/50 to-transparent pointer-events-none">
        <h1 className="text-white font-bold text-lg drop-shadow-md">Nearby Help</h1>
      </div>

      {/* Simulated Map Background */}
      <div className="flex-1 relative overflow-hidden flex items-center justify-center bg-[#e5e7eb]">
        {/* User Location Pulse */}
        <div className="absolute z-20 flex items-center justify-center">
           <div className="w-4 h-4 bg-blue-500 rounded-full border-2 border-white relative z-10" />
           <div className="w-16 h-16 bg-blue-500/30 rounded-full absolute animate-ping" />
        </div>

        {/* Simulated Pins */}
        <div className="absolute top-1/3 left-1/3 flex flex-col items-center">
            <div className="bg-white px-2 py-1 rounded shadow-md mb-1 whitespace-nowrap">
                <span className="text-[10px] font-bold">Medic (2min)</span>
            </div>
            <MapPin size={32} className="text-red-500 fill-current" />
        </div>

        <div className="absolute bottom-1/3 right-1/4 flex flex-col items-center">
             <MapPin size={28} className="text-orange-500 fill-current" />
        </div>
      </div>

      {/* Responder List Overlay */}
      <div className="bg-white rounded-t-3xl shadow-[0_-5px_20px_rgba(0,0,0,0.1)] p-6 z-20 relative mb-16">
        <div className="w-12 h-1 bg-slate-300 rounded-full mx-auto mb-6" />
        
        <h2 className="font-bold text-lg mb-4">Available Responders</h2>
        
        <div className="space-y-2">
          {responders.map(r => (
            <div key={r.id} className="flex items-center justify-between p-3 border border-slate-100 rounded-xl bg-slate-50">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-sm">
                  <Navigation size={18} className="text-slate-700" />
                </div>
                <div>
                  <h3 className="font-semibold text-sm">{r.type}</h3>
                  <p className="text-xs text-slate-500">{r.distance} • <span className="text-green-600 font-medium">ETA {r.eta}</span></p>
                </div>
              </div>
              <button className="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center hover:bg-green-200 transition-colors">
                <Phone size={18} className="text-green-700" />
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default NearbyMap;