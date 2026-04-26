import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExportService {
  static Future<Uint8List?> capturePng(GlobalKey boundaryKey) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing PNG: $e');
      return null;
    }
  }

  static Future<void> exportToPng(GlobalKey boundaryKey, String boardName) async {
    final bytes = await capturePng(boundaryKey);
    if (bytes == null) return;

    await Printing.sharePdf(
      bytes: bytes,
      filename: '${boardName}_export.png',
    );
  }

  static Future<void> exportToPdf(GlobalKey boundaryKey, String boardName) async {
    final bytes = await capturePng(boundaryKey);
    if (bytes == null) return;

    final pdf = pw.Document();
    final image = pw.MemoryImage(bytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(image),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${boardName}_export.pdf',
    );
  }
}
