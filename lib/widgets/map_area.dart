import 'dart:io';
import 'package:flutter/material.dart';
import '../models/label_item.dart';
import 'route_painter.dart';

/// 地图区域组件
class MapArea extends StatelessWidget {
  final GlobalKey mapKey;
  final String? imagePath;
  final bool isAssetImage;
  final List<LabelItem> labels;
  final int? editingRouteForLabel;
  final List<Offset> tempRoutePath;
  final int? selectedLabelId;
  final double toolbarLabelSize;
  final double mapDotSize;
  final Size? imageNaturalSize;
  final Function(int, Offset) onLabelPlaced;
  final Function(Offset) onRoutePointAdded;
  final Function(int) onLabelSelected;
  final Function(int) onLabelDeselected;
  final Function(int) onRouteEditToggle;

  const MapArea({
    super.key,
    required this.mapKey,
    required this.imagePath,
    required this.isAssetImage,
    required this.labels,
    required this.editingRouteForLabel,
    required this.tempRoutePath,
    required this.selectedLabelId,
    required this.toolbarLabelSize,
    required this.mapDotSize,
    required this.imageNaturalSize,
    required this.onLabelPlaced,
    required this.onRoutePointAdded,
    required this.onLabelSelected,
    required this.onLabelDeselected,
    required this.onRouteEditToggle,
  });

  /// 根据容器大小和图片原始尺寸，计算图片在 BoxFit.contain 下的实际渲染区域
  Rect _getImageBounds(Size containerSize) {
    if (imageNaturalSize == null) {
      return Rect.fromLTWH(0, 0, containerSize.width, containerSize.height);
    }
    final imageAspect = imageNaturalSize!.width / imageNaturalSize!.height;
    final containerAspect = containerSize.width / containerSize.height;

    double renderWidth, renderHeight, offsetX, offsetY;
    if (imageAspect > containerAspect) {
      renderWidth = containerSize.width;
      renderHeight = containerSize.width / imageAspect;
      offsetX = 0;
      offsetY = (containerSize.height - renderHeight) / 2;
    } else {
      renderHeight = containerSize.height;
      renderWidth = containerSize.height * imageAspect;
      offsetX = (containerSize.width - renderWidth) / 2;
      offsetY = 0;
    }
    return Rect.fromLTWH(offsetX, offsetY, renderWidth, renderHeight);
  }

