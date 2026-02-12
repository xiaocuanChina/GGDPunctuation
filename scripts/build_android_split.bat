@echo off
chcp 65001 >nul
echo ========================================
echo    Android 分平台打包（减小体积）
echo ========================================
echo.

REM 设置缓存路径到英文目录(解决中文用户名问题)
set "GRADLE_USER_HOME=C:\DevCache\Gradle"
set "PUB_CACHE=C:\DevCache\Pub"
if not exist "%GRADLE_USER_HOME%" mkdir "%GRADLE_USER_HOME%"
if not exist "%PUB_CACHE%" mkdir "%PUB_CACHE%"

echo [1/3] 清理旧的构建文件...
call flutter clean
echo.

echo [2/3] 获取依赖...
call flutter pub get
echo.

echo [3/3] 打包 Android APK（分平台）...
call flutter build apk --split-per-abi --release
if %errorlevel% neq 0 (
    echo ❌ 打包失败！
    pause
    exit /b %errorlevel%
)
echo.

echo ========================================
echo    打包完成！
echo ========================================
echo.
echo 生成的 APK 文件：
echo.
echo 📱 ARM 32位: build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk
echo 📱 ARM 64位: build\app\outputs\flutter-apk\app-arm64-v8a-release.apk (推荐)
echo 📱 x86 64位: build\app\outputs\flutter-apk\app-x86_64-release.apk
echo.
echo 提示：大多数现代 Android 设备使用 ARM 64位版本
echo.
pause
