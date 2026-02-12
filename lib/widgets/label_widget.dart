import 'package:flutter/material.dart';
import '../models/label_item.dart';
import '../utils/label_utils.dart';

/// 标签渲染组件
class LabelWidget extends StatelessWidget {
  final LabelItem label;
  final double labelSize;
  final bool isDragging;
  final bool isSelected;
  final bool isEditingRoute;

  const LabelWidget({
    super.key,
    required this.label,
    required this.labelSize,
    this.isDragging = false,
    this.isSelected = false,
    this.isEditingRoute = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = LabelUtils.getTextColorForBackground(label.color);
    final halfSize = labelSize / 2;
    final scale = labelSize / 28.0;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: labelSize,
          height: labelSize,
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
        // 路线指示器
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
}
