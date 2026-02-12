import 'package:flutter/material.dart';
import '../models/label_item.dart';

/// 选中标签操作面板组件
class SelectedLabelPanel extends StatelessWidget {
  final LabelItem label;
  final bool isEditingRoute;
  final double labelSize;
  final VoidCallback onToggleRouteEdit;
  final VoidCallback onUndoLastPoint;
  final VoidCallback onClearRoute;
  final VoidCallback onRemoveFromMap;
  final VoidCallback onClose;
  final Widget Function(LabelItem, {required double labelSize}) buildLabel;

  const SelectedLabelPanel({
    super.key,
    required this.label,
    required this.isEditingRoute,
    required this.labelSize,
    required this.onToggleRouteEdit,
    required this.onUndoLastPoint,
    required this.onClearRoute,
    required this.onRemoveFromMap,
    required this.onClose,
    required this.buildLabel,
  });

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = label.emoji != null ? '${label.emoji} ${label.name}' : (label.name ?? '${label.id}号');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: label.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: label.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标签预览 + 名称 + 关闭
          Row(
            children: [
              buildLabel(label, labelSize: labelSize),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    if (label.hasRoute)
                      Text(
                        isEditingRoute 
                            ? '正在标记路线 (${label.routePath.length}个点)'
                            : '已标记 ${label.routePath.length} 个路线点',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.close, size: 14, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 操作按钮
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // 路线编辑切换
              _buildActionButton(
                icon: isEditingRoute ? Icons.check : Icons.route,
                label: isEditingRoute ? '完成路线' : '标记路线',
                color: isEditingRoute ? Colors.green : Colors.blue,
                onTap: onToggleRouteEdit,
              ),
              // 撤销最后一个路线点
              if (label.hasRoute)
                _buildActionButton(
                  icon: Icons.undo,
                  label: '撤销',
                  color: Colors.orange,
                  onTap: onUndoLastPoint,
                ),
              // 清除所有路线
              if (label.hasRoute)
                _buildActionButton(
                  icon: Icons.delete_outline,
                  label: '清除路线',
                  color: Colors.red.shade400,
                  onTap: onClearRoute,
                ),
              // 从地图中移除
              _buildActionButton(
                icon: Icons.remove_circle_outline,
                label: '移除',
                color: Colors.red,
                onTap: onRemoveFromMap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
