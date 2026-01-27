import React from 'react';
import { User, Heart, Shield, Phone } from 'lucide-react';

const Profile: React.FC = () => {
  return (
    <div className="min-h-screen bg-slate-50 pb-24">
      <div className="bg-white p-6 pb-8 border-b border-slate-200">
        <div className="flex items-center gap-4 mb-6">
          <div className="w-20 h-20 bg-slate-200 rounded-full flex items-center justify-center">
            <User size={40} className="text-slate-400" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-slate-900">John Doe</h1>
            <p className="text-slate-500">ID: 2433855</p>
          </div>
        </div>
        
        <div className="flex gap-3">
          <div className="flex-1 bg-red-50 p-3 rounded-xl border border-red-100">
            <span className="text-xs text-red-600 font-medium uppercase mb-1 block">Blood Type</span>
            <span className="text-xl font-bold text-red-800">O+</span>
          </div>
          <div className="flex-1 bg-blue-50 p-3 rounded-xl border border-blue-100">
            <span className="text-xs text-blue-600 font-medium uppercase mb-1 block">Age</span>
            <span className="text-xl font-bold text-blue-800">28</span>
          </div>
        </div>
      </div>

      <div className="p-4 flex flex-col gap-4">
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center gap-2 mb-4">
            <Heart size={18} className="text-red-500" />
            <h3 className="font-semibold text-slate-800">Medical Conditions</h3>
          </div>
          <div className="flex flex-wrap gap-2">
            <div className="bg-slate-100 px-3 py-1 rounded-full">
              <span className="text-sm text-slate-700">Asthma</span>
            </div>
            <div className="bg-slate-100 px-3 py-1 rounded-full">
              <span className="text-sm text-slate-700">Penicillin Allergy</span>
            </div>
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
           <div className="flex items-center gap-2 mb-4">
            <Phone size={18} className="text-green-500" />
            <h3 className="font-semibold text-slate-800">Emergency Contacts</h3>
          </div>
          <div className="flex flex-col gap-3">
            <div className="flex justify-between items-center border-b border-slate-50 pb-2">
              <div>
                <p className="font-medium text-slate-900">Jane Doe (Wife)</p>
                <p className="text-xs text-slate-500">+1 234 567 890</p>
              </div>
              <button className="text-green-600 text-sm font-medium hover:underline">Call</button>
            </div>
            <div className="flex justify-between items-center">
              <div>
                <p className="font-medium text-slate-900">Robert Doe (Father)</p>
                <p className="text-xs text-slate-500">+1 987 654 321</p>
              </div>
              <button className="text-green-600 text-sm font-medium hover:underline">Call</button>
            </div>
          </div>
        </div>

        <button className="w-full py-4 flex items-center justify-center gap-2 text-slate-500 hover:text-slate-700 transition-colors">
          <Shield size={16} />
          <span className="text-sm font-medium">Privacy & Data Settings</span>
        </button>
      </div>
    </div>
  );
};

export default Profile;