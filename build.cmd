@echo off
rem The only way to build ohsRibbon, locally and in CI (docs\claude-workflow.md, section 5).
rem Builds the package, the tests and the demo for i386-win32 and x86_64-win64, and runs the tests.
rem Exit codes: 1 tests failed, 2 tools missing, 3 architecture rule broken, 4 build failed.
rem Tool paths can be set through RIBBON_LAZARUS_DIR and FRESNEL_DIR.
setlocal enabledelayedexpansion
cd /d "%~dp0"

if not defined RIBBON_LAZARUS_DIR set "RIBBON_LAZARUS_DIR=C:\lazarus"
if not defined FRESNEL_DIR set "FRESNEL_DIR=%USERPROFILE%\Documents\development\lazarus_libraries\fresnel"
set "LAZBUILD=%RIBBON_LAZARUS_DIR%\lazarus\lazbuild.exe"
set "LAZCONFIG=%RIBBON_LAZARUS_DIR%\config_lazarus"

if not exist "%LAZBUILD%" (
  echo lazbuild not found: %LAZBUILD%
  set "RC=2"
  goto :fail
)
if not exist "%FRESNEL_DIR%\src\fresnel.lpk" (
  echo Fresnel not found: %FRESNEL_DIR%
  set "RC=2"
  goto :fail
)

if not exist out mkdir out
set "LOG=%CD%\out\build.log"
set "TESTLOG=%CD%\out\tests.log"
if exist "%LOG%" del "%LOG%"
if exist "%TESTLOG%" del "%TESTLOG%"

rem Architecture rule (RB-NFR-101): src\model stays free of UI units.
findstr /i /r /c:"Fresnel\." /c:"[ ,]Forms[ ,;]" /c:"[ ,]Controls[ ,;]" /c:"[ ,]Graphics[ ,;]" /c:"[ ,]LCL" src\model\*.pas >nul
if not errorlevel 1 (
  echo Architecture rule broken: src\model uses a UI unit.
  set "RC=3"
  goto :fail
)
rem src\ uses no LCL units directly.
findstr /i /r /c:"[ ,]Interfaces[ ,;]" /c:"[ ,]Forms[ ,;]" /c:"[ ,]LCLType" /c:"[ ,]LCLIntf" src\*.pas >nul
if not errorlevel 1 (
  echo Architecture rule broken: src uses an LCL unit.
  set "RC=3"
  goto :fail
)

for %%T in (i386-win32 x86_64-win64) do (
  for /f "tokens=1,2 delims=-" %%A in ("%%T") do (
    set "CPU=%%A"
    set "OS=%%B"
  )
  set "SKIADIR=Win32"
  if "!CPU!"=="x86_64" set "SKIADIR=Win64"

  echo === %%T
  for %%P in (src\ohsribbon.lpk test\ohsribbontests.lpi demo\ribbondemo.lpi) do (
    "%LAZBUILD%" --pcp="%LAZCONFIG%" --cpu=!CPU! --os=!OS! "%%P" >>"%LOG%" 2>&1
    if errorlevel 1 (
      echo Build failed: %%P for %%T, see out\build.log
      set "RC=4"
      goto :fail
    )
  )

  copy /y "%FRESNEL_DIR%\bin\Binary\Shared\!SKIADIR!\sk4d.dll" "out\%%T\" >nul
  xcopy /y /q demo\icons\*.png "out\%%T\icons\" >nul

  echo === %%T >>"%TESTLOG%"
  rem The Fresnel test harness registers its own tests too, so run the ribbon suites by name.
  for %%S in (TTestSizing TTestKeyTips TTestRibbon) do (
    "out\%%T\ohsribbontests.exe" --suite=%%S --format=plain >>"%TESTLOG%" 2>&1
    if errorlevel 1 (
      echo Tests failed for %%T in %%S, see out\tests.log
      set "RC=1"
      goto :fail
    )
  )
)

echo BUILD OK, TESTS PASSED
exit /b 0

rem One exit point: an exit /b inside the loops above loses its exit code.
:fail
exit /b %RC%
