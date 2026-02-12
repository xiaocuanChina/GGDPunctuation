import 'package:flutter/material.dart';

/// 标签数据模型
class LabelItem {
  final int id;
  Color color;
  Offset? mapPosition; // null表示未放置在地图上
  List<Offset> routePath; // 路线路径点列表
  final String? name; // 自定义名称
  final String? emoji; // 自定义emoji图标
  bool isEliminated; // 是否被淘汰

  LabelItem({
    required this.id,
    required this.color,
    this.mapPosition,
    List<Offset>? routePath,
    this.name,
    this.emoji,
    this.isEliminated = false,
  }) : routePath = routePath ?? [];

  bool get isPlaced => mapPosition != null;
  bool get hasRoute => routePath.isNotEmpty;
  /// 显示文本：优先emoji，其次名称，最后id
  String get displayText => emoji ?? name ?? '$id';
}
