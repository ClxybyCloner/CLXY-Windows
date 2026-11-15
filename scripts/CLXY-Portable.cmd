@echo off
setlocal
set "ROOT=%~dp0"
set "DATA=%ROOT%user-data"
if not exist "%DATA%" mkdir "%DATA%"
start "" /D "%ROOT%" "%ROOT%clxy.exe" "--data-dir=%DATA%" %*
endlocal
