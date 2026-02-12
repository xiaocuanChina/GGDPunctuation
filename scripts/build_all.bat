@echo off
chcp 65001 >nul
echo ========================================
echo    GGD标点工具 - 多平台打包脚本
echo ========================================
echo.

REM 设置缓存路径到英文目录(解决中文用户名问题)
set "GRADLE_USER_HOME=C:\DevCache\Gradle"
set "PUB_CACHE=C:\DevCache\Pub"
if not exist "%GRADLE_USER_HOME%" mkdir "%GRADLE_USER_HOME%"
if not exist "%PUB_CACHE%" mkdir "%PUB_CACHE%"

echo [1/5] 停止 Gradle 守护进程...
cd android
call gradlew --stop
cd ..
echo ✅ Gradle 守护进程已停止
echo.

echo [2/5] 清理旧的构建文件...
call flutter clean
echo.

echo [3/5] 获取依赖...
call flutter pub get
echo.

echo [4/5] 打包 Android APK...
call flutter build apk --release --no-tree-shake-icons
if %errorlevel% neq 0 (
    echo.
    echo ❌ Android 打包失败！
    echo.
    echo 尝试使用 Android Studio 安装 NDK：
    echo 1. 打开 Android Studio
    echo 2. Tools ^> SDK Manager ^> SDK Tools
    echo 3. 勾选 "NDK (Side by side)" 版本 27.0.12077973
    echo 4. 点击 Apply 安装
    echo.
    echo 或者跳过 Android 打包，只打包 Windows 版本？
    echo 按任意键继续打包 Windows，或关闭窗口退出
    pause
    goto :windows_build
)
echo ✅ Android APK 打包完成！
echo 输出位置: build\app\outputs\flutter-apk\app-release.apk
echo.

:windows_build
echo [5/5] 打包 Windows 应用...
call flutter build windows --release
if %errorlevel% neq 0 (
    echo ❌ Windows 打包失败！
    pause
    exit /b %errorlevel%
)
echo ✅ Windows 应用打包完成！
echo 输出位置: build\windows\x64\runner\Release\
echo.

echo ========================================
echo    打包完成！
echo ========================================
echo.
if exist build\app\outputs\flutter-apk\app-release.apk (
    echo 📱 Android APK: build\app\outputs\flutter-apk\app-release.apk
    for %%A in (build\app\outputs\flutter-apk\app-release.apk) do echo    大小: %%~zA 字节
)
echo 💻 Windows EXE: build\windows\x64\runner\Release\GGDPunctuation.exe
echo.
echo 提示：iOS 打包需要在 macOS 系统上进行
echo.
pause
