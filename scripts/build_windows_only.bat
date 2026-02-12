@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo    Windows 应用打包
echo ========================================
echo.

REM 定义输出文件名
set "OUTPUT_DIR=dist"
set "WIN_MAPS_NAME=GGD标记(含地图)"
set "WIN_LITE_ZIP=GGD标记.zip"
set "WIN_LITE_TEMP=GGD标记_temp"

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
echo    正在打包含地图版本...
echo ========================================
echo.

echo 清理构建缓存...
call flutter clean
echo.

echo 获取依赖...
call flutter pub get
echo.

echo 打包 Windows 应用 (含地图)...
call flutter build windows --release
if errorlevel 1 (
    echo ❌ Windows 含地图版本打包失败！
    pause
    goto :eof
)
if exist "!OUTPUT_DIR!\!WIN_MAPS_NAME!" rmdir /s /q "!OUTPUT_DIR!\!WIN_MAPS_NAME!"
xcopy "build\windows\x64\runner\Release\*" "!OUTPUT_DIR!\!WIN_MAPS_NAME!\" /E /I /Y >nul
echo √ Windows ^(含地图^) 打包完成
echo.
goto :eof

REM ========================================
REM    不含地图版本打包
REM ========================================
:build_without_maps
echo ========================================
echo    正在打包不含地图版本...
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

echo 打包 Windows 应用 (不含地图)...
call flutter build windows --release
if errorlevel 1 (
    echo ❌ Windows 不含地图版本打包失败！
    goto :restore_pubspec
)

REM 复制到临时目录后打包为 zip
if exist "!OUTPUT_DIR!\!WIN_LITE_TEMP!" rmdir /s /q "!OUTPUT_DIR!\!WIN_LITE_TEMP!"
xcopy "build\windows\x64\runner\Release\*" "!OUTPUT_DIR!\!WIN_LITE_TEMP!\" /E /I /Y >nul
if exist "!OUTPUT_DIR!\!WIN_LITE_ZIP!" del /F "!OUTPUT_DIR!\!WIN_LITE_ZIP!"
powershell -NoProfile -Command "Compress-Archive -Path 'dist\GGD标记_temp\*' -DestinationPath 'dist\GGD标记.zip' -Force"
rmdir /s /q "!OUTPUT_DIR!\!WIN_LITE_TEMP!"
echo √ Windows ^(不含地图^) 已打包为 !WIN_LITE_ZIP!
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
if exist "!OUTPUT_DIR!\!WIN_MAPS_NAME!\GGDPunctuation.exe" call :show_win_maps
if exist "!OUTPUT_DIR!\!WIN_LITE_ZIP!" call :show_win_no_maps
echo.
echo 提示：含地图版本需要将整个文件夹打包分发
echo.
pause
exit /b 0

:show_win_maps
echo 💻 Windows (含地图): !OUTPUT_DIR!\!WIN_MAPS_NAME!\
goto :eof

:show_win_no_maps
echo 💻 Windows (不含地图): !OUTPUT_DIR!\!WIN_LITE_ZIP!
for %%A in ("!OUTPUT_DIR!\!WIN_LITE_ZIP!") do echo    大小: %%~zA 字节
goto :eof
