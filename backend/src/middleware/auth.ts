import { Request, Response, NextFunction } from 'express';
import { Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { User } from '../models/User';

export interface AuthRequest extends Request {
  userId?: string;
  user?: any;
}

export interface AuthSocket extends Socket {
  data: {
    userId: string;
    user?: any;
  };
}

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// Express middleware for JWT authentication
export const authenticate = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '') || 
                  req.cookies?.token;

    if (!token) {
      res.status(401).json({ error: 'Authentication required' });
      return;
    }

    const decoded = jwt.verify(token, JWT_SECRET) as { userId: string };
    const user = await User.findById(decoded.userId).select('-password');

    if (!user) {
      res.status(401).json({ error: 'User not found' });
      return;
    }

    req.userId = decoded.userId;
    req.user = user;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
};

// Socket.IO middleware for JWT authentication
export const authenticateSocket = async (
  socket: Socket,
  next: (err?: Error) => void
): Promise<void> => {
  try {
    const token = socket.handshake.auth?.token || 
                  socket.handshake.headers?.authorization?.replace('Bearer ', '');

    if (!token) {
      return next(new Error('Authentication required'));
    }

    const decoded = jwt.verify(token, JWT_SECRET) as { userId: string };
    const user = await User.findById(decoded.userId).select('-password');

    if (!user) {
      return next(new Error('User not found'));
    }

    (socket as AuthSocket).data.userId = decoded.userId;
    (socket as AuthSocket).data.user = user;
    next();
  } catch (error) {
    next(new Error('Invalid or expired token'));
  }
};

// Generate JWT token
export const generateToken = (userId: string): string => {
  return jwt.sign(
    { userId },
    JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
};

