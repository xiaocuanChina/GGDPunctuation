@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo    Android 分平台打包（减小体积）
echo ========================================
echo.

REM 设置缓存路径到英文目录(解决中文用户名问题)
set "GRADLE_USER_HOME=C:\DevCache\Gradle"
set "PUB_CACHE=C:\DevCache\Pub"
if not exist "%GRADLE_USER_HOME%" mkdir "%GRADLE_USER_HOME%"
if not exist "%PUB_CACHE%" mkdir "%PUB_CACHE%"

REM 定义输出文件名
set "OUTPUT_DIR=dist"
set "APK_SRC=build\app\outputs\flutter-apk"

echo 请选择打包版本：
echo.
echo   [1] 仅打包含地图版本 (包含 assets\maps)
echo   [2] 仅打包不含地图版本 (不包含 assets\maps)
echo   [3] 打包两个版本 (含地图 + 不含地图)
echo.
set /p "BUILD_CHOICE=请输入选项 (1/2/3): "

if "%BUILD_CHOICE%"=="1" (
    set "BUILD_WITH_MAPS=1"
    set "BUILD_WITHOUT_MAPS=0"
    goto :start_build
)
if "%BUILD_CHOICE%"=="2" (
    set "BUILD_WITH_MAPS=0"
    set "BUILD_WITHOUT_MAPS=1"
    goto :start_build
)
if "%BUILD_CHOICE%"=="3" (
    set "BUILD_WITH_MAPS=1"
    set "BUILD_WITHOUT_MAPS=1"
    goto :start_build
)
echo 无效的选项！
pause
exit /b 1

:start_build
REM 创建输出目录
if not exist "!OUTPUT_DIR!" mkdir "!OUTPUT_DIR!"

echo.

REM 打包含地图版本
if "!BUILD_WITH_MAPS!"=="1" call :build_with_maps

REM 打包不含地图版本
if "!BUILD_WITHOUT_MAPS!"=="1" call :build_without_maps

goto :summary

REM ========================================
REM    含地图版本打包
REM ========================================
:build_with_maps
echo ========================================
echo    正在打包含地图版本（分平台）...
echo ========================================
echo.

echo 清理构建缓存...
call flutter clean
echo.

echo 获取依赖...
call flutter pub get
echo.

echo 打包 Android APK（分平台，含地图）...
call flutter build apk --split-per-abi --release
if errorlevel 1 (
    echo ❌ 含地图版本分平台打包失败！
    pause
    goto :eof
)
echo.

REM 复制并重命名各平台 APK
if exist "!APK_SRC!\app-armeabi-v7a-release.apk" (
    copy /Y "!APK_SRC!\app-armeabi-v7a-release.apk" "!OUTPUT_DIR!\GGD标记(含地图)-armeabi-v7a.apk" >nul
)
if exist "!APK_SRC!\app-arm64-v8a-release.apk" (
    copy /Y "!APK_SRC!\app-arm64-v8a-release.apk" "!OUTPUT_DIR!\GGD标记(含地图)-arm64-v8a.apk" >nul
)
if exist "!APK_SRC!\app-x86_64-release.apk" (
    copy /Y "!APK_SRC!\app-x86_64-release.apk" "!OUTPUT_DIR!\GGD标记(含地图)-x86_64.apk" >nul
)
echo √ 含地图版本分平台 APK 打包完成
echo.
goto :eof

REM ========================================
REM    不含地图版本打包
REM ========================================
:build_without_maps
echo ========================================
echo    正在打包不含地图版本（分平台）...
echo ========================================
echo.

REM 备份 pubspec.yaml
copy /Y pubspec.yaml pubspec.yaml.bak >nul
echo √ 已备份 pubspec.yaml

REM 移除 pubspec.yaml 中的 assets/maps/ 引用
powershell -NoProfile -Command "$p = (Resolve-Path 'pubspec.yaml').Path; $lines = Get-Content $p; $out = @(); foreach ($l in $lines) { if ($l -notmatch 'assets/maps/') { $out += $l } }; $utf8 = New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllLines($p, $out, $utf8)"
echo √ 已移除 assets\maps 引用
echo.

echo 清理构建缓存...
call flutter clean
echo.

echo 获取依赖...
call flutter pub get
echo.

echo 打包 Android APK（分平台，不含地图）...
call flutter build apk --split-per-abi --release
if errorlevel 1 (
    echo ❌ 不含地图版本分平台打包失败！
    pause
    goto :restore_pubspec
)
echo.

REM 复制并重命名各平台 APK
if exist "!APK_SRC!\app-armeabi-v7a-release.apk" (
    copy /Y "!APK_SRC!\app-armeabi-v7a-release.apk" "!OUTPUT_DIR!\GGD标记-armeabi-v7a.apk" >nul
)
if exist "!APK_SRC!\app-arm64-v8a-release.apk" (
    copy /Y "!APK_SRC!\app-arm64-v8a-release.apk" "!OUTPUT_DIR!\GGD标记-arm64-v8a.apk" >nul
)
if exist "!APK_SRC!\app-x86_64-release.apk" (
    copy /Y "!APK_SRC!\app-x86_64-release.apk" "!OUTPUT_DIR!\GGD标记-x86_64.apk" >nul
)
echo √ 不含地图版本分平台 APK 打包完成
echo.

:restore_pubspec
REM 恢复 pubspec.yaml
copy /Y pubspec.yaml.bak pubspec.yaml >nul
del /F pubspec.yaml.bak >nul
echo √ pubspec.yaml 已恢复
echo.
goto :eof

REM ========================================
REM    打包汇总
REM ========================================
:summary
echo.
echo ========================================
echo    打包完成！
echo ========================================
echo.
echo 输出目录: !OUTPUT_DIR!\
echo.
echo 生成的 APK 文件：
echo.
call :show_if_exist "GGD标记(含地图)-arm64-v8a.apk" "ARM 64位 (含地图)(推荐)"
call :show_if_exist "GGD标记(含地图)-armeabi-v7a.apk" "ARM 32位 (含地图)"
call :show_if_exist "GGD标记(含地图)-x86_64.apk" "x86 64位 (含地图)"
call :show_if_exist "GGD标记-arm64-v8a.apk" "ARM 64位 (不含地图)(推荐)"
call :show_if_exist "GGD标记-armeabi-v7a.apk" "ARM 32位 (不含地图)"
call :show_if_exist "GGD标记-x86_64.apk" "x86 64位 (不含地图)"
echo.
echo 提示：大多数现代 Android 设备使用 ARM 64位版本
echo.
pause
exit /b 0

:show_if_exist
if exist "!OUTPUT_DIR!\%~1" (
    echo 📱 %~2: !OUTPUT_DIR!\%~1
    for %%A in ("!OUTPUT_DIR!\%~1") do echo    大小: %%~zA 字节
)
goto :eof
