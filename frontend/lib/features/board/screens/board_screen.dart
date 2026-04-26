import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/drawing_provider.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/tool_palette.dart';
import '../widgets/cursor_tracker.dart';
import '../widgets/canvas_controller.dart';
import '../models/stroke_model.dart';
import '../../chat/widgets/chat_panel.dart';
import '../../chat/models/chat_message_model.dart';
import '../../../services/socket_service.dart';
import '../../../services/api_service.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import '../../../services/export_service.dart';
import '../widgets/layers_panel.dart';


class BoardScreen extends StatefulWidget {
  final String boardId;
  
  const BoardScreen({
    super.key,
    required this.boardId,
  });
  
  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();
  final CanvasController _canvasController = CanvasController();
  final DrawingProvider _drawingProvider = DrawingProvider();
  final GlobalKey _canvasKey = GlobalKey();
  
  List<Stroke> _strokes = [];
  List<ChatMessage> _chatMessages = [];
  List<RemoteCursor> _remoteCursors = [];
  List<Map<String, dynamic>> _activeUsers = [];
  List<String> _typingUsers = [];
  
  bool _isChatVisible = false;
  bool _isLoading = true;
  bool _showLayersPanel = false;
  bool _isReplayMode = false;
  double _replayValue = 1.0;
  String? _boardName;
  String? _error;
  
