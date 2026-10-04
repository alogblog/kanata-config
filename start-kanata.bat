@echo off
REM 기존에 떠있는거 다 죽이기
taskkill /F /IM kanata_windows_gui_wintercept_cmd_allowed_x64.exe /T 2>nul
timeout /t 1 /nobreak >nul

REM 1. 한손키보드 담당 wintercept를 먼저 띄움 (가장 중요)
start "" /B "C:\kanata\kanata_windows_gui_wintercept_x64.exe" -c "C:\kanata\kanata1.kbd"

REM 2. 가상장치가 생길 때까지 3초 대기 - 리눅스의 ExecStartPre 역할
timeout /t 3 /nobreak >nul

REM 3. 이제 일반키보드 담당 winiov2 띄움 --> 다른 버전 kanata 실행이 문제가 많아서, 같은 버전 이용으로 변경.
start "" /B "C:\kanata\kanata_windows_gui_winIOv2_cmd_allowed_x64.exe" -c "C:\kanata\kanata2.kbd"