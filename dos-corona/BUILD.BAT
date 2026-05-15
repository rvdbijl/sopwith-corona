@ECHO OFF
REM Build Sopwith for the Corona/Cordata PPC-21.
REM Requires Microsoft C, MASM, LINK, and NMAKE in PATH.

IF "%1"=="CLEAN" GOTO CLEAN
IF "%1"=="clean" GOTO CLEAN
IF "%1"=="/CLEAN" GOTO CLEAN
IF "%1"=="/clean" GOTO CLEAN

ECHO.
ECHO Building Sopwith Corona PPC-21 DOS version...
ECHO.
ECHO Required tools: CL.EXE, MASM.EXE, LINK.EXE, NMAKE.EXE
ECHO See BUILDING.MD for PATH, INCLUDE, and LIB setup.
ECHO.

NMAKE /F SW.MAK
IF ERRORLEVEL 1 GOTO FAIL

IF EXIST SOPWITH.EXE GOTO OK
ECHO.
ECHO Build finished, but SOPWITH.EXE was not found.
GOTO FAIL

:OK
ECHO.
ECHO Build complete: SOPWITH.EXE
GOTO END

:CLEAN
ECHO.
ECHO Removing build products...
IF EXIST *.OBJ DEL *.OBJ
IF EXIST *.MAP DEL *.MAP
IF EXIST *.LST DEL *.LST
IF EXIST *.ERR DEL *.ERR
IF EXIST SOPWITH.EXE DEL SOPWITH.EXE
ECHO Clean complete.
GOTO END

:FAIL
ECHO.
ECHO Build failed.
ECHO Confirm Microsoft C, MASM, LINK, and NMAKE are installed and in PATH.
ECHO Also confirm INCLUDE and LIB point at the matching Microsoft C folders.

:END
