REM Start openOCD. The openocd-0.10.0-dev.exe is used to support the gets-user interaction
set OPENOCD_BIN=openocd-0.10.0-dev.exe

set OPENOCD_ATTACH_COM=netX90_test_aifxV2_detect_snippet.tcl


%OPENOCD_BIN% -f %OPENOCD_ATTACH_COM% -c shutdown 
exit /b