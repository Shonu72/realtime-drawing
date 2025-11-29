import mongoose, { Document, Schema } from 'mongoose';

export enum AuditAction {
  BOARD_CREATED = 'board_created',
  BOARD_DELETED = 'board_deleted',
  BOARD_CLEARED = 'board_cleared',
  STROKE_DELETED = 'stroke_deleted',
  MEMBER_ADDED = 'member_added',
  MEMBER_REMOVED = 'member_removed',
  ROLE_CHANGED = 'role_changed',
  SETTINGS_UPDATED = 'settings_updated'
}

export interface IAuditLog extends Document {
  boardId: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  action: AuditAction;
  details?: Record<string, any>;
  ipAddress?: string;
  userAgent?: string;
  createdAt: Date;
}

const AuditLogSchema = new Schema<IAuditLog>(
  {
    boardId: {
      type: Schema.Types.ObjectId,
      ref: 'Board',
      required: true,
      index: true
    },
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },
    action: {
      type: String,
      enum: Object.values(AuditAction),
      required: true,
      index: true
    },
    details: {
      type: Schema.Types.Mixed,
      default: {}
    },
    ipAddress: {
      type: String
    },
    userAgent: {
      type: String
    }
  },
  {
    timestamps: { createdAt: true, updatedAt: false }
  }
);

// Index for efficient queries
AuditLogSchema.index({ boardId: 1, createdAt: -1 });
AuditLogSchema.index({ userId: 1, createdAt: -1 });

export const AuditLog = mongoose.model<IAuditLog>('AuditLog', AuditLogSchema);

