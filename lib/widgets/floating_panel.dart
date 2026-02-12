import 'package:flutter/material.dart';
import '../models/label_item.dart';
import 'label_grid.dart';
import 'elimination_zone.dart';
import 'selected_label_panel.dart';

/// 浮窗标签面板组件（左右布局：左边标签区，右边淘汰位，选中时底部显示操作区）
class FloatingPanel extends StatelessWidget {
  final Offset offset;
  final List<LabelItem> labels;
  final int? selectedLabelId;
  final int? editingRouteForLabel;
  final double labelSize;
  final Function(Offset) onPanUpdate;
  final VoidCallback onExpandPanel;
  final VoidCallback onRingBell;
  final Function(int) onLabelReturn;
  final Function(int) onLabelEliminate;
  final VoidCallback onResetAll;
  final Widget Function(LabelItem, {required double labelSize}) buildLabel;
  final Function(int) onToggleRouteEdit;
  final Function(int) onUndoLastPoint;
  final Function(int) onClearRoute;
  final Function(int) onRemoveFromMap;

  const FloatingPanel({
    super.key,
    required this.offset,
    required this.labels,
    required this.selectedLabelId,
    required this.editingRouteForLabel,
    required this.labelSize,
    required this.onPanUpdate,
    required this.onExpandPanel,
    required this.onRingBell,
    required this.onLabelReturn,
    required this.onLabelEliminate,
    required this.onResetAll,
    required this.buildLabel,
    required this.onToggleRouteEdit,
    required this.onUndoLastPoint,
    required this.onClearRoute,
    required this.onRemoveFromMap,
  });

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final placedCount = labels.where((l) => l.isPlaced).length;
    final eliminatedCount = labels.where((l) => l.isEliminated).length;
    final panelWidth = labels.isNotEmpty ? 321.0 : 200.0;
    final selectedLabel = selectedLabelId != null 
        ? labels.cast<LabelItem?>().firstWhere((l) => l?.id == selectedLabelId, orElse: () => null)
        : null;
    
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        shadowColor: Colors.black.withValues(alpha: 0.15),
        child: Container(
          width: panelWidth,
          constraints: const BoxConstraints(maxHeight: 450),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 拖拽手柄区域
              GestureDetector(
                onPanUpdate: (details) => onPanUpdate(details.delta),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.drag_indicator, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        '标签 ($placedCount/${labels.length}${eliminatedCount > 0 ? ' 淘汰$eliminatedCount' : ''})',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                      ),
                      const Spacer(),
                      // 敲铃按钮
                      if (labels.isNotEmpty)
                        GestureDetector(
                          onTap: onRingBell,
                          child: Tooltip(
                            message: '敲铃',
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.notifications_outlined, size: 16, color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      // 展开面板按钮
                      GestureDetector(
                        onTap: onExpandPanel,
                        child: Tooltip(
                          message: '展开面板',
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.open_in_full, size: 16, color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 主内容区域：左边标签区，右边淘汰位
              Flexible(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左侧：标签区
                    SizedBox(
                      width: 200,
                      child: DragTarget<int>(
                        onAcceptWithDetails: (details) => onLabelReturn(details.data),
                        builder: (context, candidateData, rejectedData) {
                          final isHovering = candidateData.isNotEmpty;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: isHovering ? Colors.blue.withValues(alpha: 0.05) : Colors.transparent,
                              border: isHovering
                                  ? Border.all(color: Colors.blue.shade300, width: 2)
                                  : Border.all(color: Colors.transparent, width: 2),
                            ),
                            child: labels.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      '请先展开面板生成标签',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (isHovering)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 6),
                                            child: Text(
                                              '松手放回标签区',
                                              style: TextStyle(color: Colors.blue[400], fontSize: 11, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        LabelGrid(labels: labels, labelSize: labelSize, buildLabel: buildLabel),
                                      ],
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                    // 分隔线
                    if (labels.isNotEmpty)
                      Container(
                        width: 1,
                        color: Colors.grey[200],
                        margin: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    // 右侧：淘汰位
                    if (labels.isNotEmpty)
                      SizedBox(
                        width: 120,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildSectionTitle('淘汰位', Icons.cancel_outlined),
                              const SizedBox(height: 6),
                              EliminationZone(
                                labels: labels,
                                labelSize: labelSize,
                                onLabelEliminate: onLabelEliminate,
                                onResetAll: onResetAll,
                                buildLabel: buildLabel,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // 选中标签操作区
              if (selectedLabel != null && selectedLabel.isPlaced) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: SelectedLabelPanel(
                    label: selectedLabel,
                    isEditingRoute: editingRouteForLabel == selectedLabel.id,
                    labelSize: labelSize,
                    buildLabel: buildLabel,
                    onToggleRouteEdit: () => onToggleRouteEdit(selectedLabel.id),
                    onUndoLastPoint: () => onUndoLastPoint(selectedLabel.id),
                    onClearRoute: () => onClearRoute(selectedLabel.id),
                    onRemoveFromMap: () => onRemoveFromMap(selectedLabel.id),
                    onClose: () => onRemoveFromMap(selectedLabel.id),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
