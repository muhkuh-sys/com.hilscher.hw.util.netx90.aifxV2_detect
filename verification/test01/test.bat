echo off
REM Start openOCD. The openocd-0.10.0-dev.exe is used to support the gets-user interaction
set OPENOCD_BIN="..\comon\openocd-0.10.0-dev.exe"
set SCRIPT_PATH="..\comon"
set OPENOCD_ATTACH_COM=test01_netX90_test_aifxV2_detect_snippet.tcl


%OPENOCD_BIN% -f %OPENOCD_ATTACH_COM% -s %SCRIPT_PATH% -c shutdown
set script_return=%errorlevel%
echo "Script returned with %script_return%"
exit /b %script_return%