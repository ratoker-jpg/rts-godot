@echo off
setlocal

cd /d "%~dp0"

echo.
echo ==================================================
echo  PULL: GitHub to local folder
echo ==================================================
echo Folder: %cd%
echo.

where git >nul 2>&1
if errorlevel 1 (
    echo ERROR: Git is not installed or not available in PATH.
    pause
    exit /b 1
)

git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo ERROR: This folder is not a Git repository.
    echo Put this BAT file into the root folder of the Godot project.
    pause
    exit /b 1
)

git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo ERROR: Git remote "origin" is not configured.
    echo Run once:
    echo git remote add origin https://github.com/ratoker-jpg/rts-godot.git
    pause
    exit /b 1
)

echo Current status:
git status --short
echo.

echo Pulling latest changes from GitHub...
git pull --rebase --autostash
if errorlevel 1 (
    echo.
    echo ERROR: pull/rebase failed. Possible conflict.
    echo Recommended:
    echo 1. Close Godot.
    echo 2. Open the project in VS Code.
    echo 3. Resolve conflicts.
    echo 4. Run: git rebase --continue
    pause
    exit /b 1
)

echo.
echo ==================================================
echo  DONE: local folder updated from GitHub
echo ==================================================
echo.
git status
pause
