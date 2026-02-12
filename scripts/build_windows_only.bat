@echo off
chcp 65001 >nul
echo ========================================
echo    Windows 应用打包
echo ========================================
echo.

echo [1/3] 清理构建缓存...
call flutter clean
echo.

echo [2/3] 获取依赖...
call flutter pub get
echo.

echo [3/3] 打包 Windows 应用...
call flutter build windows --release
if %errorlevel% neq 0 (
    echo ❌ Windows 打包失败！
    pause
    exit /b %errorlevel%
)

echo.
echo ========================================
echo    打包成功！
echo ========================================
echo.
echo 💻 Windows EXE: build\windows\x64\runner\Release\GGDPunctuation.exe
echo.
echo 提示：需要将整个 Release 文件夹打包分发
echo 文件夹位置: build\windows\x64\runner\Release\
echo.
pause
