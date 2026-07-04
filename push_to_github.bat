@echo off
setlocal

cd /d "%~dp0"

echo.
echo ==================================================
echo  PUSH: local folder to GitHub
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

git diff --quiet --exit-code
set HAS_UNSTAGED=%errorlevel%

git diff --cached --quiet --exit-code
set HAS_STAGED=%errorlevel%

if "%HAS_UNSTAGED%"=="0" if "%HAS_STAGED%"=="0" (
    echo No local changes. Nothing to commit.
    echo.
    git status
    pause
    exit /b 0
)

set /p COMMIT_MSG=Commit message [Local progress]: 
if "%COMMIT_MSG%"=="" set "COMMIT_MSG=Local progress"

echo.
echo Adding files...
git add -A
if errorlevel 1 (
    echo ERROR: git add failed.
    pause
    exit /b 1
)

echo.
echo Creating commit...
git commit -m "%COMMIT_MSG%"
if errorlevel 1 (
    echo ERROR: git commit failed.
    pause
    exit /b 1
)

echo.
echo Pulling latest changes from GitHub before push...
git pull --rebase --autostash
if errorlevel 1 (
    echo.
    echo ERROR: pull/rebase failed. Possible conflict.
    echo Close Godot, resolve conflicts, then run:
    echo git rebase --continue
    pause
    exit /b 1
)

echo.
echo Pushing to GitHub...
git push
if errorlevel 1 (
    echo.
    echo ERROR: git push failed.
    echo Check GitHub login, token, network, or repository rights.
    pause
    exit /b 1
)

echo.
echo ==================================================
echo  DONE: local changes pushed to GitHub
echo ==================================================
echo.
git status
pause
