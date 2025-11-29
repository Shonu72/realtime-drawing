import compression from 'compression';
import cors from 'cors';
import dotenv from 'dotenv';
import express from 'express';
import helmet from 'helmet';
import { createServer } from 'http';
import { connectDatabase } from './config/database';
import { connectRedis } from './config/redis';
import { configureRedisAdapter, setupSocketIO } from './config/socket';
import { errorHandler } from './middleware/errorHandler';
import { rateLimiter } from './middleware/rateLimiter';
import authRoutes from './routes/auth';
import boardRoutes from './routes/board';

dotenv.config();

const app = express();
const httpServer = createServer(app);
const io = setupSocketIO(httpServer);

const PORT = process.env.PORT || 3000;
const CORS_ORIGIN = process.env.CORS_ORIGIN || 'http://localhost:8080';

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors({
  origin: CORS_ORIGIN.split(','),
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate limiting
app.use('/api/', rateLimiter);

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/boards', boardRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Error handling
app.use(errorHandler);

// Initialize connections
async function startServer() {
  try {
    await connectDatabase();
    await connectRedis();
    configureRedisAdapter(); // Configure Redis adapter after connection
    
    httpServer.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`📡 Socket.IO server ready`);
      console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();

export { io };

