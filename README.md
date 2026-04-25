<div align="center">
  <img width="1200" height="400" alt="ResQ Banner" src="https://github.com/user-attachments/assets/0aa67016-6eaf-458a-adb2-6e31a0763ed6" />
  <h1>ResQ: AI-Powered Emergency Response Platform</h1>
  <p>Bridging the Gap in Emergency Response through Hybrid AI and Real-time Tracking</p>
</div>

---

## 📌 Project Overview
**ResQ** is a comprehensive mobile ecosystem designed to accelerate emergency response times and provide life-saving first-aid guidance. Built with Flutter, it connects Victims, Emergency Responders, and Administrators in a seamless real-time environment.

### Key Highlights
- **Hybrid AI Engine**: Real-time injury classification using **Google Gemini** (Online) and **TensorFlow Lite** (Offline).
- **One-Tap SOS**: Instant emergency triggering with automated location sharing and RESQ-ID generation.
- **Real-time Navigation**: Live responder tracking using OpenStreetMap and GPS services.
- **Offline Reliability**: Full access to first-aid guides and AI analysis even without internet connectivity.

---

## Key Features

###  Citizens (Victims)
- **Instant SOS**: Send alerts with high-accuracy GPS coordinates.
- **AI Injury Analysis**: Upload photos to receive immediate first-aid instructions based on injury severity.
- **Live Responder Tracking**: See the real-time location of the assigned responder on a map.
- **Voice-Enabled First Aid**: Search and listen to first-aid guides hands-free.

###  Responders
- **Emergency Feed**: View active requests nearby with distance and urgency indicators.
- **Live Navigation**: Integrated map routing to the incident location.
- **Real-time Chat**: Communicate directly with the victim during transit.

###  Administrators
- **Verification System**: Review and approve responder certifications.
- **AI Metrics**: Monitor the performance and accuracy of AI evaluations.
- **Platform Analytics**: Analyze response times and emergency trends.

---

##  Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Authentication, Storage)
- **AI/ML**: Google Generative AI (Gemini Pro), TensorFlow Lite
- **Maps**: Flutter Map, OpenStreetMap API
- **State Management**: Provider

---

## ⚙️ Getting Started

### Prerequisites
- Flutter SDK (latest version)
- Android Studio / VS Code
- A Firebase Project (configured for Android/iOS)

### Installation
1. **Clone the repository**:
   ```bash
   git clone https://github.com/Nimeshkaushalya/ResQ.git
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Setup Environment Variables**:
   Create a `.env` file in the root directory and add your API keys:
   ```env
   GEMINI_API_KEY=your_api_key_here
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   ```
4. **Generate App Icons**:
   ```bash
   dart run flutter_launcher_icons
   ```
5. **Run the app**:
   ```bash
   flutter run
   ```

---

## 📂 Architecture
The project follows a **Layered Service-Oriented Architecture**:
- `lib/screens/`: Presentation Layer (UI)
- `lib/services/`: Business Logic & External Integrations
- `lib/models/`: Data Layer & State Objects
- `lib/widgets/`: Reusable UI Components

---

<div align="center">
  <p>© 2026 ResQ Emergency Response Team</p>
</div>
