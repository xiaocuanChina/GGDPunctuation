import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/label_item.dart';
import '../utils/label_utils.dart';
import '../widgets/map_area.dart';
import '../widgets/control_panel.dart';
import '../widgets/floating_panel.dart';
import '../widgets/label_widget.dart';
import 'color_settings_page.dart';
import '../widgets/map_selector_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _imagePath;
  bool _isAssetImage = false;
  final TextEditingController _countController = TextEditingController();
  List<LabelItem> _labels = [];
  Map<int, Color> _colorConfig = {};
  final GlobalKey _mapKey = GlobalKey();
  Size? _imageNaturalSize;
  
  // 路线编辑相关
  int? _editingRouteForLabel;
  List<Offset> _tempRoutePath = [];

  // 选中标签相关
  int? _selectedLabelId;

  // 面板折叠相关
  bool _isPanelCollapsed = false;
  Offset _floatingPanelOffset = const Offset(16, 80);

  // 可用的预设地图列表
  List<Map<String, String>> _availablePresetMaps = [];
  // 自定义地图列表
  List<Map<String, String>> _customMaps = [];

  @override
  void initState() {
    super.initState();
    _checkAvailablePresetMaps();
    _loadCustomMaps();
    _loadColorConfig();
  }

  /// 检查哪些预设地图存在
  Future<void> _checkAvailablePresetMaps() async {
    final available = <Map<String, String>>[];
    for (final map in presetMaps) {
      try {
        await rootBundle.load(map['asset']!);
        available.add(map);
      } catch (e) {
        // 资源不存在，跳过
      }
    }
    if (mounted) {
      setState(() {
        _availablePresetMaps = available;
      });
    }
  }

  /// 从本地存储加载自定义地图列表
  Future<void> _loadCustomMaps() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('custom_maps');
    if (jsonStr != null) {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      final maps = <Map<String, String>>[];
      for (final e in decoded) {
        final map = Map<String, String>.from(e);
        if (File(map['path']!).existsSync()) {
          maps.add(map);
        }
      }
      if (mounted) {
        setState(() {
          _customMaps = maps;
        });
      }
    }
  }

  /// 从本地存储加载颜色配置
  Future<void> _loadColorConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('color_config');
    if (jsonStr != null) {
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      final config = <int, Color>{};
      decoded.forEach((key, value) {
        config[int.parse(key)] = Color(value as int);
      });
      if (mounted) {
        setState(() {
          _colorConfig = config;
        });
      }
    }
  }

  /// 保存颜色配置到本地存储
  Future<void> _saveColorConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> toSave = {};
    _colorConfig.forEach((key, value) {
      toSave[key.toString()] = value.toARGB32();
    });
    await prefs.setString('color_config', jsonEncode(toSave));
  }

  /// 加载图片原始尺寸
  Future<void> _loadImageSize() async {
    if (_imagePath == null) {
      setState(() => _imageNaturalSize = null);
      return;
    }
    try {
      late final Uint8List bytes;
      if (_isAssetImage) {
        final data = await rootBundle.load(_imagePath!);
        bytes = data.buffer.asUint8List();
      } else {
        bytes = await File(_imagePath!).readAsBytes();
      }
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, completer.complete);
      final image = await completer.future;
      if (mounted) {
        setState(() {
          _imageNaturalSize = Size(image.width.toDouble(), image.height.toDouble());
        });
      }
      image.dispose();
    } catch (e) {
      if (mounted) setState(() => _imageNaturalSize = null);
    }
  }

  /// 选择/替换地图图片
  Future<void> _pickImage() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const MapSelectorDialog(),
    );
    
    if (result != null) {
      setState(() {
        _imagePath = result['path'];
        _isAssetImage = result['type'] == 'asset';
      });
      _loadImageSize();
      _loadCustomMaps();
    }
  }

  /// 快捷选择地图
  void _quickSelectMap(String path, bool isAsset) {
    setState(() {
      _imagePath = path;
      _isAssetImage = isAsset;
    });
    _loadImageSize();
  }

  /// 生成随机颜色（排除已使用的颜色）
  Color _generateRandomColor(Set<Color> usedColors) {
    final random = Random();
    Color newColor;
    int attempts = 0;
    const maxAttempts = 100;
    
    do {
      // 生成饱和度和亮度较高的随机颜色，确保视觉效果好
      final hue = random.nextDouble() * 360;
      final saturation = 0.5 + random.nextDouble() * 0.5; // 50%-100%
      final lightness = 0.4 + random.nextDouble() * 0.3; // 40%-70%
      
      newColor = HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
      attempts++;
      
      // 检查颜色是否与已使用的颜色太接近
      bool tooSimilar = false;
      for (final usedColor in usedColors) {
        if (_colorDistance(newColor, usedColor) < 50) {
          tooSimilar = true;
          break;
        }
      }
      
      if (!tooSimilar) break;
      
    } while (attempts < maxAttempts);
    
    return newColor;
  }

  /// 计算两个颜色的距离（简化的欧几里得距离）
  double _colorDistance(Color c1, Color c2) {
    final r1 = (c1.r * 255.0).round();
    final g1 = (c1.g * 255.0).round();
    final b1 = (c1.b * 255.0).round();
    final r2 = (c2.r * 255.0).round();
    final g2 = (c2.g * 255.0).round();
    final b2 = (c2.b * 255.0).round();
    
    return ((r1 - r2) * (r1 - r2) + (g1 - g2) * (g1 - g2) + (b1 - b2) * (b1 - b2)).toDouble();
  }

  /// 根据人数生成标签
  void _generateLabels() {
    final count = int.tryParse(_countController.text);
    if (count == null || count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的人数')),
      );
      return;
    }
    
    // 为超过13的编号生成随机颜色
    if (count > LabelUtils.defaultColors.length) {
      final usedColors = <Color>{};
      
      // 收集1-13编号已经使用的颜色
      for (int i = 1; i <= LabelUtils.defaultColors.length; i++) {
        usedColors.add(LabelUtils.getColorForLabel(i, _colorConfig));
      }
      
      // 收集已经设置的超过13编号的颜色
      for (int i = LabelUtils.defaultColors.length + 1; i <= count; i++) {
        if (_colorConfig.containsKey(i)) {
          usedColors.add(_colorConfig[i]!);
        }
      }
      
      // 为没有设置颜色的超过13的编号生成随机颜色
      for (int i = LabelUtils.defaultColors.length + 1; i <= count; i++) {
        if (!_colorConfig.containsKey(i)) {
          final newColor = _generateRandomColor(usedColors);
          _colorConfig[i] = newColor;
          usedColors.add(newColor);
        }
      }
      
      // 保存颜色配置
      _saveColorConfig();
    }
    
    setState(() {
      _labels = [
        // 默认的"腿"标签排在最前面
        LabelItem(
          id: 0,
          color: const Color.fromRGBO(255, 183, 77, 1),
          name: '腿',
          emoji: '🍗',
        ),
        ...List.generate(count, (i) {
          final id = i + 1;
          return LabelItem(id: id, color: LabelUtils.getColorForLabel(id, _colorConfig));
        }),
      ];
      _selectedLabelId = null;
      _editingRouteForLabel = null;
      _tempRoutePath.clear();
    });
  }

  /// 快捷选择人数
  void _quickSelectCount(int count) {
    _countController.text = count.toString();
    _generateLabels();
  }

  /// 敲铃：重置地图上的标签位置和路线，淘汰位保留不变
  void _ringBell() {
    setState(() {
      for (var label in _labels) {
        if (!label.isEliminated) {
          label.mapPosition = null;
          label.routePath.clear();
        }
      }
      _selectedLabelId = null;
      _editingRouteForLabel = null;
      _tempRoutePath.clear();
    });
  }

  /// 重置：重置所有标签（包括淘汰位）回到默认位置
  void _resetAll() {
    setState(() {
      for (var label in _labels) {
        label.mapPosition = null;
        label.routePath.clear();
        label.isEliminated = false;
      }
      _selectedLabelId = null;
      _editingRouteForLabel = null;
      _tempRoutePath.clear();
    });
  }

  /// 处理标签从地图拖回标签区
  void _handleLabelReturn(int labelId) {
    setState(() {
      final label = _labels.firstWhere((l) => l.id == labelId);
      label.mapPosition = null;
      label.routePath.clear();
      label.isEliminated = false;
      if (_editingRouteForLabel == label.id) {
        _editingRouteForLabel = null;
        _tempRoutePath.clear();
      }
      if (_selectedLabelId == label.id) {
        _selectedLabelId = null;
      }
    });
  }

  /// 处理标签拖入淘汰位
  void _handleLabelEliminate(int labelId) {
    setState(() {
      final label = _labels.firstWhere((l) => l.id == labelId);
      label.mapPosition = null;
      label.routePath.clear();
      label.isEliminated = true;
      if (_editingRouteForLabel == label.id) {
        _editingRouteForLabel = null;
        _tempRoutePath.clear();
      }
      if (_selectedLabelId == label.id) {
        _selectedLabelId = null;
      }
    });
  }

  /// 处理标签放置到地图
  void _handleLabelPlaced(int labelId, Offset relativePos) {
    setState(() {
      final label = _labels.firstWhere((l) => l.id == labelId);
      label.mapPosition = relativePos;
      label.isEliminated = false;
    });
  }

  /// 处理路线点添加
  void _handleRoutePointAdded(Offset relativePoint) {
    setState(() {
      _tempRoutePath.add(relativePoint);
      final label = _labels.firstWhere((l) => l.id == _editingRouteForLabel);
      label.routePath = List.from(_tempRoutePath);
    });
  }

  /// 处理标签选中
  void _handleLabelSelected(int labelId) {
    setState(() {
      _selectedLabelId = _selectedLabelId == labelId ? null : labelId;
      // 选中不同人物时自动结束之前的路线编辑
      if (_editingRouteForLabel != null && _editingRouteForLabel != labelId) {
        _editingRouteForLabel = null;
        _tempRoutePath.clear();
      }
    });
  }

  /// 处理标签取消选中
  void _handleLabelDeselected(int labelId) {
    setState(() {
      if (_selectedLabelId == labelId) {
        _selectedLabelId = null;
      }
    });
  }

  /// 处理路线编辑切换
  void _handleRouteEditToggle(int labelId) {
    setState(() {
      _selectedLabelId = labelId;
      // 结束之前其他人物的路线编辑
      if (_editingRouteForLabel != null && _editingRouteForLabel != labelId) {
        _editingRouteForLabel = null;
        _tempRoutePath.clear();
      }
      // 切换路线编辑状态
      if (_editingRouteForLabel == labelId) {
        // 双击当前编辑中的人物 → 完成标点并取消选中
        _editingRouteForLabel = null;
        _tempRoutePath.clear();
        _selectedLabelId = null;
      } else {
        final label = _labels.firstWhere((l) => l.id == labelId);
        _editingRouteForLabel = labelId;
        _tempRoutePath = List.from(label.routePath);
      }
    });
  }

  /// 打开颜色设置页
  Future<void> _openColorSettings() async {
    final result = await Navigator.push<Map<int, Color>>(
      context,
      MaterialPageRoute(
        builder: (_) => ColorSettingsPage(
          labelCount: _labels.isEmpty ? 10 : _labels.where((l) => l.emoji == null).length,
          colorConfig: Map.from(_colorConfig),
          defaultColors: LabelUtils.defaultColors,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _colorConfig = result;
        // 同步更新现有标签颜色（跳过emoji标签）
        for (var label in _labels) {
          if (label.emoji == null) {
            label.color = LabelUtils.getColorForLabel(label.id, _colorConfig);
          }
        }
      });
      // 保存颜色配置
      _saveColorConfig();
    }
  }

  /// 切换路线编辑状态
  void _handleToggleRouteEdit(int labelId) {
    setState(() {
      if (_editingRouteForLabel == labelId) {
        _editingRouteForLabel = null;
        _tempRoutePath.clear();
      } else {
        final label = _labels.firstWhere((l) => l.id == labelId);
        _editingRouteForLabel = labelId;
        _tempRoutePath = List.from(label.routePath);
      }
    });
  }

  /// 撤销最后一个路线点
  void _handleUndoLastPoint(int labelId) {
    setState(() {
      final label = _labels.firstWhere((l) => l.id == labelId);
      if (label.routePath.isNotEmpty) {
        label.routePath.removeLast();
        if (_editingRouteForLabel == labelId) {
          _tempRoutePath = List.from(label.routePath);
        }
      }
    });
  }

  /// 清除所有路线
  void _handleClearRoute(int labelId) {
    setState(() {
      final label = _labels.firstWhere((l) => l.id == labelId);
      label.routePath.clear();
      _tempRoutePath.clear();
      if (_editingRouteForLabel == labelId) {
        _editingRouteForLabel = null;
      }
    });
  }

  /// 从地图中移除标签
  void _handleRemoveFromMap(int labelId) {
    setState(() {
      final label = _labels.firstWhere((l) => l.id == labelId);
      label.mapPosition = null;
      label.routePath.clear();
      if (_editingRouteForLabel == labelId) {
        _editingRouteForLabel = null;
        _tempRoutePath.clear();
      }
      _selectedLabelId = null;
    });
  }

  /// 构建标签组件（统一的标签渲染方法）
  Widget _buildLabel(LabelItem label, {required double labelSize}) {
    return LabelWidget(
      label: label,
      labelSize: labelSize,
      isSelected: _selectedLabelId == label.id,
      isEditingRoute: _editingRouteForLabel == label.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final toolbarLabelSize = LabelUtils.getToolbarLabelSize(context);
    final mapDotSize = LabelUtils.getMapDotSize(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          // 主内容区域
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 左侧：地图区域
                Expanded(
                  child: MapArea(
                    mapKey: _mapKey,
                    imagePath: _imagePath,
                    isAssetImage: _isAssetImage,
                    labels: _labels,
                    editingRouteForLabel: _editingRouteForLabel,
                    tempRoutePath: _tempRoutePath,
                    selectedLabelId: _selectedLabelId,
                    toolbarLabelSize: toolbarLabelSize,
                    mapDotSize: mapDotSize,
                    imageNaturalSize: _imageNaturalSize,
                    onLabelPlaced: _handleLabelPlaced,
                    onRoutePointAdded: _handleRoutePointAdded,
                    onLabelSelected: _handleLabelSelected,
                    onLabelDeselected: _handleLabelDeselected,
                    onRouteEditToggle: _handleRouteEditToggle,
                  ),
                ),
                if (!_isPanelCollapsed) ...[
                  const SizedBox(width: 16),
                  // 右侧：控制面板
                  ControlPanel(
                    countController: _countController,
                    labels: _labels,
                    selectedLabelId: _selectedLabelId,
                    editingRouteForLabel: _editingRouteForLabel,
                    tempRoutePath: _tempRoutePath,
                    labelSize: toolbarLabelSize,
                    availablePresetMaps: _availablePresetMaps,
                    customMaps: _customMaps,
                    onPickImage: _pickImage,
                    onQuickSelectMap: _quickSelectMap,
                    onGenerateLabels: _generateLabels,
                    onQuickSelectCount: _quickSelectCount,
                    onRingBell: _ringBell,
                    onOpenColorSettings: _openColorSettings,
                    onLabelReturn: _handleLabelReturn,
                    onLabelEliminate: _handleLabelEliminate,
                    onResetAll: _resetAll,
                    onCollapsePanel: () => setState(() => _isPanelCollapsed = true),
                    buildLabel: _buildLabel,
                    onToggleRouteEdit: _handleToggleRouteEdit,
                    onUndoLastPoint: _handleUndoLastPoint,
                    onClearRoute: _handleClearRoute,
                    onRemoveFromMap: _handleRemoveFromMap,
                  ),
                ],
              ],
            ),
          ),
          // 折叠时显示浮窗面板
          if (_isPanelCollapsed)
            FloatingPanel(
              offset: _floatingPanelOffset,
              labels: _labels,
              selectedLabelId: _selectedLabelId,
              editingRouteForLabel: _editingRouteForLabel,
              labelSize: toolbarLabelSize,
              onPanUpdate: (delta) => setState(() => _floatingPanelOffset += delta),
              onExpandPanel: () => setState(() => _isPanelCollapsed = false),
              onRingBell: _ringBell,
              onLabelReturn: _handleLabelReturn,
              onLabelEliminate: _handleLabelEliminate,
              onResetAll: _resetAll,
              buildLabel: _buildLabel,
              onToggleRouteEdit: _handleToggleRouteEdit,
              onUndoLastPoint: _handleUndoLastPoint,
              onClearRoute: _handleClearRoute,
              onRemoveFromMap: _handleRemoveFromMap,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }
}
