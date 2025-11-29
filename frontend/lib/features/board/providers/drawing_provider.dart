import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/stroke_model.dart';

class DrawingProvider with ChangeNotifier {
  final List<Stroke> _strokes = [];
  final List<Stroke> _undoStack = [];
  final List<Stroke> _redoStack = [];
  
  StrokeTool _currentTool = StrokeTool.pencil;
  Color _currentColor = Colors.black;
  double _currentWidth = 3.0;
  String? _currentBoardId;
  String? _currentUserId;
  
  final _uuid = const Uuid();
  
  List<Stroke> get strokes => List.unmodifiable(_strokes);
  StrokeTool get currentTool => _currentTool;
  Color get currentColor => _currentColor;
  double get currentWidth => _currentWidth;
  
  void initialize(String boardId, String userId) {
    _currentBoardId = boardId;
    _currentUserId = userId;
  }
  
  void setTool(StrokeTool tool) {
    _currentTool = tool;
    notifyListeners();
  }
  
  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }
  
  void setWidth(double width) {
    _currentWidth = width;
    notifyListeners();
  }
  
  void addStroke(Stroke stroke) {
    // Add ID if not present
    final strokeWithId = stroke.id.isEmpty
        ? stroke.copyWith(id: _uuid.v4())
        : stroke;
    
    _strokes.add(strokeWithId);
    _redoStack.clear(); // Clear redo stack when new stroke is added
    notifyListeners();
  }
  
  void addStrokes(List<Stroke> strokes) {
    for (final stroke in strokes) {
      if (!_strokes.any((s) => s.id == stroke.id)) {
        _strokes.add(stroke);
      }
    }
    // Sort by timestamp
    _strokes.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    notifyListeners();
  }
  
  void removeStroke(String strokeId) {
    final stroke = _strokes.firstWhere(
      (s) => s.id == strokeId,
      orElse: () => _strokes.first,
    );
    _strokes.removeWhere((s) => s.id == strokeId);
    _undoStack.add(stroke);
    _redoStack.clear();
    notifyListeners();
  }
  
  void updateStroke(Stroke updatedStroke) {
    final index = _strokes.indexWhere((s) => s.id == updatedStroke.id);
    if (index != -1) {
      _strokes[index] = updatedStroke;
      notifyListeners();
    }
  }
  
  bool canUndo() {
    if (_currentUserId == null) return false;
    return _strokes.any((s) => s.userId == _currentUserId && !s.deleted);
  }
  
  bool canRedo() {
    return _redoStack.isNotEmpty;
  }
  
  void undo() {
    if (!canUndo()) return;
    
    // Find last stroke by current user
    Stroke? lastStroke;
    for (int i = _strokes.length - 1; i >= 0; i--) {
      if (_strokes[i].userId == _currentUserId && !_strokes[i].deleted) {
        lastStroke = _strokes[i];
        break;
      }
    }
    
    if (lastStroke != null) {
      _strokes.remove(lastStroke);
      _undoStack.add(lastStroke);
      _redoStack.clear();
      notifyListeners();
    }
  }
  
  void redo() {
    if (_redoStack.isEmpty) return;
    
    final stroke = _redoStack.removeLast();
    _strokes.add(stroke);
    notifyListeners();
  }
  
  void clearBoard() {
    _strokes.clear();
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }
  
  void clearStrokesByUser(String userId) {
    _strokes.removeWhere((s) => s.userId == userId);
    notifyListeners();
  }
  
  Stroke createStrokeFromPoints(List<Point> points) {
    return Stroke(
      id: _uuid.v4(),
      boardId: _currentBoardId ?? '',
      userId: _currentUserId ?? '',
      tool: _currentTool,
      points: points,
      color: _colorToHex(_currentColor),
      width: _currentWidth,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      version: 0,
    );
  }
  
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}

