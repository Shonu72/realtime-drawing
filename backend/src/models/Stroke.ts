import mongoose, { Document, Schema } from 'mongoose';

export enum StrokeTool {
  PENCIL = 'pencil',
  BRUSH = 'brush',
  HIGHLIGHTER = 'highlighter',
  ERASER = 'eraser'
}

export interface IPoint {
  x: number;
  y: number;
  pressure?: number;
  timestamp: number;
}

export interface IStroke extends Document {
  id: string; // UUID for client-side deduplication
  boardId: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  tool: StrokeTool;
  points: IPoint[];
  color: string;
  width: number;
  layerId?: string;
  timestamp: number; // Server-assigned timestamp for ordering
  version: number; // For Operational Transformation
  deleted: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const PointSchema = new Schema<IPoint>({
  x: { type: Number, required: true },
  y: { type: Number, required: true },
  pressure: { type: Number, min: 0, max: 1 },
  timestamp: { type: Number, required: true }
}, { _id: false });

const StrokeSchema = new Schema<IStroke>(
  {
    id: {
      type: String,
      required: true,
      unique: true,
      index: true
    },
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
    tool: {
      type: String,
      enum: Object.values(StrokeTool),
      required: true
    },
    points: {
      type: [PointSchema],
      required: true
    },
    color: {
      type: String,
      required: true,
      default: '#000000'
    },
    width: {
      type: Number,
      required: true,
      min: 1,
      max: 100,
      default: 3
    },
    layerId: {
      type: String,
      default: 'default'
    },
    timestamp: {
      type: Number,
      required: true,
      index: true
    },
    version: {
      type: Number,
      required: true,
      default: 0
    },
    deleted: {
      type: Boolean,
      default: false,
      index: true
    }
  },
  {
    timestamps: true
  }
);

// Compound index for efficient queries
StrokeSchema.index({ boardId: 1, timestamp: 1 });
StrokeSchema.index({ boardId: 1, deleted: 1, timestamp: 1 });

export const Stroke = mongoose.model<IStroke>('Stroke', StrokeSchema);

