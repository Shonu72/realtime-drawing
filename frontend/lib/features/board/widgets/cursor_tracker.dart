import 'package:flutter/material.dart';

class RemoteCursor {
  final String userId;
  final String userName;
  final String? userAvatar;
  final String color;
  final Offset position;
  
  RemoteCursor({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.color,
    required this.position,
  });
}

class CursorTracker extends StatelessWidget {
  final List<RemoteCursor> cursors;
  final Size canvasSize;
  
  const CursorTracker({
    super.key,
    required this.cursors,
    required this.canvasSize,
  });
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: cursors.map((cursor) {
        return Positioned(
          left: cursor.position.dx,
          top: cursor.position.dy,
          child: _CursorWidget(
            cursor: cursor,
          ),
        );
      }).toList(),
    );
  }
}

class _CursorWidget extends StatelessWidget {
  final RemoteCursor cursor;
  
  const _CursorWidget({
    required this.cursor,
  });
  
  Color _hexToColor(String hex) {
    final hexColor = hex.replaceAll('#', '');
    if (hexColor.length == 6) {
      return Color(int.parse('FF$hexColor', radix: 16));
    }
    return Colors.black;
  }
  
  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(cursor.color);
    
    return Transform.translate(
      offset: const Offset(0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cursor pointer
          CustomPaint(
            size: const Size(20, 20),
            painter: _CursorPainter(color: color),
          ),
          const SizedBox(height: 4),
          // User name label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              cursor.userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CursorPainter extends CustomPainter {
  final Color color;
  
  _CursorPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final fillPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    // Draw cursor arrow
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.7, size.height * 0.3);
    path.lineTo(size.width * 0.3, size.height * 0.3);
    path.lineTo(size.width * 0.3, size.height * 0.7);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(_CursorPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

