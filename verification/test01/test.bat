REM set OPENOCD_BIN=openocd-0.10.0\bin\openocd.exe
set OPENOCD_BIN=openocd-0.10.0-dev.exe

set OPENOCD_ATTACH_COM=netX90_test_aifxV2_detect_snippet.tcl

REM read log data from netX 90
%OPENOCD_BIN% -f %OPENOCD_ATTACH_COM% 
REM ^
REM -c shutdown 
REM ARB
exit /b