  Timer? _cursorUpdateTimer;
  Timer? _strokeThrottleTimer;
  List<Point> _pendingPoints = [];
  
  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }
  
  @override
  void dispose() {
    _cursorUpdateTimer?.cancel();
    _strokeThrottleTimer?.cancel();
    _socketService.disconnect();
    super.dispose();
  }
  
  Future<void> _initializeBoard() async {
    try {
      // Get board info
      final boardResponse = await _apiService.getBoard(widget.boardId);
      final boardData = boardResponse.data['board'];
      setState(() {
        _boardName = boardData['name'];
      });
      
      // Get initial strokes
      final strokesResponse = await _apiService.getBoardStrokes(widget.boardId);
      final strokesData = strokesResponse.data['strokes'] as List<dynamic>;
      final strokes = strokesData
          .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
          .toList();
      
      setState(() {
        _strokes = strokes;
        _isLoading = false;
      });

      // Get chat history
      final chatResponse = await _apiService.getBoardChat(widget.boardId);
      final chatData = chatResponse.data['messages'] as List<dynamic>;
      final chatMessages = chatData
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
      
      setState(() {
        _chatMessages = chatMessages;
      });
      
      _drawingProvider.addStrokes(strokes);
      
      // Initialize socket connection
      await _socketService.connect();
      _setupSocketListeners();
      _socketService.joinBoard(widget.boardId);
      
      // Initialize drawing provider
      final authProvider = context.read<AuthProvider>();
      _drawingProvider.initialize(
        widget.boardId,
        authProvider.user?.id ?? '',
      );
      
      // Start cursor update timer
      _cursorUpdateTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _updateCursorPosition(),
      );
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        final data = e.response?.data;
        if (data is Map && data['error'] == 'Password required') {
          _showPasswordDialog();
          return;
        }
      }
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showPasswordDialog() async {
    final TextEditingController passwordController = TextEditingController();
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Password Protected Board'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This board is private and requires a password to join.'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => Navigator.pop(context, true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Join'),
          ),
        ],
      ),
    );

    if (result == true) {
      final password = passwordController.text;
      if (password.isNotEmpty) {
        try {
          setState(() => _isLoading = true);
          await _apiService.verifyBoardPassword(widget.boardId, password);
          _initializeBoard(); // Retry initialization after successful verification
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid password'), backgroundColor: Colors.red),
          );
          _showPasswordDialog(); // Show again
        }
      } else {
        _showPasswordDialog();
      }
    } else {
      Navigator.pop(context);
    }
  }
  
  void _setupSocketListeners() {
    // Board state
    _socketService.onBoardState((data) {
      final strokes = (data['strokes'] as List<dynamic>?)
          ?.map((s) => Stroke.fromJson(s as Map<String, dynamic>))
          .toList() ?? [];
      final users = (data['users'] as List<dynamic>?) ?? [];
      
      setState(() {
        _strokes = strokes;
        _activeUsers = users.map((u) => u as Map<String, dynamic>).toList();
      });
      
      _drawingProvider.addStrokes(strokes);
    });
    
    // Stroke created
    _socketService.onStrokeCreated((data) {
      final strokeData = data['stroke'] as Map<String, dynamic>;
      final stroke = Stroke.fromJson(strokeData);
      
      setState(() {
        _strokes.add(stroke);
      });
      
      _drawingProvider.addStroke(stroke);
    });
    
    // Stroke deleted
    _socketService.onStrokeDeleted((data) {
      final strokeId = data['strokeId'] as String;
      
      setState(() {
        _strokes.removeWhere((s) => s.id == strokeId);
      });
      
      _drawingProvider.removeStroke(strokeId);
    });
    
    // User joined
    _socketService.onUserJoined((data) {
      setState(() {
        _activeUsers.add(data);
      });
    });
    
    // User left
    _socketService.onUserLeft((data) {
      final userId = data['userId'] as String;
      setState(() {
        _activeUsers.removeWhere((u) => u['userId'] == userId);
        _remoteCursors.removeWhere((c) => c.userId == userId);
      });
    });
    
    // Cursor update
    _socketService.onCursorUpdate((data) {
      final userId = data['userId'] as String;
      final userName = data['name'] as String? ?? 'User';
      final x = (data['x'] as num).toDouble();
      final y = (data['y'] as num).toDouble();
      
      setState(() {
        final existingIndex = _remoteCursors.indexWhere(
          (c) => c.userId == userId,
        );
        
        final user = _activeUsers.firstWhere(
          (u) => u['userId'] == userId,
          orElse: () => {'color': '#6366F1'},
        );
        
        final cursor = RemoteCursor(
          userId: userId,
          userName: userName,
          color: user['color'] ?? '#6366F1',
          position: Offset(x, y),
        );
        
        if (existingIndex != -1) {
          _remoteCursors[existingIndex] = cursor;
        } else {
          _remoteCursors.add(cursor);
        }
      });
    });
    
    // Chat message
    _socketService.onChatMessage((data) {
      final message = ChatMessage.fromJson(data);
      setState(() {
        _chatMessages.add(message);
      });
    });
    
    // Chat typing
    _socketService.onChatTyping((data) {
      final userName = data['name'] as String? ?? 'User';
      final isTyping = data['isTyping'] as bool? ?? false;
      
      setState(() {
        if (isTyping && !_typingUsers.contains(userName)) {
          _typingUsers.add(userName);
        } else if (!isTyping) {
          _typingUsers.remove(userName);
        }
      });
    });
    
    // Board cleared
    _socketService.onBoardCleared((data) {
      setState(() {
        _strokes.clear();
      });
      _drawingProvider.clearBoard();
    });
    
    // Error
    _socketService.onError((data) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'An error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
  
  void _updateCursorPosition() {
    // This will be called periodically to update cursor
    // Actual cursor updates happen in gesture handlers
  }
  
  void _handleStrokeComplete(Stroke stroke) {
    // Throttle stroke updates
    _pendingPoints.addAll(stroke.points);
    
    _strokeThrottleTimer?.cancel();
    _strokeThrottleTimer = Timer(const Duration(milliseconds: 16), () {
      if (_pendingPoints.isNotEmpty) {
        final strokeToSend = _drawingProvider.createStrokeFromPoints(
          List.from(_pendingPoints),
        );
        _pendingPoints.clear();
        
        _socketService.drawStroke(strokeToSend.toJson());
        _drawingProvider.addStroke(strokeToSend);
      }
    });
  }
  
  void _handleCursorMove(Offset position) {
    _socketService.updateCursor(widget.boardId, position.dx, position.dy);
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_boardName ?? 'Board'),
        actions: [
          IconButton(
            icon: Icon(_isChatVisible ? Icons.chat : Icons.chat_bubble_outline),
            onPressed: () {
              setState(() {
                _isChatVisible = !_isChatVisible;
                if (_isChatVisible) _showLayersPanel = false;
              });
            },
            tooltip: 'Toggle Chat',
          ),
          IconButton(
            icon: Icon(_showLayersPanel ? Icons.layers : Icons.layers_outlined),
            onPressed: () {
              setState(() {
                _showLayersPanel = !_showLayersPanel;
                if (_showLayersPanel) _isChatVisible = false;
              });
            },
            tooltip: 'Toggle Layers',
          ),
          IconButton(
            icon: Icon(_isReplayMode ? Icons.play_circle : Icons.play_circle_outline),
            onPressed: () {
              setState(() {
                _isReplayMode = !_isReplayMode;
                if (_isReplayMode) {
                  _showLayersPanel = false;
                  _isChatVisible = false;
                  _replayValue = 1.0;
                }
              });
            },
            tooltip: 'Replay Mode',
          ),
          PopupMenuButton<String>(
            itemBuilder: (context) => <PopupMenuEntry<String>>[
                const PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('Reset View'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'export_png',
                  child: Row(
                    children: [
                      Icon(Icons.image),
                      SizedBox(width: 8),
                      Text('Export as PNG'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export_pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf),
                      SizedBox(width: 8),
                      Text('Export as PDF'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'reset') {
                  _canvasController.reset();
                } else if (value == 'export_png') {
                  ExportService.exportToPng(_canvasKey, _boardName ?? 'board');
                } else if (value == 'export_pdf') {
                  ExportService.exportToPdf(_canvasKey, _boardName ?? 'board');
                }
              },
            ),
          ],
        ),
      body: Row(
        children: [
          // Main canvas area
          Expanded(
            child: RepaintBoundary(
              key: _canvasKey,
              child: Stack(
                children: [
                  // Drawing canvas
                GestureDetector(
                  onScaleStart: _canvasController.handleScaleStart,
                  onScaleUpdate: _canvasController.handleScaleUpdate,
                  onScaleEnd: _canvasController.handleScaleEnd,
                  child: Transform(
                    transform: _canvasController.transform,
                    child: ChangeNotifierProvider.value(
                      value: _drawingProvider,
                      child: Consumer<DrawingProvider>(
                        builder: (context, provider, _) {
                          List<Stroke> filteredStrokes = provider.strokes;
                          
                          if (_isReplayMode && provider.strokes.isNotEmpty) {
                            final startTime = provider.strokes.first.timestamp;
                            final endTime = provider.strokes.last.timestamp;
                            final threshold = startTime + (endTime - startTime) * _replayValue;
                            filteredStrokes = provider.strokes
                                .where((s) => s.timestamp <= threshold)
                                .toList();
                          }

                          return DrawingCanvas(
                            strokes: filteredStrokes,
                            onStrokeComplete: _handleStrokeComplete,
                            onCursorMove: _handleCursorMove,
                            backgroundColor: Colors.white,
                            activeLayerId: provider.activeLayerId,
                            visibleLayerIds: provider.layers
                                .where((l) => l['isVisible'] != false)
                                .map((l) => l['id'] as String)
                                .toList(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                
                // Replay slider
                if (_isReplayMode)
                  Positioned(
                    bottom: 32,
                    left: 64,
                    right: 64,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.history),
                            Expanded(
                              child: Slider(
                                value: _replayValue,
                                onChanged: (value) {
                                  setState(() {
                                    _replayValue = value;
                                  });
                                },
                              ),
                            ),
                            Text('${(_replayValue * 100).toInt()}%'),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => _isReplayMode = false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // Remote cursors
                CursorTracker(
                  cursors: _remoteCursors,
                  canvasSize: MediaQuery.of(context).size,
                ),
                
                // Tool palette (floating)
                Positioned(
                  top: 16,
                  left: 16,
                  child: ChangeNotifierProvider.value(
                    value: _drawingProvider,
                    child: const ToolPalette(isCompact: true),
                  ),
                ),
              ],
            ),
          ),
        ),
          // Layers panel
          if (_showLayersPanel)
            ChangeNotifierProvider.value(
              value: _drawingProvider,
              child: const LayersPanel(),
            ),
          
          // Chat panel
          if (_isChatVisible)
            ChatPanel(
              messages: _chatMessages,
              onSendMessage: (message) {
                _socketService.sendChatMessage(widget.boardId, message);
              },
              onTyping: (isTyping) {
                _socketService.sendTypingIndicator(widget.boardId, isTyping);
              },
              typingUsers: _typingUsers,
              isVisible: _isChatVisible,
              currentUserId: context.read<AuthProvider>().user?.id,
            ),
        ],
      ),
    );
  }
}
