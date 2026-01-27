import React, { useState, useRef, useEffect } from 'react';
import { getFirstAidAdvice } from '../services/geminiService';
import { ChatMessage } from '../types';
import { Send, User, Bot } from 'lucide-react';

const FirstAid: React.FC = () => {
  const [query, setQuery] = useState('');
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      role: 'model',
      text: "I am ResQ, your AI emergency assistant. Describe the injury or situation, and I will guide you through the first aid steps.",
      timestamp: Date.now()
    }
  ]);
  const [loading, setLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSend = async (e?: React.FormEvent) => {
    e?.preventDefault();
    if (!query.trim()) return;

    const userMsg: ChatMessage = {
      role: 'user',
      text: query,
      timestamp: Date.now()
    };

    setMessages(prev => [...prev, userMsg]);
    setQuery('');
    setLoading(true);

    try {
      const advice = await getFirstAidAdvice(userMsg.text);
      const botMsg: ChatMessage = {
        role: 'model',
        text: advice,
        timestamp: Date.now()
      };
      setMessages(prev => [...prev, botMsg]);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col h-screen bg-slate-50 pb-20">
      <div className="bg-white p-4 border-b border-slate-200 shadow-sm sticky top-0 z-10">
        <h1 className="font-bold text-lg text-slate-800">First Aid Guide</h1>
        <p className="text-xs text-slate-500">AI-Powered Assistance</p>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((item, index) => (
          <div key={index} className={`flex gap-3 ${item.role === 'user' ? 'flex-row-reverse' : 'flex-row'}`}>
            <div className={`w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 ${item.role === 'user' ? 'bg-slate-200' : 'bg-red-100'}`}>
              {item.role === 'user' ? <User size={16} className="text-slate-600" /> : <Bot size={16} className="text-red-600" />}
            </div>
            <div 
              className={`max-w-[80%] p-4 rounded-2xl ${
                item.role === 'user' 
                  ? 'bg-slate-800 text-white rounded-tr-none' 
                  : 'bg-white border border-slate-200 text-slate-800 rounded-tl-none shadow-sm'
              }`}
            >
              <p className="text-sm leading-relaxed whitespace-pre-wrap">{item.text}</p>
            </div>
          </div>
        ))}
        
        {loading && (
          <div className="flex items-center gap-2 pl-2">
            <Bot size={16} className="text-red-600" />
            <span className="text-slate-400 text-sm">Thinking...</span>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      <div className="p-4 bg-white border-t border-slate-200 fixed bottom-16 left-0 right-0">
        <form onSubmit={handleSend} className="flex gap-2">
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Describe injury..."
            className="flex-1 bg-slate-100 rounded-full px-4 py-3 text-slate-900 outline-none focus:ring-2 focus:ring-red-500"
          />
          <button 
            type="submit"
            disabled={loading || !query.trim()}
            className={`w-12 h-12 rounded-full flex items-center justify-center transition-colors ${loading || !query.trim() ? 'bg-slate-300 cursor-not-allowed' : 'bg-red-600 hover:bg-red-700 text-white'}`}
          >
            <Send size={20} />
          </button>
        </form>
      </div>
    </div>
  );
};

export default FirstAid;