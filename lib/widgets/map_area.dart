import 'dart:io';
import 'package:flutter/material.dart';
import '../models/label_item.dart';
import 'route_painter.dart';

/// 地图区域组件
class MapArea extends StatefulWidget {
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

  @override
  State<MapArea> createState() => _MapAreaState();
}

class _MapAreaState extends State<MapArea> {
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;
  bool _hasTransformed = false; // 标记是否进行了缩放或平移
  DateTime? _lastRightClickTime; // 记录上次右键点击时间

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// 监听缩放变化
  void _onInteractionUpdate(ScaleUpdateDetails details) {
    setState(() {
      _currentScale = _transformationController.value.getMaxScaleOnAxis();
      _hasTransformed = _currentScale > 1.0 || _hasTranslation();
    });
  }

  /// 检查是否有平移
  bool _hasTranslation() {
    final matrix = _transformationController.value;
    return matrix.getTranslation().x != 0 || matrix.getTranslation().y != 0;
  }

  /// 重置地图到初始状态
  void _resetTransform() {
    setState(() {
      _transformationController.value = Matrix4.identity();
      _currentScale = 1.0;
      _hasTransformed = false;
    });
  }

  /// 根据缩放比例计算图标大小
  double _getScaledDotSize() {
    // 基础大小
    final baseSize = widget.mapDotSize;
    // 缩放时适当放大，但不要太大
    // 缩放1倍时保持原大小，缩放2倍时放大到1.3倍，缩放3倍时放大到1.5倍
    final scaleFactor = 1.0 + (_currentScale - 1.0) * 0.25;
    return baseSize * scaleFactor.clamp(1.0, 1.5);
  }

