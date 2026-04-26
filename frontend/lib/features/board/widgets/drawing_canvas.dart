import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/stroke_model.dart';

class DrawingCanvas extends StatefulWidget {
  final List<Stroke> strokes;
  final Function(Stroke) onStrokeComplete;
  final Function(Offset) onCursorMove;
  final Color backgroundColor;
  final double? width;
  final double? height;
  final String activeLayerId;
  final List<String> visibleLayerIds;
  
  const DrawingCanvas({
    super.key,
    required this.strokes,
    required this.onStrokeComplete,
    required this.onCursorMove,
    required this.activeLayerId,
    required this.visibleLayerIds,
    this.backgroundColor = Colors.white,
    this.width,
    this.height,
  });
  
  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final List<Point> _currentPoints = [];
  Stroke? _currentStroke;
  StrokeTool _currentTool = StrokeTool.pencil;
  Color _currentColor = Colors.black;
  double _currentWidth = 3.0;
  
  void setTool(StrokeTool tool) {
    setState(() {
      _currentTool = tool;
    });
  }
  
  void setColor(Color color) {
    setState(() {
      _currentColor = color;
    });
  }
  
  void setWidth(double width) {
    setState(() {
      _currentWidth = width;
    });
  }
  
  void _handlePanStart(DragStartDetails details) {
    final point = Point(
      x: details.localPosition.dx,
      y: details.localPosition.dy,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    
    _currentPoints.clear();
    _currentPoints.add(point);
    
    _currentStroke = Stroke(
      id: '', // Will be set by provider
      boardId: '',
      userId: '',
      tool: _currentTool,
      points: [point],
      color: _colorToHex(_currentColor),
      width: _currentWidth,
      layerId: widget.activeLayerId,
      timestamp: point.timestamp,
      version: 0,
    );
    
    setState(() {});
  }
  
  void _handlePanUpdate(DragUpdateDetails details) {
    final point = Point(
      x: details.localPosition.dx,
      y: details.localPosition.dy,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    
    _currentPoints.add(point);
    
    if (_currentStroke != null) {
      _currentStroke = _currentStroke!.copyWith(
        points: List.from(_currentPoints),
      );
    }
    
    widget.onCursorMove(details.localPosition);
    setState(() {});
  }
  
  void _handlePanEnd(DragEndDetails details) {
    if (_currentStroke != null && _currentPoints.length > 1) {
      widget.onStrokeComplete(_currentStroke!);
    }
    
    _currentStroke = null;
    _currentPoints.clear();
    setState(() {});
  }
  
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: CustomPaint(
        size: Size(
          widget.width ?? MediaQuery.of(context).size.width,
          widget.height ?? MediaQuery.of(context).size.height,
        ),
        painter: _CanvasPainter(
          strokes: widget.strokes,
          visibleLayerIds: widget.visibleLayerIds,
          currentStroke: _currentStroke,
          backgroundColor: widget.backgroundColor,
        ),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<String> visibleLayerIds;
  final Stroke? currentStroke;
  final Color backgroundColor;
  
  _CanvasPainter({
    required this.strokes,
    required this.visibleLayerIds,
    this.currentStroke,
    required this.backgroundColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
    
    // Draw all strokes
    for (final stroke in strokes) {
      if (!stroke.deleted && 
          stroke.points.length > 1 && 
          visibleLayerIds.contains((stroke.layerId?.isEmpty ?? true) ? 'default' : stroke.layerId)) {
        _drawStroke(canvas, stroke);
      }
    }
    
    // Draw current stroke being drawn
    if (currentStroke != null && currentStroke!.points.length > 1) {
      _drawStroke(canvas, currentStroke!);
    }
  }
  
  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;
    
    final paint = Paint()
      ..color = _hexToColor(stroke.color)
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    // Adjust paint based on tool
    switch (stroke.tool) {
      case StrokeTool.highlighter:
        paint.color = paint.color.withOpacity(0.3);
        paint.blendMode = BlendMode.multiply;
        break;
      case StrokeTool.eraser:
        paint.blendMode = BlendMode.clear;
        paint.color = Colors.transparent;
        break;
      case StrokeTool.brush:
        paint.strokeWidth = stroke.width * 1.5;
        break;
      case StrokeTool.pencil:
      default:
        break;
    }
    
    // Draw smooth path using quadratic bezier curves
    final path = Path();
    final points = stroke.points;
    
    if (points.length == 1) {
      canvas.drawCircle(
        Offset(points[0].x, points[0].y),
        stroke.width / 2,
        paint,
      );
      return;
    }
    
    path.moveTo(points[0].x, points[0].y);
    
    for (int i = 1; i < points.length; i++) {
      if (i == 1) {
        path.lineTo(points[i].x, points[i].y);
      } else {
        // Use quadratic bezier for smooth curves
        final prevPoint = points[i - 1];
        final currentPoint = points[i];
        final controlPoint = Offset(
          (prevPoint.x + currentPoint.x) / 2,
          (prevPoint.y + currentPoint.y) / 2,
        );
        path.quadraticBezierTo(
          prevPoint.x,
          prevPoint.y,
          controlPoint.dx,
          controlPoint.dy,
        );
      }
    }
    
    canvas.drawPath(path, paint);
  }
  
  Color _hexToColor(String hex) {
    final hexColor = hex.replaceAll('#', '');
    if (hexColor.length == 6) {
      return Color(int.parse('FF$hexColor', radix: 16));
    }
    return Colors.black;
  }
  
  @override
  bool shouldRepaint(_CanvasPainter oldDelegate) {
    return oldDelegate.strokes.length != strokes.length ||
        oldDelegate.currentStroke != currentStroke;
  }
}

