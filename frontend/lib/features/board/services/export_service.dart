import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/stroke_model.dart';

class ExportService {
  // Export to PNG
  Future<File?> exportToPNG(
    List<Stroke> strokes,
    Size canvasSize,
    Color backgroundColor,
  ) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw background
      final backgroundPaint = Paint()..color = backgroundColor;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
        backgroundPaint,
      );

      // Draw strokes
      for (final stroke in strokes) {
        if (!stroke.deleted && stroke.points.length > 1) {
          _drawStroke(canvas, stroke);
        }
      }

      // Convert to image
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        canvasSize.width.toInt(),
        canvasSize.height.toInt(),
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes == null) return null;

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/board_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      return file;
    } catch (e) {
      print('Error exporting PNG: $e');
      return null;
    }
  }

  // Export to SVG
  Future<File?> exportToSVG(
    List<Stroke> strokes,
    Size canvasSize,
    Color backgroundColor,
  ) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      buffer.writeln(
        '<svg width="${canvasSize.width}" height="${canvasSize.height}" '
        'xmlns="http://www.w3.org/2000/svg">',
      );

      // Background
      buffer.writeln(
        '<rect width="${canvasSize.width}" height="${canvasSize.height}" '
        'fill="#${backgroundColor.value.toRadixString(16).substring(2)}"/>',
      );

      // Strokes
      for (final stroke in strokes) {
        if (!stroke.deleted && stroke.points.length > 1) {
          buffer.writeln(_strokeToSVG(stroke));
        }
      }

      buffer.writeln('</svg>');

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/board_${DateTime.now().millisecondsSinceEpoch}.svg');
      await file.writeAsString(buffer.toString());

      return file;
    } catch (e) {
      print('Error exporting SVG: $e');
      return null;
    }
  }

  // Export to PDF
  Future<void> exportToPDF(
    List<Stroke> strokes,
    Size canvasSize,
    Color backgroundColor,
    String boardName,
  ) async {
    try {
      final pdf = pw.Document();

      // Convert Flutter Color to PDF Color
      final bgColor = PdfColor(
        backgroundColor.red / 255,
        backgroundColor.green / 255,
        backgroundColor.blue / 255,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            canvasSize.width,
            canvasSize.height,
          ),
          build: (pw.Context context) {
            return pw.CustomPaint(
              painter: (PdfGraphics canvas, PdfPoint size) {
                // Draw background
                canvas.setFillColor(bgColor);
                canvas.drawRect(
                  0,
                  0,
                  size.x,
                  size.y,
                );

                // Draw strokes
                for (final stroke in strokes) {
                  if (!stroke.deleted && stroke.points.length > 1) {
                    _drawStrokeToPDF(canvas, stroke);
                  }
                }
              },
              size: PdfPoint(canvasSize.width, canvasSize.height),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      print('Error exporting PDF: $e');
    }
  }

  void _drawStrokeToPDF(PdfGraphics canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final color = _hexToPdfColor(stroke.color);
    final width = stroke.width;
    final points = stroke.points;

    canvas.setStrokeColor(color);
    canvas.setLineWidth(width);
    canvas.setLineCap(PdfLineCap.round);
    canvas.setLineJoin(PdfLineJoin.round);

    if (points.length == 1) {
      canvas.setFillColor(color);
      // Draw circle using arc
      canvas.drawEllipse(
        points[0].x - width / 2,
        points[0].y - width / 2,
        width,
        width,
      );
      return;
    }

    // Draw path using lines (simplified - PDF doesn't support quadratic bezier directly)
    canvas.moveTo(points[0].x, points[0].y);

    for (int i = 1; i < points.length; i++) {
      canvas.lineTo(points[i].x, points[i].y);
    }

    canvas.strokePath();
  }

  PdfColor _hexToPdfColor(String hex) {
    final hexColor = hex.replaceAll('#', '');
    if (hexColor.length == 6) {
      final r = int.parse(hexColor.substring(0, 2), radix: 16);
      final g = int.parse(hexColor.substring(2, 4), radix: 16);
      final b = int.parse(hexColor.substring(4, 6), radix: 16);
      return PdfColor(r / 255, g / 255, b / 255);
    }
    return const PdfColor(0, 0, 0); // Black default
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = _hexToColor(stroke.color)
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (stroke.tool) {
      case StrokeTool.highlighter:
        paint.color = paint.color.withOpacity(0.3);
        paint.blendMode = BlendMode.multiply;
        break;
      case StrokeTool.eraser:
        paint.blendMode = BlendMode.clear;
        break;
      case StrokeTool.brush:
        paint.strokeWidth = stroke.width * 1.5;
        break;
      default:
        break;
    }

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

  String _strokeToSVG(Stroke stroke) {
    if (stroke.points.isEmpty) return '';

    final points = stroke.points;
    final color = stroke.color;
    final width = stroke.width;

    if (points.length == 1) {
      return '<circle cx="${points[0].x}" cy="${points[0].y}" '
          'r="${width / 2}" fill="$color"/>';
    }

    final pathData = StringBuffer();
    pathData.write('M ${points[0].x} ${points[0].y} ');

    for (int i = 1; i < points.length; i++) {
      if (i == 1) {
        pathData.write('L ${points[i].x} ${points[i].y} ');
      } else {
        final prevPoint = points[i - 1];
        final currentPoint = points[i];
        final controlX = (prevPoint.x + currentPoint.x) / 2;
        final controlY = (prevPoint.y + currentPoint.y) / 2;
        pathData.write('Q ${prevPoint.x} ${prevPoint.y} $controlX $controlY ');
      }
    }

    return '<path d="$pathData" stroke="$color" stroke-width="$width" '
        'fill="none" stroke-linecap="round" stroke-linejoin="round"/>';
  }

  Color _hexToColor(String hex) {
    final hexColor = hex.replaceAll('#', '');
    if (hexColor.length == 6) {
      return Color(int.parse('FF$hexColor', radix: 16));
    }
    return Colors.black;
  }
}
