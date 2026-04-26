import { ChatMessage, IChatMessage } from '../models/ChatMessage';
import { Board } from '../models/Board';

export class ChatService {
  /**
   * Save a new chat message
   */
  async saveMessage(boardId: string, userId: string, userName: string, text: string): Promise<IChatMessage> {
    const board = await Board.findById(boardId);
    if (!board) {
      throw new Error('Board not found');
    }

    const message = new ChatMessage({
      boardId,
      userId,
      userName,
      text,
      timestamp: Date.now()
    });

    await message.save();
    return message;
  }

  /**
   * Get chat history for a board
   */
  async getChatHistory(boardId: string, limit: number = 50): Promise<IChatMessage[]> {
    return ChatMessage.find({ boardId })
      .sort({ timestamp: -1 })
      .limit(limit)
      .then(messages => messages.reverse());
  }
}

export const chatService = new ChatService();
