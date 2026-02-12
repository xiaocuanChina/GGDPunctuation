import 'package:flutter/material.dart';

/// 标签颜色设置页面
class ColorSettingsPage extends StatefulWidget {
  final int labelCount;
  final Map<int, Color> colorConfig;
  final List<Color> defaultColors;

  const ColorSettingsPage({
    super.key,
    required this.labelCount,
    required this.colorConfig,
    required this.defaultColors,
  });

  @override
  State<ColorSettingsPage> createState() => _ColorSettingsPageState();
}

class _ColorSettingsPageState extends State<ColorSettingsPage> {
  late Map<int, Color> _colorConfig;

  @override
  void initState() {
    super.initState();
    _colorConfig = Map.from(widget.colorConfig);
  }

  /// 获取指定编号的颜色
  Color _getColor(int id) {
    return _colorConfig[id] ??
        widget.defaultColors[(id - 1) % widget.defaultColors.length];
  }

  /// 根据背景色计算合适的文字颜色（黑色或白色）
  Color _getTextColorForBackground(Color backgroundColor) {
    // 计算相对亮度 (0.0 - 1.0)
    final r = (backgroundColor.r * 255.0).round().clamp(0, 255);
    final g = (backgroundColor.g * 255.0).round().clamp(0, 255);
    final b = (backgroundColor.b * 255.0).round().clamp(0, 255);
    final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    // 亮度大于0.5使用黑色，否则使用白色
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// 打开颜色选择器
  void _pickColor(int id) {
    Color selectedColor = _getColor(id);
    final TextEditingController hexController = TextEditingController();
    final TextEditingController rController = TextEditingController();
    final TextEditingController gController = TextEditingController();
    final TextEditingController bController = TextEditingController();

    // 初始化输入框
    void updateInputFields(Color color) {
      final r = (color.r * 255.0).round().clamp(0, 255);
      final g = (color.g * 255.0).round().clamp(0, 255);
      final b = (color.b * 255.0).round().clamp(0, 255);
      hexController.text = '${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
      rController.text = r.toString();
      gController.text = g.toString();
      bController.text = b.toString();
    }

    updateInputFields(selectedColor);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('编号 $id 颜色设置'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 当前选中颜色预览
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 预设颜色选择
                      const Text(
                        '预设颜色',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: widget.defaultColors.length,
                        itemBuilder: (context, index) {
                          final color = widget.defaultColors[index];
                          final isSelected = selectedColor == color;
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedColor = color;
                                updateInputFields(color);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.grey.shade300,
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 24,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      // 自定义颜色输入
                      const Text(
                        '自定义颜色',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // 十六进制输入
                      Row(
                        children: [
                          const SizedBox(
                            width: 40,
                            child: Text('HEX', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 8),
                          const Text('#', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextField(
                              controller: hexController,
                              decoration: const InputDecoration(
                                hintText: 'RRGGBB',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(),
                                isDense: true,
                                counterText: '',
                              ),
                              style: const TextStyle(fontSize: 13),
                              maxLength: 6,
                              onChanged: (value) {
                                if (value.length == 6) {
                                  try {
                                    final color = Color(int.parse('FF$value', radix: 16));
                                    setDialogState(() {
                                      selectedColor = color;
                                      rController.text = ((color.r * 255.0).round().clamp(0, 255)).toString();
                                      gController.text = ((color.g * 255.0).round().clamp(0, 255)).toString();
                                      bController.text = ((color.b * 255.0).round().clamp(0, 255)).toString();
                                    });
                                  } catch (e) {
                                    // 输入无效，忽略
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // RGB 输入
                      Row(
                        children: [
                          const SizedBox(
                            width: 40,
                            child: Text('R', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: rController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '0-255',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 13),
                              onChanged: (value) => _updateColorFromRGB(
                                setDialogState,
                                rController,
                                gController,
                                bController,
                                hexController,
                                (color) => selectedColor = color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(
                            width: 40,
                            child: Text('G', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: gController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '0-255',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 13),
                              onChanged: (value) => _updateColorFromRGB(
                                setDialogState,
                                rController,
                                gController,
                                bController,
                                hexController,
                                (color) => selectedColor = color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(
                            width: 40,
                            child: Text('B', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: bController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '0-255',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 13),
                              onChanged: (value) => _updateColorFromRGB(
                                setDialogState,
                                rController,
                                gController,
                                bController,
                                hexController,
                                (color) => selectedColor = color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    hexController.dispose();
                    rController.dispose();
                    gController.dispose();
                    bController.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _colorConfig[id] = selectedColor;
                    });
                    hexController.dispose();
                    rController.dispose();
                    gController.dispose();
                    bController.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text('确认'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 从 RGB 输入更新颜色
  void _updateColorFromRGB(
    StateSetter setDialogState,
    TextEditingController rController,
    TextEditingController gController,
    TextEditingController bController,
    TextEditingController hexController,
    Function(Color) updateColor,
  ) {
    try {
      final r = int.tryParse(rController.text) ?? 0;
      final g = int.tryParse(gController.text) ?? 0;
      final b = int.tryParse(bController.text) ?? 0;
      
      if (r >= 0 && r <= 255 && g >= 0 && g <= 255 && b >= 0 && b <= 255) {
        final color = Color.fromRGBO(r, g, b, 1);
        setDialogState(() {
          updateColor(color);
          hexController.text = '${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
        });
      }
    } catch (e) {
      // 输入无效，忽略
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('标签颜色设置'),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _colorConfig),
              child: const Text('保存'),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.labelCount,
        itemBuilder: (context, index) {
          final id = index + 1;
          final color = _getColor(id);
          final r = (color.r * 255.0).round().clamp(0, 255);
          final g = (color.g * 255.0).round().clamp(0, 255);
          final b = (color.b * 255.0).round().clamp(0, 255);
          final hexColor = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$id',
                    style: TextStyle(
                      color: _getTextColorForBackground(color),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              title: Text('编号 $id'),
              subtitle: Text(
                hexColor,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickColor(id),
            ),
          );
        },
      ),
    );
  }
}
