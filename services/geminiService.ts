import { GoogleGenAI } from "@google/genai";

const getAiClient = () => {
  const apiKey = process.env.API_KEY;
  if (!apiKey) {
    console.error("API_KEY is not defined in environment variables.");
    // In a real app, you would handle this gracefully.
    throw new Error("API_KEY is missing");
  }
  return new GoogleGenAI({ apiKey });
};

export const getFirstAidAdvice = async (query: string): Promise<string> => {
  try {
    const ai = getAiClient();
    const response = await ai.models.generateContent({
      model: 'gemini-3-flash-preview',
      contents: query,
      config: {
        systemInstruction: `You are ResQ, an intelligent emergency first aid assistant. 
        Provide clear, concise, step-by-step first aid instructions for the user's situation. 
        If the situation sounds life-threatening (e.g., no breathing, severe bleeding, chest pain), start by IMMEDIATELY telling the user to call emergency services.
        Use bullet points for steps. Keep it simple and reassuring.`,
        temperature: 0.4,
      }
    });
    return response.text || "I apologize, I could not generate advice at this moment. Please call emergency services immediately.";
  } catch (error) {
    console.error("Gemini API Error:", error);
    return "Network error or API Key issue. Please call emergency services immediately.";
  }
};

export const analyzeIncident = async (description: string, imageBase64?: string): Promise<string> => {
  try {
    const ai = getAiClient();
    
    let parts: any[] = [{ text: `Analyze this emergency situation report and provide a brief summary for first responders. 
    Assess severity (High/Medium/Low) and suggest immediate equipment needed. 
    Report Description: ${description}` }];

    if (imageBase64) {
      // Ensure the base64 string is clean (remove data:image/... prefix if present)
      const cleanBase64 = imageBase64.includes(',') ? imageBase64.split(',')[1] : imageBase64;
      
      parts = [
        {
          inlineData: {
            mimeType: 'image/jpeg',
            data: cleanBase64
          }
        },
        ...parts
      ];
    }

    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash-image',
      contents: { parts },
    });
    return response.text || "Analysis pending...";
  } catch (error) {
    console.error("Gemini Analysis Error:", error);
    return "Could not analyze incident due to network error.";
  }
};