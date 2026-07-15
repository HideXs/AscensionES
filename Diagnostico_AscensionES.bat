@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
echo ============================================
echo  Diagnostico AscensionES - pega una captura
echo  de esta ventana en el Discord
echo ============================================
cd /d "%~dp0"
echo [1] Carpeta donde se ejecuta: %CD%
echo.
if exist "AscensionES\AscensionES.toc" (
    echo [2] AscensionES\AscensionES.toc : EXISTE
    for %%F in ("AscensionES\AscensionES.toc") do echo     tamano: %%~zF bytes ^| fecha: %%~tF
) else (
    echo [2] AscensionES\AscensionES.toc : *** NO EXISTE *** ese es el problema
)
echo.
echo [3] Primeras lineas del .toc:
if exist "AscensionES\AscensionES.toc" (
    for /f "usebackq delims=" %%L in (`findstr /n "^" "AscensionES\AscensionES.toc"`) do (
        set "line=%%L"
        for /f "delims=: tokens=1" %%N in ("%%L") do if %%N LEQ 6 echo     !line!
    )
)
echo.
echo [4] Contenido de la carpeta AscensionES:
dir "AscensionES" 2>nul | findstr /i "toc lua Core data sounds bytes archivos File"
echo.
echo [5] Numero de .lua en data:
dir /b "AscensionES\data\*.lua" 2>nul | find /c /v ""
echo.
echo [6] Ruta del juego detectada al lado (Ascension.exe):
if exist "..\..\Ascension.exe" (echo     OK: esta es la carpeta AddOns del juego) else (echo     *** OJO: aqui al lado no esta Ascension.exe - puede ser una copia/carpeta equivocada ***)
echo.
echo [7] Busqueda de copias/duplicados en AddOns:
set "dup=0"
for /d %%D in (*) do (
    if /i not "%%D"=="AscensionES" if exist "%%D\AscensionES.toc" (
        echo     *** DUPLICADO: la carpeta "%%D" contiene AscensionES.toc ***
        echo         El juego SOLO lee la carpeta llamada exactamente AscensionES.
        echo         Borra o renombra "%%D" y deja una unica carpeta AscensionES.
        set "dup=1"
    )
)
for /d %%D in (*scension*) do (
    if /i not "%%D"=="AscensionES" if not exist "%%D\AscensionES.toc" (
        echo     aviso: carpeta con nombre parecido a AscensionES: "%%D" ^(revisala^)
        set "dup=1"
    )
)
if "!dup!"=="0" echo     OK: sin duplicados ni copias
echo.
echo Listo. Haz captura de TODA esta ventana.
pause