  /// 根据容器大小和图片原始尺寸，计算图片在 BoxFit.contain 下的实际渲染区域
  Rect _getImageBounds(Size containerSize) {
    if (widget.imageNaturalSize == null) {
      return Rect.fromLTWH(0, 0, containerSize.width, containerSize.height);
    }
    final imageAspect = widget.imageNaturalSize!.width / widget.imageNaturalSize!.height;
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

  /// 将 InteractiveViewer 的坐标转换为图片相对坐标
  Offset? _transformToImageCoordinate(Offset globalPosition, Size containerSize) {
    final RenderBox? mapBox = widget.mapKey.currentContext?.findRenderObject() as RenderBox?;
    if (mapBox == null) return null;
    
    // 转换为本地坐标
    final localPosition = mapBox.globalToLocal(globalPosition);
    
    // 应用变换矩阵的逆变换
    final matrix = _transformationController.value;
    final inverse = Matrix4.inverted(matrix);
    final transformed = MatrixUtils.transformPoint(inverse, localPosition);
    
    final imageBounds = _getImageBounds(containerSize);
    
    // 计算相对位置
    final relativePos = Offset(
      (transformed.dx - imageBounds.left) / imageBounds.width,
      (transformed.dy - imageBounds.top) / imageBounds.height,
    );
    
    return relativePos;
  }

  /// 构建工具栏标签组件
  Widget _buildLabel(LabelItem label, {bool isDragging = false}) {
    final textColor = _getTextColorForBackground(label.color);
    final isEditingRoute = widget.editingRouteForLabel == label.id;
    final isSelected = widget.selectedLabelId == label.id;
    final halfSize = widget.toolbarLabelSize / 2;
    final scale = widget.toolbarLabelSize / 28.0;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: widget.toolbarLabelSize,
          height: widget.toolbarLabelSize,
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
    final isEditingRoute = widget.editingRouteForLabel == label.id;
    final isSelected = widget.selectedLabelId == label.id;
    final scaledDotSize = _getScaledDotSize();

    return Container(
      width: scaledDotSize,
      height: scaledDotSize,
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
                  fontSize: scaledDotSize * 0.55,
                  decoration: TextDecoration.none,
                ),
              )
            : Text(
                '${label.id}',
                style: TextStyle(
                  color: textColor,
                  fontSize: scaledDotSize * 0.5,
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
        final RenderBox? mapBox = widget.mapKey.currentContext?.findRenderObject() as RenderBox?;
        if (mapBox == null) return;
        final mapSize = mapBox.size;
        
        // 使用变换后的坐标
        final relativePos = _transformToImageCoordinate(
          details.offset + Offset(widget.toolbarLabelSize / 2, widget.toolbarLabelSize / 2),
          mapSize,
        );
        
        if (relativePos != null) {
          widget.onLabelPlaced(details.data, relativePos);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Listener(
          onPointerDown: (event) {
            // 检测右键点击（button == 2 表示右键）
            if (event.buttons == 2 && widget.editingRouteForLabel != null) {
              final now = DateTime.now();
              if (_lastRightClickTime != null && 
                  now.difference(_lastRightClickTime!) < const Duration(milliseconds: 300)) {
                // 右键双击 - 完成路线编辑
                widget.onRouteEditToggle(widget.editingRouteForLabel!);
                _lastRightClickTime = null;
              } else {
                _lastRightClickTime = now;
              }
            }
          },
          child: GestureDetector(
            onTapUp: widget.editingRouteForLabel != null ? (details) {
              final RenderBox? mapBox = widget.mapKey.currentContext?.findRenderObject() as RenderBox?;
              if (mapBox == null) return;
              final mapSize = mapBox.size;
              
              // 使用变换后的坐标
              final relativePoint = _transformToImageCoordinate(details.globalPosition, mapSize);
              
              if (relativePoint != null) {
                widget.onRoutePointAdded(relativePoint);
              }
            } : null,
          child: Container(
            key: widget.mapKey,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.editingRouteForLabel != null 
                    ? Colors.blue.shade400 
                    : (isHovering ? Colors.blue.shade400 : Colors.grey.shade300),
                width: widget.editingRouteForLabel != null ? 2.5 : (isHovering ? 2.5 : 1.0),
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                // 地图内容
                LayoutBuilder(
                  builder: (context, mapConstraints) {
                    final containerSize = Size(mapConstraints.maxWidth, mapConstraints.maxHeight);
                    final imageBounds = _getImageBounds(containerSize);
                    final scaledDotSize = _getScaledDotSize();
                    
                    return InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 1.0,
                      maxScale: 3.0,
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      panEnabled: widget.imagePath != null,
                      scaleEnabled: widget.imagePath != null,
                      onInteractionUpdate: _onInteractionUpdate,
                      child: Stack(
                        children: [
                          // 地图图片或占位图
                          Positioned.fill(
                            child: widget.imagePath != null
                                ? (widget.isAssetImage
                                    ? Image.asset(widget.imagePath!, fit: BoxFit.contain)
                                    : Image.file(File(widget.imagePath!), fit: BoxFit.contain))
                                : _buildPlaceholder(),
                          ),
                          // 绘制所有路线
                          CustomPaint(
                            painter: RoutesPainter(
                              labels: widget.labels,
                              editingLabelId: widget.editingRouteForLabel,
                              tempRoutePath: widget.tempRoutePath,
                              mapDotSize: scaledDotSize,
                              imageBounds: imageBounds,
                            ),
                            size: Size.infinite,
                          ),
                          // 已放置在地图上的标签
                          for (var label in widget.labels.where((l) => l.isPlaced))
                            Positioned(
                              left: label.mapPosition!.dx * imageBounds.width + imageBounds.left - scaledDotSize / 2,
                              top: label.mapPosition!.dy * imageBounds.height + imageBounds.top - scaledDotSize / 2,
                              child: widget.editingRouteForLabel == null
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
                                        if (widget.selectedLabelId == label.id) {
                                          widget.onLabelDeselected(label.id);
                                        }
                                      },
                                      child: GestureDetector(
                                        onTap: () => widget.onLabelSelected(label.id),
                                        onDoubleTap: () => widget.onRouteEditToggle(label.id),
                                        child: _buildMapDot(label),
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: () => widget.onLabelSelected(label.id),
                                      onDoubleTap: () => widget.onRouteEditToggle(label.id),
                                      child: _buildMapDot(label),
                                    ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                // 路线编辑提示（在 InteractiveViewer 外层）
                if (widget.editingRouteForLabel != null)
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
                // 缩放提示（在 InteractiveViewer 外层，始终显示）
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.zoom_in,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(_currentScale * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 归位按钮（当缩放或平移后显示）
                if (_hasTransformed)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _resetTransform,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.center_focus_strong,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '归位',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }
}
