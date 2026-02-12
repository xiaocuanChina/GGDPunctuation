# 打包脚本说明

本目录包含 GGD标点工具 的各平台打包脚本。

## 重要说明

所有脚本运行时都会提示选择打包版本：
1. **仅打包含地图版本** — 包含 `assets\maps` 地图资源
2. **仅打包不含地图版本** — 不包含地图资源，体积更小
3. **打包两个版本** — 同时生成含地图和不含地图版本

所有打包产物统一输出到项目根目录的 `dist\` 文件夹。

> **注意：** 地图资源需要自行准备。请将地图文件放置到 `assets\maps\` 目录下后再选择"含地图版本"进行打包，否则即使选择含地图版本，打包产物中也不会包含实际的地图数据。

## 脚本列表

### 1. build_all.bat - 全平台打包
同时打包 Android APK 和 Windows 应用。

**使用方法：**
```bash
cd scripts
build_all.bat
```

**输出：**
| 版本 | 产物 | 路径 |
|------|------|------|
| Android 含地图 | APK | `dist\GGD标记(含地图).apk` |
| Android 不含地图 | APK | `dist\GGD标记.apk` |
| Windows 含地图 | 文件夹 | `dist\GGD标记(含地图)\` |
| Windows 不含地图 | ZIP | `dist\GGD标记.zip` |

---

### 2. build_android.bat - Android 单平台打包
仅打包 Android APK（通用版本，支持所有架构）。

**使用方法：**
```bash
cd scripts
build_android.bat
```

**输出：**
| 版本 | 路径 |
|------|------|
| 含地图 | `dist\GGD标记(含地图).apk` |
| 不含地图 | `dist\GGD标记.apk` |

---

### 3. build_android_split.bat - Android 分架构打包
打包多个 APK 文件，每个文件针对特定 CPU 架构，体积更小。

**使用方法：**
```bash
cd scripts
build_android_split.bat
```

**输出：**
| 版本 | 架构 | 路径 |
|------|------|------|
| 含地图 | ARM 64位（推荐） | `dist\GGD标记(含地图)-arm64-v8a.apk` |
| 含地图 | ARM 32位 | `dist\GGD标记(含地图)-armeabi-v7a.apk` |
| 含地图 | x86 64位 | `dist\GGD标记(含地图)-x86_64.apk` |
| 不含地图 | ARM 64位（推荐） | `dist\GGD标记-arm64-v8a.apk` |
| 不含地图 | ARM 32位 | `dist\GGD标记-armeabi-v7a.apk` |
| 不含地图 | x86 64位 | `dist\GGD标记-x86_64.apk` |

**提示：** 大多数现代 Android 设备使用 ARM 64位版本。

---

### 4. build_windows_only.bat - Windows 单平台打包
仅打包 Windows 应用。

**使用方法：**
```bash
cd scripts
build_windows_only.bat
```

**输出：**
| 版本 | 产物 | 路径 |
|------|------|------|
| 含地图 | 文件夹 | `dist\GGD标记(含地图)\` |
| 不含地图 | ZIP | `dist\GGD标记.zip` |

**说明：**
- 不含地图版本自动压缩为 ZIP，方便分发
- 含地图版本输出为文件夹，需要手动压缩或整体分发

---

## 环境要求

- Flutter SDK
- Android SDK（Android 打包需要）
- NDK（Android 打包需要）
- Visual Studio 2019+ 或 Build Tools（Windows 打包需要）

## 命名规则

### 含地图版本
- 包含 `assets/maps` 目录下的所有地图资源
- **地图资源需要自行准备**，将地图文件放入 `assets\maps\` 目录即可
- 文件名带有 `(含地图)` 标记
- 文件体积较大
- 适合需要离线地图功能的用户

### 不含地图版本
- 不包含 `assets/maps` 地图资源
- 文件名无额外标记，仅为 `GGD标记`
- 文件体积更小
- 适合不需要离线地图或网络环境良好的用户

## 工作原理

### 不含地图版本打包流程
1. 备份原始 `pubspec.yaml` 为 `pubspec.yaml.bak`
2. 移除 `pubspec.yaml` 中的 `assets/maps/` 配置（通过 PowerShell 实现）
3. 执行 `flutter clean` + `flutter pub get` + 构建
4. 自动恢复原始 `pubspec.yaml`，删除备份文件
5. Windows 不含地图版本自动压缩为 ZIP（使用 PowerShell 的 Compress-Archive）

整个过程完全自动化，无需手动修改配置文件。

---

## 常见问题

### 中文用户名问题
脚本已自动设置缓存路径到 `C:\DevCache\`，避免中文路径导致的构建失败。

### NDK 错误
如果遇到 NDK 相关错误：
1. 打开 Android Studio
2. Tools > SDK Manager > SDK Tools
3. 勾选 "NDK (Side by side)" 版本 27.0.12077973
4. 点击 Apply 安装

### Gradle 守护进程问题
`build_all.bat` 和 `build_android.bat` 会自动停止 Gradle 守护进程，避免缓存冲突。

### 配置文件恢复
如果打包过程中断，可能导致 `pubspec.yaml` 未恢复。此时可以：
1. 检查项目根目录是否存在 `pubspec.yaml.bak`
2. 如果存在，手动重命名回 `pubspec.yaml`
3. 运行 `flutter pub get` 恢复依赖

---

## 提示

- iOS 打包需要在 macOS 系统上使用 Xcode 进行
- 首次打包可能需要较长时间下载依赖
- 建议在打包前确保网络连接稳定
- 选择"打包两个版本"时需要执行两次完整构建，耗时较长
