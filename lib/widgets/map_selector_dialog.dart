import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 预设地图列表（全局常量）
const List<Map<String, String>> presetMaps = [
  {'name': '地下室（实验室）', 'asset': 'assets/maps/map_1.jpeg'},
  {'name': '老妈鹅飞船（电机室）', 'asset': 'assets/maps/map_2.jpeg'},
  {'name': '丛林神殿（敬拜坑）', 'asset': 'assets/maps/map_3.jpeg'},
  {'name': '鹅教堂（港口）', 'asset': 'assets/maps/map_4.jpeg'},
];

/// 自定义地图持久化Key
const String _customMapsKey = 'custom_maps';

/// 地图选择对话框
class MapSelectorDialog extends StatefulWidget {
  const MapSelectorDialog({super.key});

  @override
  State<MapSelectorDialog> createState() => _MapSelectorDialogState();
}

class _MapSelectorDialogState extends State<MapSelectorDialog> {
  List<Map<String, String>> _customMaps = [];
  List<Map<String, String>> _availablePresetMaps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomMaps();
    _checkPresetMaps();
  }

  /// 检查预设地图是否存在
  Future<void> _checkPresetMaps() async {
    final available = <Map<String, String>>[];
    for (final map in presetMaps) {
      try {
        // 尝试加载资源，如果成功则说明存在
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
    final jsonStr = prefs.getString(_customMapsKey);
    if (jsonStr != null) {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      // 过滤掉文件已不存在的记录
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
          _isLoading = false;
        });
      }
      // 如果过滤后数量变了，同步更新存储
      if (maps.length != decoded.length) {
        await _saveCustomMaps();
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 保存自定义地图列表到本地存储
  Future<void> _saveCustomMaps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customMapsKey, jsonEncode(_customMaps));
  }

  /// 获取自定义地图的存储目录
  Future<Directory> _getCustomMapsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final mapsDir = Directory('${appDir.path}/ggd_custom_maps');
    if (!await mapsDir.exists()) {
      await mapsDir.create(recursive: true);
    }
    return mapsDir;
  }

  /// 从本地添加地图（选择文件 → 命名 → 复制持久化 → 保存）
  Future<void> _addLocalMap() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;

    final sourcePath = result.files.single.path!;
    final fileName = result.files.single.name;

    if (!mounted) return;

    // 弹出命名对话框
    final name = await _showNameDialog(fileName);
    if (name == null || !mounted) return;

    // 复制图片到应用持久化目录
    final mapsDir = await _getCustomMapsDir();
    final ext = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.'))
        : '.png';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final destPath = '${mapsDir.path}/map_$timestamp$ext';
    await File(sourcePath).copy(destPath);

    // 保存元数据
    final newMap = {'name': name, 'path': destPath};
    setState(() {
      _customMaps.add(newMap);
    });
    await _saveCustomMaps();

    // 选择该地图并关闭对话框
    if (mounted) {
      Navigator.pop(context, {
        'type': 'local',
        'path': destPath,
      });
    }
  }

  /// 弹出地图命名对话框
  Future<String?> _showNameDialog(String defaultName) {
    final baseName = defaultName.contains('.')
        ? defaultName.substring(0, defaultName.lastIndexOf('.'))
        : defaultName;
    final controller = TextEditingController(text: baseName);

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('命名地图'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '输入地图名称',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          autofocus: true,
          onSubmitted: (value) {
            final text = value.trim();
            Navigator.pop(context, text.isEmpty ? baseName : text);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(context, text.isEmpty ? baseName : text);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 删除自定义地图
  Future<void> _deleteCustomMap(int index) async {
    final map = _customMaps[index];

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('删除地图'),
        content: Text('确定要删除「${map['name']}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 删除文件
      final file = File(map['path']!);
      if (await file.exists()) {
        await file.delete();
      }
      setState(() {
        _customMaps.removeAt(index);
      });
      await _saveCustomMaps();
    }
  }

  /// 编辑自定义地图名称
  Future<void> _editCustomMapName(int index) async {
    final map = _customMaps[index];
    final newName = await _showNameDialog(map['name']!);
    
    if (newName != null && newName.isNotEmpty && newName != map['name']) {
      setState(() {
        _customMaps[index]['name'] = newName;
      });
      await _saveCustomMaps();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        // 限制最大高度，防止超出屏幕
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(Icons.map_outlined, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  '选择地图',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 可滚动的地图列表区域
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 预设地图网格（只显示存在的）
                    if (_availablePresetMaps.isNotEmpty) ...[
                      const Text(
                        '预设地图',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: _availablePresetMaps.length,
                        itemBuilder: (context, index) {
                          final map = _availablePresetMaps[index];
                          return _buildPresetMapCard(
                            context,
                            map['name']!,
                            map['asset']!,
                          );
                        },
                      ),
                    ],

                    // 自定义地图网格
                    if (!_isLoading && _customMaps.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        '自定义地图',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: _customMaps.length,
                        itemBuilder: (context, index) {
                          final map = _customMaps[index];
                          return _buildCustomMapCard(
                            context,
                            map['name']!,
                            map['path']!,
                            index,
                          );
                        },
                      ),
                    ],

                    // 加载中提示
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // 从本地选择按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addLocalMap,
                icon: const Icon(Icons.folder_open),
                label: const Text('从本地选择图片'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建预设地图卡片
  Widget _buildPresetMapCard(
      BuildContext context, String name, String assetPath) {
    return InkWell(
      onTap: () {
        Navigator.pop(context, {
          'type': 'asset',
          'path': assetPath,
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // 如果图片不存在，显示占位图
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 4),
                          Text(
                            '暂无预览',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建自定义地图卡片（带删除按钮）
  Widget _buildCustomMapCard(
      BuildContext context, String name, String filePath, int index) {
    return InkWell(
      onTap: () {
        Navigator.pop(context, {
          'type': 'local',
          'path': filePath,
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Image.file(
                        File(filePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_outlined,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 4),
                              Text(
                                '图片加载失败',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            // 编辑按钮
            Positioned(
              top: 4,
              left: 4,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _editCustomMapName(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            // 删除按钮
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _deleteCustomMap(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
