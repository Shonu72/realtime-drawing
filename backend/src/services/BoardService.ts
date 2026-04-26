import { IBoard, Board, BoardRole, ILayer } from '../models/Board';
import { Stroke } from '../models/Stroke';

import { AuditLog, AuditAction } from '../models/AuditLog';
import { v4 as uuidv4 } from 'uuid';

export interface CreateBoardData {
  name: string;
  description?: string;
  ownerId: string;
  isPublic?: boolean;
  password?: string;
  settings?: {
    allowGuests?: boolean;
    maxUsers?: number;
    enableChat?: boolean;
    enableReplay?: boolean;
  };
}

export class BoardService {
  /**
   * Create a new board
   */
  async createBoard(data: CreateBoardData): Promise<IBoard> {
    const board = new Board({
      name: data.name,
      description: data.description,
      ownerId: data.ownerId,
      isPublic: data.isPublic || false,
      password: data.password,
      settings: {
        allowGuests: data.settings?.allowGuests || false,
        maxUsers: data.settings?.maxUsers || 50,
        enableChat: data.settings?.enableChat !== false,
        enableReplay: data.settings?.enableReplay !== false
      }
    });

    await board.save();

    // Log audit
    await AuditLog.create({
      boardId: board._id,
      userId: data.ownerId as any,
      action: AuditAction.BOARD_CREATED,
      details: { name: data.name }
    });

    return board;
  }

  /**
   * Get board by ID with permission check
   */
  async getBoard(boardId: string, userId?: string, password?: string): Promise<IBoard | null> {
    const board = await Board.findById(boardId).select('+password');
    if (!board) {
      return null;
    }

    // Check if user has access
    if (userId) {
      const role = board.getMemberRole(userId as any);
      if (!role) {
        // Not a member - check if it's public or password matches
        if (board.password) {
          if (!password || !(await board.comparePassword(password))) {
            const error: any = new Error('Password required');
            error.statusCode = 401;
            throw error;
          }
        } else if (!board.isPublic) {
          throw new Error('Access denied');
        }
      }
    } else if (!board.isPublic) {
      throw new Error('Access denied');
    }

    return board;
  }

  /**
   * Verify board password and add user as guest/member if correct
   */
  async verifyPassword(boardId: string, userId: string, password: string): Promise<boolean> {
    const board = await Board.findById(boardId).select('+password');
    if (!board) {
      throw new Error('Board not found');
    }

    const isValid = await board.comparePassword(password);
    if (isValid) {
      // Add as editor by default if password is correct
      board.addMember(userId as any, BoardRole.EDITOR);
      await board.save();
      
      // Log audit
      await AuditLog.create({
        boardId,
        userId,
        action: AuditAction.MEMBER_ADDED,
        details: { role: BoardRole.EDITOR, method: 'password' }
      });
    }

    return isValid;
  }

  /**
   * Add member to board
   */
  async addMember(boardId: string, userId: string, targetUserId: string, role: BoardRole): Promise<IBoard> {
    const board = await Board.findById(boardId);
    if (!board) {
      throw new Error('Board not found');
    }

    // Check permissions - only admin can add members
    const userRole = board.getMemberRole(userId as any);
    if (userRole !== BoardRole.ADMIN) {
      throw new Error('Only admin can add members');
    }

    board.addMember(targetUserId as any, role);
    await board.save();

    // Log audit
    await AuditLog.create({
      boardId,
      userId,
      action: AuditAction.MEMBER_ADDED,
      details: { targetUserId, role }
    });

    return board;
  }

  /**
   * Remove member from board
   */
  async removeMember(boardId: string, userId: string, targetUserId: string): Promise<IBoard> {
    const board = await Board.findById(boardId);
    if (!board) {
      throw new Error('Board not found');
    }

    // Check permissions
    const userRole = board.getMemberRole(userId as any);
    if (userRole !== BoardRole.ADMIN && userId !== targetUserId) {
      throw new Error('Insufficient permissions');
    }

    board.removeMember(targetUserId as any);
    await board.save();

    // Log audit
    await AuditLog.create({
      boardId,
      userId,
      action: AuditAction.MEMBER_REMOVED,
      details: { targetUserId }
    });

    return board;
  }

