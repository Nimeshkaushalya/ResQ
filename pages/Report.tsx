import React, { useState, useEffect, useRef } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { Camera, MapPin, Mic, CheckCircle, AlertTriangle, Send } from 'lucide-react';
import { analyzeIncident } from '../services/geminiService';
import { Coordinates } from '../types';

const Report: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const typeParam = searchParams.get('type');

  const [step, setStep] = useState<number>(1);
  const [loading, setLoading] = useState(false);
  const [analyzing, setAnalyzing] = useState(false);
  
  const [location, setLocation] = useState<Coordinates | null>(null);
  const [description, setDescription] = useState('');
  const [image, setImage] = useState<string | null>(null);
  const [aiAnalysis, setAiAnalysis] = useState<string | null>(null);
  
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if ('geolocation' in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setLocation({
            latitude: position.coords.latitude,
            longitude: position.coords.longitude
          });
        },
        (error) => {
          console.error("Error getting location", error);
        }
      );
    }
  }, []);

  const handleImageUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setImage(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleVoiceInput = () => {
    alert("Voice input is not supported in this browser demo.");
  };

  const handleSubmit = async () => {
    if (!description && !image) return;
    
    setLoading(true);
    setAnalyzing(true);

    try {
      // 1. Simulate finding nearby responders (delay)
      await new Promise(resolve => setTimeout(resolve, 1500));
      
      // 2. AI Analysis of the incident
      const analysis = await analyzeIncident(description || `Emergency reported: ${typeParam || 'General'}`, image || undefined);
      
      setAiAnalysis(analysis);
      setStep(2); // Move to success/status screen
    } catch (error) {
      console.error(error);
      alert("Failed to submit report.");
    } finally {
      setLoading(false);
      setAnalyzing(false);
    }
  };

  if (step === 2) {
    return (
      <div className="min-h-screen bg-slate-50 flex flex-col items-center justify-center p-6">
        <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mb-6">
          <CheckCircle size={48} className="text-green-600" />
        </div>
        <h2 className="text-2xl font-bold text-slate-900 mb-2">Responders Notified</h2>
        <p className="text-slate-600 mb-6 text-center">Help is on the way. Your location and incident details have been broadcast to nearby emergency teams.</p>
        
        {aiAnalysis && (
          <div className="bg-white p-4 rounded-xl w-full text-left mb-6 border border-slate-200 shadow-sm">
            <div className="flex items-center gap-2 mb-2">
              <div className="w-2 h-2 rounded-full bg-purple-500"></div> 
              <span className="font-semibold text-slate-800">AI Assessment</span>
            </div>
            <p className="text-sm text-slate-600 leading-relaxed">{aiAnalysis}</p>
          </div>
        )}

        <button 
          onClick={() => navigate('/')}
          className="w-full bg-slate-900 py-4 rounded-xl text-white font-semibold hover:bg-slate-800 transition-colors"
        >
          Return Home
        </button>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col">
      <div className="bg-white p-4 border-b border-slate-100 flex items-center gap-4 sticky top-0 z-10">
        <button onClick={() => navigate(-1)} className="text-slate-500 text-lg">Back</button>
        <h1 className="font-bold text-lg">Report Emergency</h1>
      </div>

      <div className="p-4 flex-1 overflow-y-auto pb-24">
        {/* Location Status */}
        <div className="mb-6 flex items-center gap-3 bg-blue-50 p-3 rounded-lg">
          <div className={`p-1 rounded-full ${location ? 'bg-blue-200' : 'bg-slate-200'}`}>
            <MapPin size={16} className="text-blue-700" />
          </div>
          {location ? (
            <span className="text-blue-700 text-sm">Location acquired: {location.latitude.toFixed(4)}, {location.longitude.toFixed(4)}</span>
          ) : (
            <span className="text-blue-700 text-sm">Acquiring GPS location...</span>
          )}
        </div>

        {/* Media Upload */}
        <div className="mb-6">
          <h3 className="text-sm font-medium text-slate-700 mb-2">Evidence (Photo/Video)</h3>
          <input 
            type="file" 
            accept="image/*" 
            ref={fileInputRef} 
            onChange={handleImageUpload} 
            className="hidden" 
          />
          <button 
            onClick={() => fileInputRef.current?.click()}
            className="w-full border-2 border-dashed border-slate-300 rounded-xl h-48 flex flex-col items-center justify-center bg-slate-100 overflow-hidden relative hover:bg-slate-200 transition-colors"
          >
            {image ? (
              <img src={image} alt="Evidence" className="w-full h-full object-cover" />
            ) : (
              <>
                <Camera size={32} className="text-slate-500" />
                <span className="text-sm text-slate-500 mt-2">Tap to take photo</span>
              </>
            )}
          </button>
        </div>

        {/* Description */}
        <div className="mb-6">
          <h3 className="text-sm font-medium text-slate-700 mb-2">Description</h3>
          <div className="relative">
            <textarea
              className="w-full bg-white border border-slate-300 rounded-xl p-4 min-h-[120px] text-slate-900 resize-none focus:ring-2 focus:ring-red-500 outline-none"
              placeholder="Describe the situation..."
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            />
            <button 
              onClick={handleVoiceInput}
              className="absolute bottom-3 right-3 p-2 bg-slate-100 rounded-full hover:bg-slate-200"
            >
              <Mic size={20} className="text-slate-600" />
            </button>
          </div>
        </div>

        {/* Info Box */}
        <div className="flex gap-3 items-start p-3 bg-yellow-50 rounded-lg mb-8">
          <AlertTriangle size={16} className="text-yellow-800 flex-shrink-0 mt-0.5" />
          <p className="text-xs text-yellow-800">By submitting, you agree to share your current location and media with emergency responders. False reporting is a punishable offense.</p>
        </div>
      </div>

      <div className="p-4 bg-white border-t border-slate-100 fixed bottom-0 left-0 right-0 z-20">
        <button 
          onClick={handleSubmit}
          disabled={loading || (!description && !image)}
          className={`w-full py-4 rounded-xl flex items-center justify-center gap-2 shadow-sm transition-colors ${loading || (!description && !image) ? 'bg-slate-300 cursor-not-allowed' : 'bg-red-600 hover:bg-red-700 text-white'}`}
        >
          {loading ? (
            <>
              <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
              <span className="font-bold text-lg">{analyzing ? 'Analyzing...' : 'Connecting...'}</span>
            </>
          ) : (
            <>
              <Send size={24} />
              <span className="font-bold text-lg">Request Help</span>
            </>
          )}
        </button>
      </div>
    </div>
  );
};

export default Report;