  /// 根据背景色计算合适的文字颜色
  Color _getTextColorForBackground(Color backgroundColor) {
    final r = (backgroundColor.r * 255.0).round().clamp(0, 255);
    final g = (backgroundColor.g * 255.0).round().clamp(0, 255);
    final b = (backgroundColor.b * 255.0).round().clamp(0, 255);
    final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// 构建工具栏标签组件
  Widget _buildLabel(LabelItem label, {bool isDragging = false}) {
    final textColor = _getTextColorForBackground(label.color);
    final isEditingRoute = editingRouteForLabel == label.id;
    final isSelected = selectedLabelId == label.id;
    final halfSize = toolbarLabelSize / 2;
    final scale = toolbarLabelSize / 28.0;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: toolbarLabelSize,
          height: toolbarLabelSize,
          decoration: BoxDecoration(
            color: label.color.withValues(alpha: isDragging ? 0.8 : 1.0),
            borderRadius: BorderRadius.circular(halfSize),
            border: Border.all(
              color: isSelected ? Colors.blue : (isEditingRoute ? Colors.blue : Colors.white), 
              width: isSelected ? 3.0 : (isEditingRoute ? 2.5 : 2),
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected 
                    ? Colors.blue.withValues(alpha: 0.5)
                    : label.color.withValues(alpha: 0.4),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: label.emoji != null
                ? Text(
                    label.emoji!,
                    style: TextStyle(
                      fontSize: 15 * scale,
                      decoration: TextDecoration.none,
                    ),
                  )
                : Text(
                    label.name ?? '${label.id}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11 * scale,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
          ),
        ),
        if (label.hasRoute && !isEditingRoute)
          Positioned(
            right: -2 * scale,
            bottom: -2 * scale,
            child: Container(
              width: 12 * scale,
              height: 12 * scale,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Icon(
                Icons.route,
                size: 8 * scale,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  /// 构建地图上的小圆点标签
  Widget _buildMapDot(LabelItem label, {bool isDragging = false}) {
    final textColor = _getTextColorForBackground(label.color);
    final isEditingRoute = editingRouteForLabel == label.id;
    final isSelected = selectedLabelId == label.id;

    return Container(
      width: mapDotSize,
      height: mapDotSize,
      decoration: BoxDecoration(
        color: label.color.withValues(alpha: isDragging ? 0.8 : 1.0),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.blue : (isEditingRoute ? Colors.blue : Colors.white),
          width: isSelected ? 2.5 : (isEditingRoute ? 2.0 : 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected 
                ? Colors.blue.withValues(alpha: 0.5)
                : label.color.withValues(alpha: 0.4),
            blurRadius: isSelected ? 6 : 3,
          ),
        ],
      ),
      child: Center(
        child: label.emoji != null
            ? Text(
                label.emoji!,
                style: TextStyle(
                  fontSize: mapDotSize * 0.55,
                  decoration: TextDecoration.none,
                ),
              )
            : Text(
                '${label.id}',
                style: TextStyle(
                  color: textColor,
                  fontSize: mapDotSize * 0.5,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
      ),
    );
  }

  /// 构建占位图
  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '请选择地图图片',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右侧「选择地图」按钮',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onAcceptWithDetails: (details) {
        final RenderBox? mapBox = mapKey.currentContext?.findRenderObject() as RenderBox?;
        if (mapBox == null) return;
        final Offset localPosition = mapBox.globalToLocal(details.offset);
        final mapSize = mapBox.size;
        final imageBounds = _getImageBounds(mapSize);
        final centerPos = localPosition + Offset(toolbarLabelSize / 2, toolbarLabelSize / 2);
        final relativePos = Offset(
          (centerPos.dx - imageBounds.left) / imageBounds.width,
          (centerPos.dy - imageBounds.top) / imageBounds.height,
        );
        onLabelPlaced(details.data, relativePos);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return GestureDetector(
          onTapUp: editingRouteForLabel != null ? (details) {
            final RenderBox? mapBox = mapKey.currentContext?.findRenderObject() as RenderBox?;
            if (mapBox == null) return;
            final Offset localPosition = mapBox.globalToLocal(details.globalPosition);
            final mapSize = mapBox.size;
            final imageBounds = _getImageBounds(mapSize);
            final relativePoint = Offset(
              (localPosition.dx - imageBounds.left) / imageBounds.width,
              (localPosition.dy - imageBounds.top) / imageBounds.height,
            );
            onRoutePointAdded(relativePoint);
          } : null,
          child: Container(
            key: mapKey,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: editingRouteForLabel != null 
                    ? Colors.blue.shade400 
                    : (isHovering ? Colors.blue.shade400 : Colors.grey.shade300),
                width: editingRouteForLabel != null ? 2.5 : (isHovering ? 2.5 : 1.0),
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: LayoutBuilder(
              builder: (context, mapConstraints) {
                final containerSize = Size(mapConstraints.maxWidth, mapConstraints.maxHeight);
                final imageBounds = _getImageBounds(containerSize);
                return Stack(
                  children: [
                    // 地图图片或占位图
                    Positioned.fill(
                      child: imagePath != null
                          ? (isAssetImage
                              ? Image.asset(imagePath!, fit: BoxFit.contain)
                              : Image.file(File(imagePath!), fit: BoxFit.contain))
                          : _buildPlaceholder(),
                    ),
                    // 绘制所有路线
                    CustomPaint(
                      painter: RoutesPainter(
                        labels: labels,
                        editingLabelId: editingRouteForLabel,
                        tempRoutePath: tempRoutePath,
                        mapDotSize: mapDotSize,
                        imageBounds: imageBounds,
                      ),
                      size: Size.infinite,
                    ),
                    // 已放置在地图上的标签
                    for (var label in labels.where((l) => l.isPlaced))
                      Positioned(
                        left: label.mapPosition!.dx * imageBounds.width + imageBounds.left - mapDotSize / 2,
                        top: label.mapPosition!.dy * imageBounds.height + imageBounds.top - mapDotSize / 2,
                        child: editingRouteForLabel == null
                            ? Draggable<int>(
                                data: label.id,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: _buildLabel(label, isDragging: true),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.2,
                                  child: _buildMapDot(label, isDragging: false),
                                ),
                                onDragStarted: () {
                                  if (selectedLabelId == label.id) {
                                    onLabelDeselected(label.id);
                                  }
                                },
                                child: GestureDetector(
                                  onTap: () => onLabelSelected(label.id),
                                  onDoubleTap: () => onRouteEditToggle(label.id),
                                  child: _buildMapDot(label),
                                ),
                              )
                            : GestureDetector(
                                onTap: () => onLabelSelected(label.id),
                                onDoubleTap: () => onRouteEditToggle(label.id),
                                child: _buildMapDot(label),
                              ),
                      ),
                    // 路线编辑提示
                    if (editingRouteForLabel != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app, size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                '点击地图添加路线点',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
