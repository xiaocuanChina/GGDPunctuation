@echo off
chcp 65001 >nul
echo ========================================
echo    Android APK 打包
echo ========================================
echo.

REM 设置缓存路径到英文目录(解决中文用户名问题)
set "GRADLE_USER_HOME=C:\DevCache\Gradle"
set "PUB_CACHE=C:\DevCache\Pub"
if not exist "%GRADLE_USER_HOME%" mkdir "%GRADLE_USER_HOME%"
if not exist "%PUB_CACHE%" mkdir "%PUB_CACHE%"

echo [1/4] 停止 Gradle 守护进程...
cd android
call gradlew --stop
cd ..
echo.

echo [2/4] 清理构建缓存...
call flutter clean
echo.

echo [3/4] 获取依赖...
call flutter pub get
echo.

echo [4/4] 打包 Android APK...
call flutter build apk --release
if %errorlevel% neq 0 (
    echo.
    echo ❌ 打包失败！
    echo.
    echo 如果仍然提示 NDK 错误，请尝试：
    echo 1. 打开 Android Studio
    echo 2. Tools ^> SDK Manager ^> SDK Tools
    echo 3. 勾选 NDK (Side by side) 并安装
    echo.
    echo 或者联系我获取进一步帮助
    echo.
    pause
    exit /b %errorlevel%
)

echo.
echo ========================================
echo    打包成功！
echo ========================================
echo.
echo 📱 APK 位置: build\app\outputs\flutter-apk\app-release.apk
echo.
echo 文件大小:
dir build\app\outputs\flutter-apk\app-release.apk | find "app-release.apk"
echo.
pause
