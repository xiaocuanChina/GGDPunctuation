# Goose Goose Duck标点工具

一个基于 Flutter 开发的地图标点和路线规划工具，支持在地图上标记人物位置、绘制移动路线，适用于游戏战术规划、活动路线设计等场景。

## 功能特性

- 📍 **地图标点**：支持在地图上拖放标签标记位置
- 🗺️ **路线规划**：双击人物可快捷进入路线编辑模式，点击地图添加路线点
- 🎨 **自定义颜色**：支持为每个标签自定义颜色
- 🏷️ **特殊标签**：支持 emoji 标签（如"腿"标签）
- 🔄 **快速操作**：
  - 敲铃：重置地图上的标签位置和路线（淘汰位保留）
  - 重置：重置所有标签回到默认状态
  - 双击人物：快捷标点、保存路线
- 🗑️ **淘汰区**：拖动标签到淘汰区进行淘汰管理
- 💾 **地图管理**：支持预设地图和自定义地图导入
- 📱 **横屏优化**：自动锁定横屏方向，提供沉浸式体验

## 快速操作说明

- **标记路线**：双击地图上的人物进入路线编辑模式，点击地图添加路线点
- **完成标点**：再次双击同一人物即可保存路线并退出编辑模式
- **拖动标签**：从右侧标签区拖动到地图上进行标记
- **移除标签**：将地图上的标签拖回右侧标签区
- **淘汰管理**：将标签拖到淘汰区进行淘汰

## 运行项目

```bash
# 清理项目
flutter clean

# 获取依赖
flutter pub get

# 运行项目（Windows）
flutter run -d windows

# 运行项目（Android）
flutter run -d android

# 运行项目（iOS）
flutter run -d ios
```

## 项目结构

```
lib/
├── main.dart                    # 主程序入口
├── pages/
│   ├── home_page.dart          # 主页面
│   └── color_settings_page.dart # 颜色设置页
├── widgets/
│   ├── map_area.dart           # 地图区域组件
│   ├── control_panel.dart      # 控制面板组件
│   ├── floating_panel.dart     # 浮动面板组件
│   ├── label_widget.dart       # 标签组件
│   └── route_painter.dart      # 路线绘制组件
├── models/
│   └── label_item.dart         # 标签数据模型
└── utils/
    └── label_utils.dart        # 标签工具类
```

## 技术栈

- Flutter 3.x
- Dart
- shared_preferences（本地存储）