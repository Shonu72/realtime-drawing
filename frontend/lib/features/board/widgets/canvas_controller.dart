import 'package:flutter/material.dart';

class CanvasController extends ChangeNotifier {
  Matrix4 _transform = Matrix4.identity();
  Offset _panOffset = Offset.zero;
  Offset _panStartOffset = Offset.zero;
  Offset _accumulatedPanDelta = Offset.zero;
  double _scale = 1.0;
  double _previousScale = 1.0;

  Matrix4 get transform => _transform;
  double get scale => _scale;

  void handleScaleStart(ScaleStartDetails details) {
    _previousScale = _scale;
    _panStartOffset = _panOffset;
    _accumulatedPanDelta = Offset.zero;
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
    // Handle zooming
    _scale = (_previousScale * details.scale).clamp(0.5, 5.0);

    // Handle panning via focalPointDelta (works for both single-finger drag and multi-finger pan)
    // focalPointDelta is incremental, so accumulate it
    _accumulatedPanDelta += details.focalPointDelta;
    _panOffset = _panStartOffset + _accumulatedPanDelta;

    _updateTransform();
  }

  void handleScaleEnd(ScaleEndDetails details) {
    _previousScale = _scale;
  }

  void _updateTransform() {
    _transform = Matrix4.identity()
      ..translate(_panOffset.dx, _panOffset.dy)
      ..scale(_scale);
    notifyListeners();
  }

  Offset screenToWorld(Offset screenPoint) {
    final inverse = Matrix4.inverted(_transform);
    // Use manual transformation for 2D points
    final x = screenPoint.dx;
    final y = screenPoint.dy;
    const w = 1.0;

    final resultX = inverse.entry(0, 0) * x +
        inverse.entry(0, 1) * y +
        inverse.entry(0, 3) * w;
    final resultY = inverse.entry(1, 0) * x +
        inverse.entry(1, 1) * y +
        inverse.entry(1, 3) * w;

    return Offset(resultX, resultY);
  }

  Offset worldToScreen(Offset worldPoint) {
    // Use manual transformation for 2D points
    final x = worldPoint.dx;
    final y = worldPoint.dy;
    const w = 1.0;

    final resultX = _transform.entry(0, 0) * x +
        _transform.entry(0, 1) * y +
        _transform.entry(0, 3) * w;
    final resultY = _transform.entry(1, 0) * x +
        _transform.entry(1, 1) * y +
        _transform.entry(1, 3) * w;

    return Offset(resultX, resultY);
  }

  void reset() {
    _transform = Matrix4.identity();
    _panOffset = Offset.zero;
    _panStartOffset = Offset.zero;
    _accumulatedPanDelta = Offset.zero;
    _scale = 1.0;
    _previousScale = 1.0;
    notifyListeners();
  }

  void zoomIn() {
    _scale = (_scale * 1.2).clamp(0.5, 5.0);
    _previousScale = _scale;
    _updateTransform();
  }

  void zoomOut() {
    _scale = (_scale / 1.2).clamp(0.5, 5.0);
    _previousScale = _scale;
    _updateTransform();
  }
}
