import { IStroke, Stroke } from '../models/Stroke';
import { Board, BoardRole } from '../models/Board';
import { AuditLog, AuditAction } from '../models/AuditLog';
import { operationalTransform } from './OperationalTransform';
import { v4 as uuidv4 } from 'uuid';

export interface CreateStrokeData {
  id: string;
  boardId: string;
  userId: string;
  tool: string;
  points: Array<{ x: number; y: number; pressure?: number; timestamp: number }>;
  color: string;
  width: number;
  layerId?: string;
}

export class StrokeService {
  /**
   * Create a new stroke
   */
  async createStroke(data: CreateStrokeData): Promise<IStroke> {
    const board = await Board.findById(data.boardId);
    if (!board) {
      throw new Error('Board not found');
    }

    // Check permissions
    const role = board.getMemberRole(data.userId as any);
    if (!role || role === BoardRole.VIEWER) {
      throw new Error('Insufficient permissions to draw');
    }

    const timestamp = Date.now();
    
    // Apply Operational Transformation
    const operation = operationalTransform.addOperation(data.boardId, {
      type: 'add',
      strokeId: data.id,
      timestamp,
      version: 0,
      userId: data.userId
    });

    const stroke = new Stroke({
      id: data.id || uuidv4(),
      boardId: data.boardId,
      userId: data.userId,
      tool: data.tool,
      points: data.points,
      color: data.color,
      width: data.width,
      layerId: data.layerId || 'default',
      timestamp: operation.timestamp,
      version: operation.version,
      deleted: false
    });

    await stroke.save();
    return stroke;
  }

  /**
   * Delete a stroke (soft delete for undo support)
   */
  async deleteStroke(strokeId: string, boardId: string, userId: string): Promise<IStroke> {
    const stroke = await Stroke.findOne({ id: strokeId, boardId });
    if (!stroke) {
      throw new Error('Stroke not found');
    }

    const board = await Board.findById(boardId);
    if (!board) {
      throw new Error('Board not found');
    }

    // Check permissions - only admin or stroke owner can delete
    const role = board.getMemberRole(userId as any);
    if (role !== BoardRole.ADMIN && stroke.userId.toString() !== userId) {
      throw new Error('Insufficient permissions to delete stroke');
    }

    // Apply OT
    const operation = operationalTransform.addOperation(boardId, {
      type: 'delete',
      strokeId,
      timestamp: Date.now(),
      version: stroke.version + 1,
      userId
    });

    stroke.deleted = true;
    stroke.version = operation.version;
    await stroke.save();

    // Log audit
    await AuditLog.create({
      boardId,
      userId,
      action: AuditAction.STROKE_DELETED,
      details: { strokeId }
    });

    return stroke;
  }

  /**
   * Get all strokes for a board
   */
  async getStrokes(boardId: string, includeDeleted: boolean = false): Promise<IStroke[]> {
    const query: any = { boardId, deleted: false };
    
    if (includeDeleted) {
      delete query.deleted;
    }

    return Stroke.find(query)
      .sort({ timestamp: 1 })
      .populate('userId', 'name avatar')
      .lean();
  }

  /**
   * Get strokes since a specific timestamp (for incremental sync)
   */
  async getStrokesSince(boardId: string, sinceTimestamp: number): Promise<IStroke[]> {
    return Stroke.find({
      boardId,
      timestamp: { $gt: sinceTimestamp },
      deleted: false
    })
      .sort({ timestamp: 1 })
      .populate('userId', 'name avatar')
      .lean();
  }

  /**
   * Clear all strokes from a board (admin only)
   */
  async clearBoard(boardId: string, userId: string): Promise<void> {
    const board = await Board.findById(boardId);
    if (!board) {
      throw new Error('Board not found');
    }

    const role = board.getMemberRole(userId as any);
    if (role !== BoardRole.ADMIN) {
      throw new Error('Only admin can clear board');
    }

    // Soft delete all strokes
    await Stroke.updateMany(
      { boardId, deleted: false },
      { $set: { deleted: true } }
    );

    // Clear OT log
    operationalTransform.clearBoardLog(boardId);

    // Log audit
    await AuditLog.create({
      boardId,
      userId,
      action: AuditAction.BOARD_CLEARED,
      details: {}
    });
  }

  /**
   * Undo last stroke by user
   */
  async undoStroke(boardId: string, userId: string): Promise<IStroke | null> {
    const lastStroke = await Stroke.findOne({
      boardId,
      userId,
      deleted: false
    }).sort({ timestamp: -1 });

    if (!lastStroke) {
      return null;
    }

    return this.deleteStroke(lastStroke.id, boardId, userId);
  }
}

export const strokeService = new StrokeService();

