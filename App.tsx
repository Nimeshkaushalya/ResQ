import React from 'react';
import { HashRouter, Routes, Route, Navigate } from 'react-router-dom';
import Home from './pages/Home';
import Report from './pages/Report';
import FirstAid from './pages/FirstAid';
import NearbyMap from './pages/NearbyMap';
import Profile from './pages/Profile';
import { Navigation } from './components/Navigation';

export default function App() {
  return (
    <HashRouter>
      <div className="min-h-screen bg-slate-100 font-sans">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/report" element={<Report />} />
          <Route path="/map" element={<NearbyMap />} />
          <Route path="/first-aid" element={<FirstAid />} />
          <Route path="/profile" element={<Profile />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
        <Navigation />
      </div>
    </HashRouter>
  );
}