# Realtime Drawing Backend

Multiplayer whiteboard backend with WebSocket support, Redis pub/sub, and MongoDB persistence.

## Features

- ✅ Real-time collaboration using Socket.IO
- ✅ Redis pub/sub for horizontal scaling
- ✅ MongoDB for data persistence
- ✅ JWT authentication
- ✅ Operational Transformation for conflict resolution
- ✅ Rate limiting and security
- ✅ Audit logging
- ✅ Role-based permissions (Admin, Editor, Viewer)

## Prerequisites

- Node.js 18+
- MongoDB 6+
- Redis 6+

## Installation

1. Install dependencies:
```bash
npm install
```

2. Create `.env` file from `.env.example`:
```bash
cp .env.example .env
```

3. Update `.env` with your configuration:
```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/realtime-drawing
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_SECRET=your-secret-key
```

## Running

Development:
```bash
npm run dev
```

Production:
```bash
npm run build
npm start
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user

### Boards
- `POST /api/boards` - Create board
- `GET /api/boards/my-boards` - Get user's boards
- `GET /api/boards/:boardId` - Get board details
- `GET /api/boards/:boardId/strokes` - Get board strokes
- `POST /api/boards/:boardId/members` - Add member
- `DELETE /api/boards/:boardId/members/:userId` - Remove member
- `PATCH /api/boards/:boardId/settings` - Update settings
- `DELETE /api/boards/:boardId` - Delete board

## WebSocket Events

### Client → Server
- `board:join` - Join a board room
- `board:leave` - Leave board room
- `stroke:draw` - Draw a stroke
- `stroke:delete` - Delete a stroke
- `cursor:move` - Update cursor position
- `chat:message` - Send chat message
- `chat:typing` - Typing indicator
- `board:clear` - Clear board (admin only)

### Server → Client
- `board:state` - Initial board state
- `stroke:created` - New stroke created
- `stroke:deleted` - Stroke deleted
- `user:joined` - User joined board
- `user:left` - User left board
- `cursor:update` - Cursor position update
- `chat:message` - Chat message received
- `chat:typing` - Typing indicator
- `board:cleared` - Board cleared
- `error` - Error message

## Architecture

- **Express.js** - HTTP server
- **Socket.IO** - WebSocket server
- **Redis** - Pub/sub for multi-instance scaling
- **MongoDB** - Data persistence
- **Operational Transformation** - Conflict resolution
- **JWT** - Authentication

## Project Structure

```
backend/
├── src/
│   ├── config/          # Database, Redis, Socket.IO setup
│   ├── models/          # MongoDB models
│   ├── services/        # Business logic
│   ├── socket/          # Socket.IO handlers
│   ├── routes/          # Express routes
│   ├── middleware/      # Auth, rate limiting, etc.
│   └── utils/           # Utilities
└── tests/               # Test files
```

