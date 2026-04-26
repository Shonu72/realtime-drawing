import mongoose, { Document, Schema } from 'mongoose';

export interface IChatMessage extends Document {
  boardId: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  userName: String;
  text: string;
  timestamp: number;
  createdAt: Date;
}

const ChatMessageSchema = new Schema<IChatMessage>(
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
      required: true
    },
    userName: {
      type: String,
      required: true
    },
    text: {
      type: String,
      required: true
    },
    timestamp: {
      type: Number,
      required: true,
      index: true
    }
  },
  {
    timestamps: true
  }
);

// Index for efficient message retrieval
ChatMessageSchema.index({ boardId: 1, timestamp: 1 });

export const ChatMessage = mongoose.model<IChatMessage>('ChatMessage', ChatMessageSchema);
