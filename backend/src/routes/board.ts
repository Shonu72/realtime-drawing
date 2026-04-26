import { Router, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { boardService } from '../services/BoardService';
import { strokeService } from '../services/StrokeService';
import { chatService } from '../services/ChatService';
import { createError } from '../middleware/errorHandler';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Create board
router.post('/', async (req: AuthRequest, res: Response) => {
  try {
    const board = await boardService.createBoard({
      ...req.body,
      ownerId: req.userId!
    });

    res.status(201).json({ board });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get user's boards
router.get('/my-boards', async (req: AuthRequest, res: Response) => {
  try {
    const boards = await boardService.getUserBoards(req.userId!);
    res.json({ boards });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get board by ID
router.get('/:boardId', async (req: AuthRequest, res: Response) => {
  try {
    const board = await boardService.getBoard(req.params.boardId, req.userId);
    if (!board) {
      throw createError('Board not found', 404);
    }
    res.json({ board });
  } catch (error: any) {
    res.status(error.statusCode || 500).json({ error: error.message });
  }
});

// Get board strokes
router.get('/:boardId/strokes', async (req: AuthRequest, res: Response) => {
  try {
    const includeDeleted = req.query.includeDeleted === 'true';
    const strokes = await strokeService.getStrokes(req.params.boardId, includeDeleted);
    res.json({ strokes });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Add member to board
router.post('/:boardId/members', async (req: AuthRequest, res: Response) => {
  try {
    const { userId, role } = req.body;
    const board = await boardService.addMember(
      req.params.boardId,
      req.userId!,
      userId,
      role
    );
    res.json({ board });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Remove member from board
router.delete('/:boardId/members/:userId', async (req: AuthRequest, res: Response) => {
  try {
    const board = await boardService.removeMember(
      req.params.boardId,
      req.userId!,
      req.params.userId
    );
    res.json({ board });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Update board settings
router.patch('/:boardId/settings', async (req: AuthRequest, res: Response) => {
  try {
    const board = await boardService.updateSettings(
      req.params.boardId,
      req.userId!,
      req.body
    );
    res.json({ board });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Delete board
router.delete('/:boardId', async (req: AuthRequest, res: Response) => {
  try {
    await boardService.deleteBoard(req.params.boardId, req.userId!);
    res.json({ message: 'Board deleted successfully' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Verify board password
router.post('/:boardId/verify-password', async (req: AuthRequest, res: Response) => {
  try {
    const { password } = req.body;
    const isValid = await boardService.verifyPassword(
      req.params.boardId,
      req.userId!,
      password
    );

    if (isValid) {
      res.json({ success: true, message: 'Password verified' });
    } else {
      res.status(401).json({ success: false, error: 'Invalid password' });
    }
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Layers management
router.post('/:boardId/layers', async (req: AuthRequest, res: Response) => {
  try {
    const { name } = req.body;
    const board = await boardService.addLayer(req.params.boardId, req.userId!, name);
    res.status(201).json({ board });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

router.patch('/:boardId/layers/:layerId', async (req: AuthRequest, res: Response) => {
  try {
    const board = await boardService.updateLayer(
      req.params.boardId,
      req.userId!,
      req.params.layerId,
      req.body
    );
    res.json({ board });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

router.delete('/:boardId/layers/:layerId', async (req: AuthRequest, res: Response) => {
  try {
    const board = await boardService.deleteLayer(
      req.params.boardId,
      req.userId!,
      req.params.layerId
    );
    res.json({ board });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Chat history
router.get('/:boardId/chat', async (req: AuthRequest, res: Response) => {
  try {
    const messages = await chatService.getChatHistory(req.params.boardId);
    res.json({ messages });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

export default router;

