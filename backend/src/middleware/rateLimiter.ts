import rateLimit from 'express-rate-limit';

const windowMs = parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000');
const maxRequests = parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100');

export const rateLimiter = rateLimit({
  windowMs,
  max: maxRequests,
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    // Skip rate limiting for health checks
    return req.path === '/health';
  }
});

// Stricter rate limiter for authentication endpoints
export const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 requests per window
  message: 'Too many authentication attempts, please try again later.',
  standardHeaders: true,
  legacyHeaders: false
});

// Rate limiter for socket connections (handled separately in socket handlers)
export const socketRateLimiter = {
  maxConnectionsPerIP: 10,
  maxEventsPerSecond: 50
};

