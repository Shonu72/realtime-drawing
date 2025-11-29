import { IBoard, Board, BoardRole } from '../models/Board';
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
  async getBoard(boardId: string, userId?: string): Promise<IBoard | null> {
    const board = await Board.findById(boardId);
    if (!board) {
      return null;
    }

    // Check if user has access
    if (userId) {
      const role = board.getMemberRole(userId as any);
      if (!role && !board.isPublic) {
        throw new Error('Access denied');
      }
    } else if (!board.isPublic) {
      throw new Error('Access denied');
    }

    return board;
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
}

export const boardService = new BoardService();

