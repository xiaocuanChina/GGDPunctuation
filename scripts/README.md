# 打包脚本说明

本目录包含 GGD标点工具 的各平台打包脚本。

## 脚本列表

### 1. build_all.bat - 全平台打包
打包 Android APK 和 Windows 应用。

**使用方法：**
```bash
cd scripts
build_all.bat
```

**输出：**
- Android APK: `build\app\outputs\flutter-apk\app-release.apk`
- Windows EXE: `build\windows\x64\runner\Release\GGDPunctuation.exe`

---

### 2. build_android.bat - Android 单平台打包
仅打包 Android APK（通用版本，支持所有架构）。

**使用方法：**
```bash
cd scripts
build_android.bat
```

**输出：**
- `build\app\outputs\flutter-apk\app-release.apk`

---

### 3. build_android_split.bat - Android 分架构打包
打包多个 APK 文件，每个文件针对特定 CPU 架构，体积更小。

**使用方法：**
```bash
cd scripts
build_android_split.bat
```

**输出：**
- ARM 32位: `app-armeabi-v7a-release.apk`
- ARM 64位: `app-arm64-v8a-release.apk` （推荐，适用于大多数现代设备）
- x86 64位: `app-x86_64-release.apk`

---

### 4. build_windows_only.bat - Windows 单平台打包
仅打包 Windows 应用。

**使用方法：**
```bash
cd scripts
build_windows_only.bat
```

**输出：**
- `build\windows\x64\runner\Release\GGDPunctuation.exe`
- 注意：需要将整个 Release 文件夹打包分发

---

## 环境要求

- Flutter SDK
- Android SDK（Android 打包需要）
- NDK（Android 打包需要）
- Visual Studio 2019+ 或 Build Tools（Windows 打包需要）

## 常见问题

### 中文用户名问题
脚本已自动设置缓存路径到 `C:\DevCache\`，避免中文路径问题。

### NDK 错误
如果遇到 NDK 相关错误：
1. 打开 Android Studio
2. Tools > SDK Manager > SDK Tools
3. 勾选 "NDK (Side by side)" 版本 27.0.12077973
4. 点击 Apply 安装

### Gradle 守护进程问题
脚本会自动停止 Gradle 守护进程，避免缓存冲突。

---

## 提示

- iOS 打包需要在 macOS 系统上使用 Xcode 进行
- 首次打包可能需要较长时间下载依赖
- 建议在打包前确保网络连接稳定
