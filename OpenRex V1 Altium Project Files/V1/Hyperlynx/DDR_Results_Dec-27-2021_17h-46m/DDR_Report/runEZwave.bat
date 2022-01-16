@echo off
set HYP_HOME=C:\MentorGraphics\HLVX.2.5\SDD_HOME\hyperlynx64
if EXIST %HYP_HOME%\Ams goto InstallDirFound

REM Get path from Registry
set KEYNAME=HKEY_CLASSES_ROOT\ffsfile\shell\open\command
REM Check for presence of key first.
reg query %KEYNAME% 2>nul || (echo HyperLynx is not installed! & exit /b 1)
for /f "tokens=3" %%a in ('reg query %KEYNAME% 2^>nul') do (
    set HYP_HOME=%%a
)
REM Remove bsw.exe
for /f %%i IN ("%HYP_HOME%") do (
	set HYP_HOME=%%~dpi
)

:InstallDirFound
echo HYP_HOME: %HYP_HOME%

REM .tcl script expected to be next to the batch file
set "SCRIPT_DIR=%~dp0"
cd "%SCRIPT_DIR%\.."
set "RESULTS_DIR=%CD%"
set "RESULTS_DIR=%RESULTS_DIR:\=/%"
set RESULTS_DIR

if [%1]==[] goto noArgs

set DataRate=%1
set TableType=%2

if %3=="" goto noThresholds
set Thresholds=%3
:noThresholds

set Time=%4

set WFfile1="%RESULTS_DIR%/%~5"
set WFname1=%6

if [%7]==[] goto noMoreWF
set WFfile2="%RESULTS_DIR%/%~7"
set WFname2=%8
shift
shift

if [%7]==[] goto noMoreWF
set WFfile3="%RESULTS_DIR%/%~7"
set WFname3=%8
shift
shift

if [%7]==[] goto noMoreWF
set WFfile4="%RESULTS_DIR%/%~7"
set WFname4=%8
:noMoreWF

:noArgs

REM install might be on a different drive
%HYP_HOME:~0,2%

REM support future releases
cd %HYP_HOME%\Ams\pkgs\icx_pro_sim\1*
set AMS_DIR=%CD%
call .\bin\ams_setup.bat %AMS_DIR%

cd %SCRIPT_DIR%

set TCL_SCRIPT="%SCRIPT_DIR%\showDDRwfs.tcl"
if [%1]==[] set TCL_SCRIPT="%SCRIPT_DIR%\saveDDRimgs.tcl"

REM "" needed to support spaces in path
%AMS_DIR%\ixn\bin\ezwave.bat -dofile ""%TCL_SCRIPT%""
