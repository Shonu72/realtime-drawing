import mongoose, { Document, Schema } from 'mongoose';
import bcrypt from 'bcryptjs';


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

export interface ILayer {
  id: string;
  name: string;
  isVisible: boolean;
  isLocked: boolean;
  opacity: number;
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
  layers: ILayer[];
  createdAt: Date;
  updatedAt: Date;
  addMember(userId: mongoose.Types.ObjectId, role: BoardRole): void;
  removeMember(userId: mongoose.Types.ObjectId): void;
  getMemberRole(userId: mongoose.Types.ObjectId): BoardRole | null;
  comparePassword(candidatePassword: string): Promise<boolean>;
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
    },
    layers: [
      {
        id: { type: String, required: true },
        name: { type: String, required: true },
        isVisible: { type: Boolean, default: true },
        isLocked: { type: Boolean, default: false },
        opacity: { type: Number, default: 1.0 }
      }
    ]
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

    if (this.layers.length === 0) {
      this.layers.push({
        id: 'default',
        name: 'Layer 1',
        isVisible: true,
        isLocked: false,
        opacity: 1.0
      });
    }
  }
  next();
});

// Hash password before saving
BoardSchema.pre('save', async function (next) {
  if (!this.isModified('password') || !this.password) return next();
  
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
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

BoardSchema.methods.comparePassword = async function (candidatePassword: string): Promise<boolean> {
  if (!this.password) return true;
  return bcrypt.compare(candidatePassword, this.password);
};

export const Board = mongoose.model<IBoard>('Board', BoardSchema);

