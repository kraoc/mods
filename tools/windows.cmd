@echo off
chcp 65001
cls

REM 2023-02-22

MinecraftVersion=Inconnue
ListVersion=https://github.com/kraoc/mods/raw/main/lists/version.txt
ListModrinth=https://github.com/kraoc/mods/raw/main/lists/client_modrinth.txt
ListCurseforge=https://github.com/kraoc/mods/raw/main/lists/client_curseforge.txt
FeriumApp=https://github.com/kraoc/mods/raw/main/tools/ferium.exe

call :DisplayHeader
echo   - Mise à jour de Ferium
call :UpdateFerium

call :DisplayHeader
echo   - Mise à jour des informations
call :UpdateDatas
set /p MinecraftVersion=<datas\version.txt

call :DisplayHeader
tools\ferium profile list > nul 2>&1
if errorlevel 1 (
    echo   - Suppression du profile Zogg
    call :CreateProfile
) else (
    echo   - Recréation du profile Zogg
    call :DeleteProfile
    call :CreateProfile
)

call :DisplayHeader
echo   - Préparation des modules
call :PrepareModules

call :DisplayHeader
echo   - Installation, ou mise à jour, des modules
call :InstallModules

call :DisplayHeader
echo   - Resumé des modules installés
call :DisplayModules

timeout /t 30

exit 0


REM --------------------------------------------------
REM Functions
REM --------------------------------------------------

REM Script display header
:DisplayHeader
    cls
    echo [Minecraft Zogg]
    echo   - Version %MinecraftVersion%
exit /b 0

REM Delete already existing profile
:DeleteProfile
	rem del "$env:APPDATA\.minecraft\mods\*.jar"
	del "%APPDATA%\.minecraft\mods\*.jar" > nul 2>&1
    tools\ferium profile delete --profile-name zogg > nul 2>&1
exit /b 0

REM Create profile
:CreateProfile
    tools\ferium profile create --name zogg --mod-loader fabric --game-version %MinecraftVersion% > nul 2>&1
    tools\ferium profile switch --profile-name zogg > nul 2>&1
exit /b 0

REM Update Ferium
:UpdateFerium
    mkdir tools > nul 2>&1
    cd tools\
        del ferium.exe > nul 2>&1
	powershell.exe -ExecutionPolicy Unrestricted -WindowStyle Maximized -Command "wget -Headers @{'Cache-Control'='no-cache'} $FeriumApp -o ferium.exe"
    cd ..
exit /b 0

REM Update all versions and modules datas
:UpdateDatas
    mkdir datas > nul 2>&1
    cd datas\
        del datas.zip > nul 2>&1
	powershell.exe -ExecutionPolicy Unrestricted -WindowStyle Maximized -Command "wget -Headers @{'Cache-Control'='no-cache'} $ListVersion -o version.txt"
	powershell.exe -ExecutionPolicy Unrestricted -WindowStyle Maximized -Command "wget -Headers @{'Cache-Control'='no-cache'} $ListModrinth -o modrinth.txt"
	powershell.exe -ExecutionPolicy Unrestricted -WindowStyle Maximized -Command "wget -Headers @{'Cache-Control'='no-cache'} $ListCurseforge -o curseforge.txt"
    cd ..
exit /b 0

REM Prepare modules for Zogg profile
:PrepareModules
    for /f %%G in (datas\modrinth.txt) do call :InstallInProfile %%G
    for /f %%G in (datas\curseforge.txt) do call :InstallInProfile %%G
exit /b 0

REM Add specified module in profile
:InstallInProfile
    tools\ferium add --dependencies required %~1
exit /b 0

REM Download modules
:InstallModules
    tools\ferium upgrade
exit /b 0

REM Display modules
:DisplayModules
    tools\ferium list > ..\mods.log
    tools\ferium list
exit /b 0
