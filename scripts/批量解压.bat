@echo off
chcp 65001 > nul

set "zip=C:\Program Files\7-Zip\7z.exe"
set /p delete="解压后删除原文件? (Y/N): "

for /r %%f in (*.rar *.zip *.7z) do (
    "%zip%" x "%%f" -o"%%~nf" -y > nul 
    if not errorlevel 1 (
        set /p="%%~nf ...... 解压成功" < nul
        if /i "%delete%"=="Y" del "%%f" && set /p="，原文件已删除" < nul
        echo;
    ) else (
        echo "%%~nf ...... 解压失败"
    )
)

pause