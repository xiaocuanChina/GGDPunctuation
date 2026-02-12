import 'dart:math' show atan2, cos, sin, pi;
import 'package:flutter/material.dart';
import '../models/label_item.dart';

/// 路线绘制器（基于图片渲染区域的相对坐标，在绘制时转换为绝对坐标）
class RoutesPainter extends CustomPainter {
  final List<LabelItem> labels;
  final int? editingLabelId;
  final List<Offset> tempRoutePath;
  final double mapDotSize;
  final Rect imageBounds;

  RoutesPainter({
    required this.labels,
    this.editingLabelId,
    required this.tempRoutePath,
    required this.mapDotSize,
    required this.imageBounds,
  });

  /// 将基于图片的相对坐标转换为容器内的绝对坐标
  Offset _toAbsolute(Offset relative) {
    return Offset(
      relative.dx * imageBounds.width + imageBounds.left,
      relative.dy * imageBounds.height + imageBounds.top,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制所有已完成的路线
    for (var label in labels.where((l) => l.isPlaced && l.hasRoute)) {
      final isEditing = editingLabelId == label.id;
      
      // 路线画笔
      final linePaint = Paint()
        ..color = isEditing ? Colors.blue.withValues(alpha: 0.6) : label.color.withValues(alpha: 0.7)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // 路线点画笔
      final pointPaint = Paint()
        ..color = isEditing ? Colors.blue : label.color
        ..style = PaintingStyle.fill;

      final pointBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // 将基于图片的相对坐标转换为绝对坐标
      final labelAbsPos = _toAbsolute(label.mapPosition!);
      final absoluteRoute = label.routePath.map((p) => _toAbsolute(p)).toList();

      // 绘制路线
      if (absoluteRoute.length >= 2) {
        final path = Path();
        path.moveTo(labelAbsPos.dx, labelAbsPos.dy);
        
        for (var point in absoluteRoute) {
          path.lineTo(point.dx, point.dy);
        }
        
        canvas.drawPath(path, linePaint);
      } else if (absoluteRoute.length == 1) {
        // 只有一个点时，绘制从标签到该点的线
        canvas.drawLine(labelAbsPos, absoluteRoute[0], linePaint);
      }

      // 绘制路线点
      for (var point in absoluteRoute) {
        canvas.drawCircle(point, 5, pointBorderPaint);
        canvas.drawCircle(point, 4, pointPaint);
      }

      // 绘制箭头（在最后一个路线点）
      if (absoluteRoute.isNotEmpty) {
        final lastPoint = absoluteRoute.last;
        Offset startPoint;
        
        if (absoluteRoute.length >= 2) {
          startPoint = absoluteRoute[absoluteRoute.length - 2];
        } else {
          startPoint = labelAbsPos;
        }
        
        _drawArrow(canvas, startPoint, lastPoint, linePaint);
      }
    }
  }

  /// 绘制箭头
  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final angle = atan2(dy, dx);
    
    const arrowSize = 10.0;
    const arrowAngle = 25 * pi / 180;
    
    final arrowPath = Path();
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(
      end.dx - arrowSize * cos(angle - arrowAngle),
      end.dy - arrowSize * sin(angle - arrowAngle),
    );
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(
      end.dx - arrowSize * cos(angle + arrowAngle),
      end.dy - arrowSize * sin(angle + arrowAngle),
    );
    
    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(RoutesPainter oldDelegate) {
    return true;
  }
}
