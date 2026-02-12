import 'package:flutter/material.dart';
import '../models/label_item.dart';

/// 标签网格布局组件（鸡腿未使用时单独一行，拖走后不保留空位；人物一行3个，保留空位）
class LabelGrid extends StatelessWidget {
  final List<LabelItem> labels;
  final double labelSize;
  final Widget Function(LabelItem, {required double labelSize}) buildLabel;

  const LabelGrid({
    super.key,
    required this.labels,
    required this.labelSize,
    required this.buildLabel,
  });

  @override
  Widget build(BuildContext context) {
    final chickenLeg = labels.where((l) => l.emoji != null).toList();
    final numberedLabels = labels.where((l) => l.emoji == null).toList();
    final showChickenLeg = chickenLeg.any((l) => !l.isPlaced && !l.isEliminated);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 鸡腿单独一行（拖走后整行消失，不保留空位）
        if (showChickenLeg)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Draggable<int>(
              data: chickenLeg.first.id,
              feedback: Material(
                color: Colors.transparent,
                child: buildLabel(chickenLeg.first, labelSize: labelSize),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: buildLabel(chickenLeg.first, labelSize: labelSize),
              ),
              child: buildLabel(chickenLeg.first, labelSize: labelSize),
            ),
          ),
        // 人物标签一行3个（已放置或淘汰时保留空位，位置固定不变）
        if (numberedLabels.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final itemWidth = (availableWidth - 12) / 3;
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: numberedLabels.map((label) {
                  final isOccupied = label.isPlaced || label.isEliminated;
                  return SizedBox(
                    width: itemWidth,
                    child: Center(
                      child: isOccupied
                          ? SizedBox(width: labelSize, height: labelSize)
                          : Draggable<int>(
                              data: label.id,
                              feedback: Material(
                                color: Colors.transparent,
                                child: buildLabel(label, labelSize: labelSize),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: buildLabel(label, labelSize: labelSize),
                              ),
                              child: buildLabel(label, labelSize: labelSize),
                            ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }
}
