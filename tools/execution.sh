#!/bin/bash
clear

# 2023-02-22

MinecraftVersion=Inconnue
ListVersion=https://github.com/kraoc/mods/raw/main/lists/version.txt
ListModrinth=https://github.com/kraoc/mods/raw/main/lists/client_modrinth.txt
ListCurseforge=https://github.com/kraoc/mods/raw/main/lists/client_curseforge.txt
FeriumApp=https://github.com/kraoc/mods/raw/main/tools/ferium

# Script display header
function DisplayHeader() {
    clear
    echo [Minecraft Zogg]
    echo   - Version $MinecraftVersion
}

# Delete already existing profile
function DeleteProfile() {
    tools/ferium profile delete --profile-name zogg >/dev/null 2>&1
}

# Create profile
function CreateProfile() {
    tools/ferium profile create --name zogg --mod-loader fabric --game-version $MinecraftVersion >/dev/null 2>&1
    tools/ferium profile switch --profile-name zogg >/dev/null 2>&1
}

# Update Ferium
function UpdateFerium() {
    mkdir -p tools >/dev/null 2>&1
    cd tools/
        rm -f ferium >/dev/null 2>&1
        wget --output-document=ferium --no-clobber --no-dns-cache --inet4-only --no-cache --no-cookies --no-check-certificate --recursive $FeriumApp >/dev/null 2>&1
    cd ..
}

# Update all versions and modules datas
function UpdateDatas() {
    mkdir -p datas >/dev/null 2>&1
    cd datas/
        rm -f datas.zip >/dev/null 2>&1
        wget --output-document=version.txt --no-clobber --no-dns-cache --inet4-only --no-cache --no-cookies --no-check-certificate --recursive $ListVersion >/dev/null 2>&1
        wget --output-document=modrinth.txt --no-clobber --no-dns-cache --inet4-only --no-cache --no-cookies --no-check-certificate --recursive $ListModrinth >/dev/null 2>&1
        wget --output-document=curseforge.txt --no-clobber --no-dns-cache --inet4-only --no-cache --no-cookies --no-check-certificate --recursive $ListCurseforge >/dev/null 2>&1
    cd ..
}

# Prepare modules for Zogg profile
function PrepareModules() {
    while read -r line
        do
          InstallInProfile $line
        done < datas/modrinth.txt
    while read -r line
        do
          InstallInProfile $line
        done < datas/curseforge.txt
}

# Add specified module in profile
function InstallInProfile() {
    tools/ferium add --dependencies required $1
}

# Download modules
function InstallModules() {
    tools/ferium upgrade
}

# Display modules
function DisplayModules() {
    tools/ferium list > ../mods.log
    tools/ferium list
}

DisplayHeader
echo   - Mise à jour de Ferium
UpdateFerium

# Set execute permissions
chmod +x tools/ferium >/dev/null 2>&1

DisplayHeader
echo   - Mise à jour des informations
UpdateDatas
MinecraftVersion=$(cat datas/version.txt)

DisplayHeader
tools/ferium profile list >/dev/null 2>&1
RETURN=$?
if [ $RETURN -eq 0 ]; then
    echo   - Suppression du profile Zogg
    CreateProfile
else
    echo   - Recréation du profile Zogg
    DeleteProfile
    CreateProfile
fi

DisplayHeader
echo   - Préparation des modules
PrepareModules

DisplayHeader
echo   - Installation, ou mise à jour, des modules
InstallModules

DisplayHeader
echo   - Resumé des modules installés
DisplayModules

sleep 30
exit 0
