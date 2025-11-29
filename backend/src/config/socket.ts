import { Server as HTTPServer } from 'http';
import { Server as SocketIOServer, Socket } from 'socket.io';
import { getRedisAdapter } from './redis';
import { authenticateSocket } from '../middleware/auth';
import { setupSocketHandlers } from '../socket/socketHandlers';

let ioInstance: SocketIOServer | null = null;

export const setupSocketIO = (httpServer: HTTPServer): SocketIOServer => {
  const io = new SocketIOServer(httpServer, {
    cors: {
      origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:8080'],
      credentials: true,
      methods: ['GET', 'POST']
    },
    transports: ['websocket', 'polling'],
    pingTimeout: 60000,
    pingInterval: 25000
  });

  ioInstance = io;

  // Authentication middleware
  io.use(authenticateSocket);

  // Connection handler
  io.on('connection', (socket: Socket) => {
    console.log(`🔌 Client connected: ${socket.id} (User: ${socket.data.userId})`);
    
    setupSocketHandlers(io, socket);

    socket.on('disconnect', (reason) => {
      console.log(`🔌 Client disconnected: ${socket.id} (Reason: ${reason})`);
    });
  });

  return io;
};

// Configure Redis adapter after Redis connection is established
export const configureRedisAdapter = (): void => {
  if (!ioInstance) {
    console.warn('⚠️  Socket.IO instance not initialized');
    return;
  }

  try {
    const adapter = getRedisAdapter();
    ioInstance.adapter(adapter);
    console.log('✅ Redis adapter configured for Socket.IO');
  } catch (error) {
    console.warn('⚠️  Redis adapter not available, using default adapter');
  }
};

