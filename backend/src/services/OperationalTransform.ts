import { IStroke } from '../models/Stroke';

export interface Operation {
  type: 'add' | 'delete' | 'modify';
  strokeId: string;
  stroke?: IStroke;
  timestamp: number;
  version: number;
  userId: string;
}

/**
 * Operational Transformation (OT) for conflict-free collaborative editing
 * Handles concurrent operations on strokes with proper ordering and conflict resolution
 */
export class OperationalTransform {
  private operationLog: Map<string, Operation[]> = new Map(); // boardId -> operations

  /**
   * Transform an operation against a list of concurrent operations
   */
  transform(operation: Operation, concurrentOps: Operation[]): Operation {
    let transformedOp = { ...operation };

    for (const concurrentOp of concurrentOps) {
      if (concurrentOp.strokeId === transformedOp.strokeId) {
        // Same stroke - need to resolve conflict
        if (concurrentOp.type === 'delete' && transformedOp.type !== 'delete') {
          // If concurrent op deleted the stroke, mark as deleted
          transformedOp.type = 'delete';
        } else if (concurrentOp.type === 'add' && transformedOp.type === 'add') {
          // Both adding - use timestamp to determine order
          if (concurrentOp.timestamp < transformedOp.timestamp) {
            transformedOp.version = concurrentOp.version + 1;
          }
        }
      } else if (concurrentOp.timestamp < transformedOp.timestamp) {
        // Earlier operation - increment version
        transformedOp.version = Math.max(transformedOp.version, concurrentOp.version);
      }
    }

    return transformedOp;
  }

  /**
   * Add operation to log and return transformed version
   */
  addOperation(boardId: string, operation: Operation): Operation {
    if (!this.operationLog.has(boardId)) {
      this.operationLog.set(boardId, []);
    }

    const log = this.operationLog.get(boardId)!;
    const concurrentOps = log.filter(
      op => op.timestamp >= operation.timestamp - 1000 && // Within 1 second
            op.userId !== operation.userId
    );

    const transformedOp = this.transform(operation, concurrentOps);
    transformedOp.version = log.length;
    
    log.push(transformedOp);
    
    // Keep only last 1000 operations per board
    if (log.length > 1000) {
      log.shift();
    }

    return transformedOp;
  }

  /**
   * Get operation history for a board
   */
  getOperationHistory(boardId: string, sinceTimestamp?: number): Operation[] {
    const log = this.operationLog.get(boardId) || [];
    
    if (sinceTimestamp) {
      return log.filter(op => op.timestamp > sinceTimestamp);
    }
    
    return log;
  }

  /**
   * Clear operation log for a board
   */
  clearBoardLog(boardId: string): void {
    this.operationLog.delete(boardId);
  }
}

export const operationalTransform = new OperationalTransform();

