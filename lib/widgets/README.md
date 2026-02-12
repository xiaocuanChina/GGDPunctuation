# 组件结构说明

## 组件划分

### 1. 核心组件

#### `route_painter.dart` - 路线绘制器
- 负责在地图上绘制标签的移动路线
- 支持路线点、连线和箭头的绘制
- 使用相对坐标系统，适配不同尺寸的地图

#### `map_area.dart` - 地图区域组件
- 显示地图图片（支持资源图片和本地文件）
- 处理标签的拖放操作
- 管理地图上的标签位置
- 支持路线编辑模式

#### `label_widget.dart` - 标签渲染组件
- 统一的标签视觉呈现
- 支持不同状态：普通、选中、编辑路线、拖拽中
- 显示路线指示器

### 2. 布局组件

#### `label_grid.dart` - 标签网格布局
- 管理标签的网格排列
- 鸡腿标签单独一行
- 人物标签3个一行，保留空位

#### `elimination_zone.dart` - 淘汰区组件
- 显示已淘汰的标签
- 支持拖入淘汰和拖出恢复
- 提供重置功能

#### `selected_label_panel.dart` - 选中标签操作面板
- 显示选中标签的详细信息
- 提供路线编辑、撤销、清除等操作
- 支持从地图移除标签

### 3. 面板组件

#### `control_panel.dart` - 右侧控制面板
- 完整的控制界面
- 包含地图选择、人数输入、标签管理等功能
- 可折叠为浮窗模式

#### `floating_panel.dart` - 浮窗面板
- 折叠后的精简面板
- 可拖拽移动
- 左右布局：标签区 + 淘汰位

### 4. 工具类

#### `label_utils.dart` - 标签工具类
- 颜色管理（13种预设颜色）
- 标签尺寸计算（响应式）
- 文字颜色计算（根据背景色自动选择黑/白）

## 数据流

```
HomePage (主页面)
  ├─ 状态管理
  │   ├─ _labels (标签列表)
  │   ├─ _selectedLabelId (选中的标签)
  │   ├─ _editingRouteForLabel (正在编辑路线的标签)
  │   └─ _colorConfig (颜色配置)
  │
  ├─ MapArea (地图区域)
  │   ├─ 接收：labels, selectedLabelId, editingRouteForLabel
  │   └─ 回调：onLabelPlaced, onRoutePointAdded, onLabelSelected
  │
  └─ ControlPanel / FloatingPanel (控制面板)
      ├─ 接收：labels, selectedLabelId, editingRouteForLabel
      └─ 回调：onGenerateLabels, onRingBell, onToggleRouteEdit, etc.
```

## 回调函数说明

### 标签操作
- `onLabelPlaced(int labelId, Offset position)` - 标签放置到地图
- `onLabelReturn(int labelId)` - 标签从地图拖回
- `onLabelEliminate(int labelId)` - 标签拖入淘汰位
- `onLabelSelected(int labelId)` - 选中标签
- `onLabelDeselected(int labelId)` - 取消选中

### 路线操作
- `onRoutePointAdded(Offset point)` - 添加路线点
- `onToggleRouteEdit(int labelId)` - 切换路线编辑状态
- `onUndoLastPoint(int labelId)` - 撤销最后一个路线点
- `onClearRoute(int labelId)` - 清除所有路线

### 其他操作
- `onGenerateLabels()` - 生成标签
- `onRingBell()` - 敲铃（重置非淘汰标签）
- `onResetAll()` - 重置所有标签
- `onRemoveFromMap(int labelId)` - 从地图移除标签

## 使用示例

```dart
// 在 HomePage 中使用
MapArea(
  mapKey: _mapKey,
  labels: _labels,
  selectedLabelId: _selectedLabelId,
  onLabelPlaced: (labelId, position) {
    setState(() {
      final label = _labels.firstWhere((l) => l.id == labelId);
      label.mapPosition = position;
    });
  },
  // ... 其他参数
)
```

## 注意事项

1. 所有组件都是无状态的（StatelessWidget），状态由 HomePage 统一管理
2. 使用回调函数进行父子组件通信
3. 标签尺寸根据屏幕大小自动调整
4. 地图使用相对坐标系统（0.0-1.0），适配不同尺寸