  /**
   * Update board settings
   */
  async updateSettings(boardId: string, userId: string, settings: Partial<IBoard['settings']>): Promise<IBoard> {
    const board = await Board.findById(boardId);
    if (!board) {
      throw new Error('Board not found');
    }

    const role = board.getMemberRole(userId as any);
    if (role !== BoardRole.ADMIN) {
      throw new Error('Only admin can update settings');
    }

    board.settings = { ...board.settings, ...settings };
    await board.save();

    // Log audit
    await AuditLog.create({
      boardId,
      userId,
      action: AuditAction.SETTINGS_UPDATED,
      details: { settings }
    });

    return board;
  }

  /**
   * Get user's boards
   */
  async getUserBoards(userId: string): Promise<IBoard[]> {
    return Board.find({
      $or: [
        { ownerId: userId },
        { 'members.userId': userId }
      ]
    })
      .sort({ updatedAt: -1 })
      .populate('ownerId', 'name avatar')
      .lean();
  }

  /**
   * Delete board
   */
  async deleteBoard(boardId: string, userId: string): Promise<void> {
    const board = await Board.findById(boardId);
    if (!board) {
      throw new Error('Board not found');
    }

    if (board.ownerId.toString() !== userId) {
      throw new Error('Only owner can delete board');
    }

    await Board.deleteOne({ _id: boardId });

    // Log audit
    await AuditLog.create({
      boardId,
      userId,
      action: AuditAction.BOARD_DELETED,
      details: {}
    });
  }

  /**
   * Add a new layer to the board
   */
  async addLayer(boardId: string, userId: string, name: string): Promise<IBoard> {
    const board = await Board.findById(boardId);
    if (!board) throw new Error('Board not found');

    const role = board.getMemberRole(userId as any);
    if (role !== BoardRole.ADMIN && role !== BoardRole.EDITOR) {
      throw new Error('Insufficient permissions');
    }

    const newLayer = {
      id: uuidv4(),
      name,
      isVisible: true,
      isLocked: false,
      opacity: 1.0
    };

    board.layers.push(newLayer);
    await board.save();

    return board;
  }

  /**
   * Update layer properties
   */
  async updateLayer(
    boardId: string,
    userId: string,
    layerId: string,
    updates: Partial<ILayer>
  ): Promise<IBoard> {
    const board = await Board.findById(boardId);
    if (!board) throw new Error('Board not found');

    const role = board.getMemberRole(userId as any);
    if (role !== BoardRole.ADMIN && role !== BoardRole.EDITOR) {
      throw new Error('Insufficient permissions');
    }

    const layerIndex = board.layers.findIndex(l => l.id === layerId);
    if (layerIndex === -1) throw new Error('Layer not found');

    board.layers[layerIndex] = { ...board.layers[layerIndex], ...updates };
    await board.save();

    return board;
  }

  /**
   * Delete a layer and move its strokes to default
   */
  async deleteLayer(boardId: string, userId: string, layerId: string): Promise<IBoard> {
    if (layerId === 'default') throw new Error('Cannot delete default layer');

    const board = await Board.findById(boardId);
    if (!board) throw new Error('Board not found');

    const role = board.getMemberRole(userId as any);
    if (role !== BoardRole.ADMIN) throw new Error('Only admin can delete layers');

    board.layers = board.layers.filter(l => l.id !== layerId);
    await board.save();

    // Move strokes to default layer
    await Stroke.updateMany(
      { boardId, layerId },
      { $set: { layerId: 'default' } }
    );

    return board;
  }
}

export const boardService = new BoardService();

