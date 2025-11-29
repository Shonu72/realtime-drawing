import { Router, Response } from 'express';
import { User } from '../models/User';
import { generateToken, authenticate, AuthRequest } from '../middleware/auth';
import { authRateLimiter } from '../middleware/rateLimiter';
import { createError } from '../middleware/errorHandler';

const router = Router();

// Register
router.post('/register', authRateLimiter, async (req: AuthRequest, res: Response) => {
  try {
    const { email, password, name } = req.body;

    if (!email || !password || !name) {
      throw createError('Email, password, and name are required', 400);
    }

    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      throw createError('User already exists', 409);
    }

    // Create user
    const user = new User({ email, password, name });
    await user.save();

    // Generate token
    const token = generateToken(user._id.toString());

    res.status(201).json({
      token,
      user: {
        id: user._id.toString(),
        email: user.email,
        name: user.name,
        avatar: user.avatar
      }
    });
  } catch (error: any) {
    if (error.statusCode) {
      res.status(error.statusCode).json({ error: error.message });
    } else {
      res.status(500).json({ error: 'Registration failed' });
    }
  }
});

// Login
router.post('/login', authRateLimiter, async (req: AuthRequest, res: Response) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      throw createError('Email and password are required', 400);
    }

    // Find user
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      throw createError('Invalid credentials', 401);
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      throw createError('Invalid credentials', 401);
    }

    // Generate token
    const token = generateToken(user._id.toString());

    res.json({
      token,
      user: {
        id: user._id.toString(),
        email: user.email,
        name: user.name,
        avatar: user.avatar
      }
    });
  } catch (error: any) {
    if (error.statusCode) {
      res.status(error.statusCode).json({ error: error.message });
    } else {
      res.status(500).json({ error: 'Login failed' });
    }
  }
});

// Get current user
router.get('/me', authenticate, async (req: AuthRequest, res: Response) => {
  res.json({
    user: {
      id: req.user?._id?.toString(),
      email: req.user?.email,
      name: req.user?.name,
      avatar: req.user?.avatar
    }
  });
});

export default router;

