export const SOCKET_EVENTS = {
  // Board events
  BOARD_JOIN: 'board:join',
  BOARD_LEAVE: 'board:leave',
  BOARD_STATE: 'board:state',
  BOARD_CLEARED: 'board:cleared',
  
  // User events
  USER_JOINED: 'user:joined',
  USER_LEFT: 'user:left',
  
  // Stroke events
  STROKE_DRAW: 'stroke:draw',
  STROKE_CREATED: 'stroke:created',
  STROKE_DELETE: 'stroke:delete',
  STROKE_DELETED: 'stroke:deleted',
  
  // Cursor events
  CURSOR_MOVE: 'cursor:move',
  CURSOR_UPDATE: 'cursor:update',
  
  // Chat events
  CHAT_MESSAGE: 'chat:message',
  CHAT_TYPING: 'chat:typing',
  
  // Error events
  ERROR: 'error'
} as const;

export const STROKE_TOOLS = {
  PENCIL: 'pencil',
  BRUSH: 'brush',
  HIGHLIGHTER: 'highlighter',
  ERASER: 'eraser'
} as const;

export const BOARD_ROLES = {
  ADMIN: 'admin',
  EDITOR: 'editor',
  VIEWER: 'viewer'
} as const;

