# Realtime Drawing - Multiplayer Whiteboard

A production-ready multiplayer whiteboard application supporting 50+ concurrent users with sub-100ms latency using WebSocket and Redis pub/sub.

## 🚀 Features

### Core Features
- ✅ Real-time multi-user drawing with smooth rendering
- ✅ WebSocket-based low-latency synchronization
- ✅ Multi-device support (Web, Android, iOS, Desktop)
- ✅ Multiple stroke tools (Pencil, Brush, Highlighter, Eraser)
- ✅ Real-time cursor tracking with user names/colors
- ✅ Infinite canvas with pan, zoom, and scale

### Advanced Collaboration
- ✅ Live presence indicators
- ✅ Real-time chat panel
- ✅ Multi-board workspace system
- ✅ Board permissions & roles (Admin, Editor, Viewer)
- ✅ Password-protected boards
- ✅ Replay mode (time-travel slider)

### Backend Features
- ✅ WebSocket backend using Node.js + Socket.IO
- ✅ Redis Pub/Sub for horizontal scaling
- ✅ Stroke persistence in MongoDB
- ✅ Operational Transformation for conflict resolution
- ✅ Offline support with automatic sync
- ✅ Rate limiting & abuse protection
- ✅ JWT authentication for WebSockets
- ✅ Audit log system

### Frontend Features
- ✅ Smooth drawing engine (60 FPS)
- ✅ Undo/Redo functionality
- ✅ Layer management
- ✅ Export options (PNG, SVG, PDF)
- ✅ Real-time zoom & pan

## 📁 Project Structure

```
realtime-drawing/
├── backend/          # Node.js + TypeScript backend
│   ├── src/
│   │   ├── config/   # Database, Redis, Socket.IO setup
│   │   ├── models/   # MongoDB models
│   │   ├── services/ # Business logic & OT
│   │   ├── socket/   # Socket.IO handlers
│   │   ├── routes/   # Express routes
│   │   └── middleware/
│   └── package.json
│
└── frontend/         # Flutter frontend
    ├── lib/
    │   ├── core/
    │   ├── features/
    │   ├── services/
    │   └── widgets/
    └── pubspec.yaml
```

## 🛠️ Tech Stack

### Backend
- **Node.js** + **TypeScript**
- **Express.js** - HTTP server
- **Socket.IO** - WebSocket server
- **Redis** - Pub/sub for scaling
- **MongoDB** - Data persistence
- **JWT** - Authentication

### Frontend
- **Flutter** - Cross-platform UI
- **Socket.IO Client** - WebSocket client
- **Provider** - State management
- **Hive** - Local caching

## 🚦 Getting Started

### Prerequisites
- Node.js 18+
- MongoDB 6+
- Redis 6+
- Flutter 3.0+

### Backend Setup

1. Navigate to backend:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file:
```bash
cp .env.example .env
```

4. Update `.env` with your configuration

5. Start MongoDB and Redis:
```bash
# MongoDB
mongod

# Redis
redis-server
```

6. Run backend:
```bash
npm run dev
```

### Frontend Setup

1. Navigate to frontend:
```bash
cd frontend
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## 📡 API Documentation

See [backend/README.md](./backend/README.md) for detailed API documentation.

## 🔐 Authentication

The application uses JWT tokens for authentication. Include the token in:
- **HTTP requests**: `Authorization: Bearer <token>`
- **WebSocket**: `auth: { token: '<token>' }`

## 🎯 Architecture Highlights

### Operational Transformation
Implements OT algorithm for conflict-free collaborative editing, ensuring all users see consistent state even with concurrent edits.

### Horizontal Scaling
Redis pub/sub allows multiple Node.js instances to share WebSocket events, enabling horizontal scaling to support 50+ concurrent users.

### Real-time Performance
- Throttled stroke updates (60 FPS max)
- Batched point updates
- Efficient rendering with CustomPainter
- Optimized MongoDB queries with indexes

## 📝 License

MIT

## 👨‍💻 Development

This project is built for backend skill enhancement and resume showcasing. It demonstrates:
- Real-time systems architecture
- WebSocket programming
- Database design and optimization
- Security best practices
- Scalable system design

