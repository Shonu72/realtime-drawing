import { Server as SocketIOServer, Socket } from 'socket.io';
import { AuthSocket } from '../middleware/auth';
import { strokeService } from '../services/StrokeService';
import { boardService } from '../services/BoardService';
import { BoardRole } from '../models/Board';
import { socketRateLimiter } from '../middleware/rateLimiter';

interface RoomUser {
  userId: string;
  socketId: string;
  name: string;
  avatar?: string;
  cursor?: { x: number; y: number };
  color: string;
}

const roomUsers = new Map<string, Map<string, RoomUser>>(); // boardId -> socketId -> user
const userColors = new Map<string, string>(); // userId -> color

// Generate color for user
const getUserColor = (userId: string): string => {
  if (!userColors.has(userId)) {
    const colors = [
      '#FF6B6B', '#4ECDC4', '#45B7D1', '#FFA07A',
      '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E2',
      '#F8B739', '#6C5CE7', '#A29BFE', '#FD79A8'
    ];
    const index = userColors.size % colors.length;
    userColors.set(userId, colors[index]);
  }
  return userColors.get(userId)!;
};

export const setupSocketHandlers = (io: SocketIOServer, socket: AuthSocket): void => {
  const userId = socket.data.userId;
  const user = socket.data.user;
  let currentBoardId: string | null = null;

  // Rate limiting tracking
  const eventCounts = new Map<string, number>();
  const resetInterval = setInterval(() => {
    eventCounts.clear();
  }, 1000);

  socket.on('disconnect', () => {
    clearInterval(resetInterval);
    if (currentBoardId) {
      leaveBoard(currentBoardId);
    }
  });

  // Join board room
  socket.on('board:join', async (data: { boardId: string }) => {
    try {
      const { boardId } = data;

      // Check rate limiting
      const count = eventCounts.get('board:join') || 0;
      if (count > socketRateLimiter.maxEventsPerSecond) {
        socket.emit('error', { message: 'Rate limit exceeded' });
        return;
      }
      eventCounts.set('board:join', count + 1);

      // Verify board access
      const board = await boardService.getBoard(boardId, userId);
      if (!board) {
        socket.emit('error', { message: 'Board not found' });
        return;
      }

      // Leave previous board if any
      if (currentBoardId && currentBoardId !== boardId) {
        leaveBoard(currentBoardId);
      }

      currentBoardId = boardId;
      socket.join(`board:${boardId}`);

      // Add user to room
      if (!roomUsers.has(boardId)) {
        roomUsers.set(boardId, new Map());
      }
      
      const userInfo: RoomUser = {
        userId,
        socketId: socket.id,
        name: user.name,
        avatar: user.avatar,
        color: getUserColor(userId)
      };
      
      roomUsers.get(boardId)!.set(socket.id, userInfo);

      // Notify others
      socket.to(`board:${boardId}`).emit('user:joined', {
        userId,
        name: user.name,
        avatar: user.avatar,
        color: userInfo.color
      });

      // Send current board state
      const strokes = await strokeService.getStrokes(boardId);
      const users = Array.from(roomUsers.get(boardId)!.values());

      socket.emit('board:state', {
        strokes,
        users: users.map(u => ({
          userId: u.userId,
          name: u.name,
          avatar: u.avatar,
          color: u.color,
          cursor: u.cursor
        }))
      });

      console.log(`✅ User ${userId} joined board ${boardId}`);
    } catch (error: any) {
      socket.emit('error', { message: error.message });
    }
  });

  // Leave board
  const leaveBoard = (boardId: string) => {
    socket.leave(`board:${boardId}`);
    
    const boardUsers = roomUsers.get(boardId);
    if (boardUsers) {
      const userInfo = boardUsers.get(socket.id);
      if (userInfo) {
        boardUsers.delete(socket.id);
        
        // Notify others
        socket.to(`board:${boardId}`).emit('user:left', {
          userId: userInfo.userId
        });

        // Clean up if room is empty
        if (boardUsers.size === 0) {
          roomUsers.delete(boardId);
        }
      }
    }
  };

  socket.on('board:leave', () => {
    if (currentBoardId) {
      leaveBoard(currentBoardId);
      currentBoardId = null;
    }
  });

  // Cursor movement
  socket.on('cursor:move', (data: { boardId: string; x: number; y: number }) => {
    if (!currentBoardId || data.boardId !== currentBoardId) return;

    const boardUsers = roomUsers.get(data.boardId);
    if (boardUsers) {
      const userInfo = boardUsers.get(socket.id);
      if (userInfo) {
        userInfo.cursor = { x: data.x, y: data.y };
        socket.to(`board:${data.boardId}`).emit('cursor:update', {
          userId,
          x: data.x,
          y: data.y
        });
      }
    }
  });

  // Draw stroke
  socket.on('stroke:draw', async (data: any) => {
    try {
      if (!currentBoardId || data.boardId !== currentBoardId) {
        socket.emit('error', { message: 'Not in board' });
        return;
      }

      // Rate limiting for draw events
      const count = eventCounts.get('stroke:draw') || 0;
      if (count > socketRateLimiter.maxEventsPerSecond) {
        return; // Silently drop if rate limited
      }
      eventCounts.set('stroke:draw', count + 1);

      const stroke = await strokeService.createStroke({
        ...data,
        userId
      });

      // Broadcast to all users in board (including sender for confirmation)
      io.to(`board:${currentBoardId}`).emit('stroke:created', {
        stroke: {
          ...stroke.toObject(),
          user: {
            name: user.name,
            avatar: user.avatar
          }
        }
      });
    } catch (error: any) {
      socket.emit('error', { message: error.message });
    }
  });

  // Delete stroke
  socket.on('stroke:delete', async (data: { boardId: string; strokeId: string }) => {
    try {
      if (!currentBoardId || data.boardId !== currentBoardId) {
        return;
      }

      await strokeService.deleteStroke(data.strokeId, data.boardId, userId);

      io.to(`board:${currentBoardId}`).emit('stroke:deleted', {
        strokeId: data.strokeId
      });
    } catch (error: any) {
      socket.emit('error', { message: error.message });
    }
  });

  // Clear board
  socket.on('board:clear', async (data: { boardId: string }) => {
    try {
      if (!currentBoardId || data.boardId !== currentBoardId) {
        return;
      }

      await strokeService.clearBoard(data.boardId, userId);

      io.to(`board:${currentBoardId}`).emit('board:cleared', {
        clearedBy: userId
      });
    } catch (error: any) {
      socket.emit('error', { message: error.message });
    }
  });

  // Chat message
  socket.on('chat:message', async (data: { boardId: string; message: string }) => {
    try {
      if (!currentBoardId || data.boardId !== currentBoardId) {
        return;
      }

      const board = await boardService.getBoard(data.boardId, userId);
      if (!board || !board.settings.enableChat) {
        socket.emit('error', { message: 'Chat disabled' });
        return;
      }

      io.to(`board:${data.boardId}`).emit('chat:message', {
        userId,
        name: user.name,
        avatar: user.avatar,
        message: data.message,
        timestamp: Date.now()
      });
    } catch (error: any) {
      socket.emit('error', { message: error.message });
    }
  });

  // Typing indicator
  socket.on('chat:typing', (data: { boardId: string; isTyping: boolean }) => {
    if (!currentBoardId || data.boardId !== currentBoardId) return;
    
    socket.to(`board:${data.boardId}`).emit('chat:typing', {
      userId,
      name: user.name,
      isTyping: data.isTyping
    });
  });
};

