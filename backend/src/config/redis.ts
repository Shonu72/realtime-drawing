import { createClient } from 'redis';
import { createAdapter } from '@socket.io/redis-adapter';

let redisClient: ReturnType<typeof createClient> | null = null;
let redisSubscriber: ReturnType<typeof createClient> | null = null;

export const connectRedis = async (): Promise<void> => {
  try {
    const redisHost = process.env.REDIS_HOST || 'localhost';
    const redisPort = parseInt(process.env.REDIS_PORT || '6379');
    const redisPassword = process.env.REDIS_PASSWORD || undefined;

    const redisUrl = redisPassword 
      ? `redis://:${redisPassword}@${redisHost}:${redisPort}`
      : `redis://${redisHost}:${redisPort}`;

    redisClient = createClient({ url: redisUrl });
    redisSubscriber = redisClient.duplicate();

    redisClient.on('error', (err) => console.error('Redis Client Error:', err));
    redisSubscriber.on('error', (err) => console.error('Redis Subscriber Error:', err));

    await Promise.all([
      redisClient.connect(),
      redisSubscriber.connect()
    ]);

    console.log('✅ Redis connected successfully');
  } catch (error) {
    console.error('❌ Failed to connect to Redis:', error);
    throw error;
  }
};

export const getRedisClient = () => {
  if (!redisClient) {
    throw new Error('Redis client not initialized');
  }
  return redisClient;
};

export const getRedisSubscriber = () => {
  if (!redisSubscriber) {
    throw new Error('Redis subscriber not initialized');
  }
  return redisSubscriber;
};

export const getRedisAdapter = () => {
  if (!redisClient || !redisSubscriber) {
    throw new Error('Redis clients not initialized');
  }
  return createAdapter(redisClient, redisSubscriber);
};

