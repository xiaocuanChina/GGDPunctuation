import 'package:flutter/material.dart';

/// 标签工具类
class LabelUtils {
  /// 默认颜色列表（13种预设颜色）
  static const List<Color> defaultColors = [
    Color.fromRGBO(254, 253, 253, 1),
    Color.fromRGBO(98, 142, 200, 1),
    Color.fromRGBO(46, 168, 129, 1),
    Color.fromRGBO(240, 174, 242, 1),
    Color.fromRGBO(244, 65, 95, 1),
    Color.fromRGBO(248, 207, 115, 1),
    Color.fromRGBO(255, 124, 52, 1),
    Color.fromRGBO(167, 142, 138, 1),
    Color.fromRGBO(93, 85, 85, 1),
    Color.fromRGBO(130, 96, 205, 1),
    Color.fromRGBO(160, 247, 134, 1),
    Color.fromRGBO(174, 226, 253, 1),
    Color.fromRGBO(228, 91, 198, 1),
  ];

  /// 根据编号获取颜色
  static Color getColorForLabel(int id, Map<int, Color> colorConfig) {
    return colorConfig[id] ?? defaultColors[(id - 1) % defaultColors.length];
  }

  /// 根据背景色计算合适的文字颜色（黑色或白色）
  static Color getTextColorForBackground(Color backgroundColor) {
    final r = (backgroundColor.r * 255.0).round().clamp(0, 255);
    final g = (backgroundColor.g * 255.0).round().clamp(0, 255);
    final b = (backgroundColor.b * 255.0).round().clamp(0, 255);
    final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// 工具栏标签大小（较大，方便选择）
  static double getToolbarLabelSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final referenceSize = screenSize.shortestSide;
    return (40.0 * referenceSize / 800.0).clamp(30.0, 52.0);
  }

  /// 地图上标签大小（小圆点）
  static double getMapDotSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final referenceSize = screenSize.shortestSide;
    return (20.0 * referenceSize / 800.0).clamp(16.0, 26.0);
  }
}
