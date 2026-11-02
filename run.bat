@echo off
setlocal

cd /d "%~dp0"

echo [1/3] Initializing MSVC environment...

set "PATH=C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem"
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"

if not exist "%VSWHERE%" (
    echo vswhere.exe not found!
    exit /b 1
)

for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -property installationPath`) do (
    set "VS_PATH=%%i"
)

if not defined VS_PATH (
    echo Visual Studio installation not found!
    exit /b 1
)

set "VCVARS=%VS_PATH%\VC\Auxiliary\Build\vcvars32.bat"

if not exist "%VCVARS%" (
    echo vcvars32.bat not found!
    exit /b 1
)

echo Using Visual Studio: %VS_PATH%

call "%VCVARS%"
if errorlevel 1 (
    echo Failed to initialize MSVC environment
    exit /b 1
)

echo.
echo [2/3] Compiling MASM...

ml /nologo /c /coff comp.asm

if errorlevel 1 (
    echo MASM compilation failed
    exit /b 1
)

echo.
echo [3/3] Compiling C++ and linking...

cl /nologo /EHsc main.cpp comp.obj /Fe:main.exe

if errorlevel 1 (
    echo C++ compilation or linking failed
    exit /b 1
)

echo.
echo Build successful!

exit /b 0