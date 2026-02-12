import 'package:flutter/material.dart';
import '../models/label_item.dart';

/// 淘汰位区域组件
class EliminationZone extends StatelessWidget {
  final List<LabelItem> labels;
  final double labelSize;
  final Function(int) onLabelEliminate;
  final VoidCallback onResetAll;
  final Widget Function(LabelItem, {required double labelSize}) buildLabel;

  const EliminationZone({
    super.key,
    required this.labels,
    required this.labelSize,
    required this.onLabelEliminate,
    required this.onResetAll,
    required this.buildLabel,
  });

  @override
  Widget build(BuildContext context) {
    final eliminatedLabels = labels.where((l) => l.isEliminated).toList();

    return DragTarget<int>(
      onAcceptWithDetails: (details) => onLabelEliminate(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHovering
                ? Colors.red.withValues(alpha: 0.08)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHovering ? Colors.red.shade400 : Colors.grey.shade300,
              width: isHovering ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isHovering)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cancel, size: 14, color: Colors.red[400]),
                      const SizedBox(width: 4),
                      Text(
                        '松手淘汰该角色',
                        style: TextStyle(color: Colors.red[400], fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              if (eliminatedLabels.isEmpty && !isHovering)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '拖入此处淘汰',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ),
                )
              else if (eliminatedLabels.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: eliminatedLabels.map((label) {
                    return Draggable<int>(
                      data: label.id,
                      feedback: Material(
                        color: Colors.transparent,
                        child: buildLabel(label, labelSize: labelSize),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: buildLabel(label, labelSize: labelSize),
                      ),
                      child: Opacity(
                        opacity: 0.5,
                        child: buildLabel(label, labelSize: labelSize),
                      ),
                    );
                  }).toList(),
                ),
              // 淘汰位重置按钮
              if (eliminatedLabels.isNotEmpty && !isHovering)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onResetAll,
                      icon: Icon(Icons.refresh, size: 14, color: Colors.red[400]),
                      label: Text('重置', style: TextStyle(fontSize: 11, color: Colors.red[400])),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        side: BorderSide(color: Colors.red.shade200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
