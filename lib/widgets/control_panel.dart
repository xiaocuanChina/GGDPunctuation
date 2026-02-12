import 'package:flutter/material.dart';
import '../models/label_item.dart';
import 'label_grid.dart';
import 'elimination_zone.dart';
import 'selected_label_panel.dart';

/// 右侧控制面板组件
class ControlPanel extends StatelessWidget {
  final TextEditingController countController;
  final List<LabelItem> labels;
  final int? selectedLabelId;
  final int? editingRouteForLabel;
  final List<Offset> tempRoutePath;
  final double labelSize;
  final List<Map<String, String>> availablePresetMaps;
  final List<Map<String, String>> customMaps;
  final VoidCallback onPickImage;
  final Function(String, bool) onQuickSelectMap;
  final VoidCallback onGenerateLabels;
  final Function(int) onQuickSelectCount;
  final VoidCallback onRingBell;
  final VoidCallback onOpenColorSettings;
  final Function(int) onLabelReturn;
  final Function(int) onLabelEliminate;
  final VoidCallback onResetAll;
  final VoidCallback onCollapsePanel;
  final Widget Function(LabelItem, {required double labelSize}) buildLabel;
  final Function(int) onToggleRouteEdit;
  final Function(int) onUndoLastPoint;
  final Function(int) onClearRoute;
  final Function(int) onRemoveFromMap;

  const ControlPanel({
    super.key,
    required this.countController,
    required this.labels,
    required this.selectedLabelId,
    required this.editingRouteForLabel,
    required this.tempRoutePath,
    required this.labelSize,
    required this.availablePresetMaps,
    required this.customMaps,
    required this.onPickImage,
    required this.onQuickSelectMap,
    required this.onGenerateLabels,
    required this.onQuickSelectCount,
    required this.onRingBell,
    required this.onOpenColorSettings,
    required this.onLabelReturn,
    required this.onLabelEliminate,
    required this.onResetAll,
    required this.onCollapsePanel,
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

  Widget _buildQuickSelectButton(int count) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => onQuickSelectCount(count),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text('$count人'),
      ),
    );
  }

  Widget _buildQuickMapButton(String name, String path, bool isAsset) {
    return OutlinedButton(
      onPressed: () => onQuickSelectMap(path, isAsset),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        minimumSize: Size.zero,
      ),
      child: Text(name, style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placedCount = labels.where((l) => l.isPlaced).length;
    final eliminatedCount = labels.where((l) => l.isEliminated).length;
    final selectedLabel = selectedLabelId != null 
        ? labels.cast<LabelItem?>().firstWhere((l) => l?.id == selectedLabelId, orElse: () => null)
        : null;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== 地图操作区 =====
            _buildSectionTitle('地图', Icons.map_outlined),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onPickImage,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('选择地图'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 快捷选择地图按钮
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...availablePresetMaps.map((map) => _buildQuickMapButton(map['name']!, map['asset']!, true)),
                ...customMaps.map((map) => _buildQuickMapButton(map['name']!, map['path']!, false)),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // ===== 人数输入区 =====
            _buildSectionTitle('人数', Icons.people_outline),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: countController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '输入人数',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onGenerateLabels,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('生成'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildQuickSelectButton(8),
                const SizedBox(width: 6),
                _buildQuickSelectButton(10),
                const SizedBox(width: 6),
                _buildQuickSelectButton(13),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // ===== 选中标签操作区 =====
            if (selectedLabel != null && selectedLabel.isPlaced) ...[
              _buildSectionTitle('选中操作', Icons.touch_app),
              const SizedBox(height: 8),
              SelectedLabelPanel(
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
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
            ],

            // ===== 待放置标签区 =====
            Row(
              children: [
                Expanded(
                  child: _buildSectionTitle(
                    '标签 ($placedCount/${labels.length}${eliminatedCount > 0 ? ' 淘汰$eliminatedCount' : ''})',
                    Icons.label_outline,
                  ),
                ),
                GestureDetector(
                  onTap: onOpenColorSettings,
                  child: Tooltip(
                    message: '调色',
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.palette_outlined, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 2),
                          Text('调色', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onCollapsePanel,
                  child: Tooltip(
                    message: '浮窗模式',
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.picture_in_picture_alt, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 2),
                          Text('浮窗', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (labels.isNotEmpty)
              Text(
                '拖拽放置到地图，从地图拖回此处可取消',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            const SizedBox(height: 8),
            DragTarget<int>(
              onAcceptWithDetails: (details) => onLabelReturn(details.data),
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: isHovering
                        ? Border.all(color: Colors.blue.shade300, width: 2)
                        : Border.all(color: Colors.transparent, width: 2),
                    color: isHovering ? Colors.blue.withValues(alpha: 0.05) : Colors.transparent,
                  ),
                  child: labels.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              children: [
                                if (isHovering) ...[
                                  Icon(Icons.keyboard_return, size: 24, color: Colors.blue[300]),
                                  const SizedBox(height: 4),
                                  Text('松手放回标签区', style: TextStyle(color: Colors.blue[400], fontSize: 13)),
                                ] else
                                  Text('请先输入人数并生成标签', style: TextStyle(color: Colors.grey[400], fontSize: 13), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            if (isHovering)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text('松手放回标签区', style: TextStyle(color: Colors.blue[400], fontSize: 11, fontWeight: FontWeight.w500)),
                              ),
                            LabelGrid(labels: labels, labelSize: labelSize, buildLabel: buildLabel),
                          ],
                        ),
                );
              },
            ),

            // ===== 淘汰位 =====
            if (labels.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _buildSectionTitle('淘汰位', Icons.cancel_outlined),
              const SizedBox(height: 8),
              EliminationZone(
                labels: labels,
                labelSize: labelSize,
                onLabelEliminate: onLabelEliminate,
                onResetAll: onResetAll,
                buildLabel: buildLabel,
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ===== 操作按钮区 =====
            OutlinedButton.icon(
              onPressed: labels.isEmpty ? null : onRingBell,
              icon: const Icon(Icons.notifications_outlined, size: 18),
              label: const Text('敲铃'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
