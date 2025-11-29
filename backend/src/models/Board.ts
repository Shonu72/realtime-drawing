import mongoose, { Document, Schema } from 'mongoose';

export enum BoardRole {
  ADMIN = 'admin',
  EDITOR = 'editor',
  VIEWER = 'viewer'
}

export interface IBoardMember {
  userId: mongoose.Types.ObjectId;
  role: BoardRole;
  joinedAt: Date;
}

export interface IBoard extends Document {
  name: string;
  description?: string;
  ownerId: mongoose.Types.ObjectId;
  members: IBoardMember[];
  isPublic: boolean;
  password?: string;
  settings: {
    allowGuests: boolean;
    maxUsers: number;
    enableChat: boolean;
    enableReplay: boolean;
  };
  createdAt: Date;
  updatedAt: Date;
  addMember(userId: mongoose.Types.ObjectId, role: BoardRole): void;
  removeMember(userId: mongoose.Types.ObjectId): void;
  getMemberRole(userId: mongoose.Types.ObjectId): BoardRole | null;
}

const BoardMemberSchema = new Schema<IBoardMember>({
  userId: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  role: {
    type: String,
    enum: Object.values(BoardRole),
    default: BoardRole.EDITOR
  },
  joinedAt: {
    type: Date,
    default: Date.now
  }
});

const BoardSchema = new Schema<IBoard>(
  {
    name: {
      type: String,
      required: true,
      trim: true
    },
    description: {
      type: String,
      trim: true
    },
    ownerId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },
    members: [BoardMemberSchema],
    isPublic: {
      type: Boolean,
      default: false
    },
    password: {
      type: String,
      select: false
    },
    settings: {
      allowGuests: {
        type: Boolean,
        default: false
      },
      maxUsers: {
        type: Number,
        default: 50
      },
      enableChat: {
        type: Boolean,
        default: true
      },
      enableReplay: {
        type: Boolean,
        default: true
      }
    }
  },
  {
    timestamps: true
  }
);

// Add owner as admin member on creation
BoardSchema.pre('save', function (next) {
  if (this.isNew) {
    this.members.push({
      userId: this.ownerId,
      role: BoardRole.ADMIN,
      joinedAt: new Date()
    });
  }
  next();
});

// Methods
BoardSchema.methods.addMember = function (userId: mongoose.Types.ObjectId, role: BoardRole) {
  const existingMember = this.members.find(
    (m: IBoardMember) => m.userId.toString() === userId.toString()
  );
  
  if (!existingMember) {
    this.members.push({
      userId,
      role,
      joinedAt: new Date()
    });
  }
};

BoardSchema.methods.removeMember = function (userId: mongoose.Types.ObjectId) {
  this.members = this.members.filter(
    (m: IBoardMember) => m.userId.toString() !== userId.toString()
  );
};

BoardSchema.methods.getMemberRole = function (userId: mongoose.Types.ObjectId): BoardRole | null {
  const member = this.members.find(
    (m: IBoardMember) => m.userId.toString() === userId.toString()
  );
  return member ? member.role : null;
};

export const Board = mongoose.model<IBoard>('Board', BoardSchema);

