#!/bin/bash
clear

# 2023-03-02

MinecraftVersion=Inconnue
ListVersion=https://github.com/kraoc/mods/raw/main/lists/version.txt
ListModrinth=https://github.com/kraoc/mods/raw/main/lists/server_modrinth.txt
ListCurseforge=https://github.com/kraoc/mods/raw/main/lists/server_curseforge.txt
FeriumApp=https://github.com/kraoc/mods/raw/main/tools/ferium

FabricFolder=/opt/docker/pterodactyl/mounts/fabric

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
    tools/ferium profile create --name zogg --mod-loader fabric --output-dir $FabricFolder --game-version $MinecraftVersion >/dev/null 2>&1
    tools/ferium profile switch --profile-name zogg >/dev/null 2>&1
    tools/ferium profile configure
}

# Download Remote File
function DownloadRemoteFile() {
    rm -f $2 >/dev/null 2>&1
    wget --header="Cache-Control: no-cache, no-store, max-age=0, must-revalidate" --header="Pragma: no-cache" --header="Expires: -1" --output-document=$2 --no-clobber --no-dns-cache --inet4-only --no-cache --no-cookies --no-check-certificate --recursive $1 >/dev/null 2>&1
}

# Update Ferium
function UpdateFerium() {
    mkdir -p tools >/dev/null 2>&1
    cd tools/
        #rm -f ferium >/dev/null 2>&1
        #wget --header="Cache-Control: no-cache, no-store, max-age=0, must-revalidate" --header="Pragma: no-cache" --header="Expires: -1" --output-document=ferium --no-clobber --no-dns-cache --inet4-only --no-cache --no-cookies --no-check-certificate --recursive $FeriumApp >/dev/null 2>&1
        DownloadRemoteFile $FeriumApp ferium
    cd ..
}

# Update all versions and modules datas
function UpdateDatas() {
    mkdir -p datas >/dev/null 2>&1
    cd datas/
        rm -f datas.zip >/dev/null 2>&1
        #rm -f version.txt >/dev/null 2>&1
        #rm -f modrinth.txt >/dev/null 2>&1
        #rm -f curseforge.txt >/dev/null 2>&1
        #wget --header="Cache-Control: no-cache, no-store, max-age=0, must-revalidate" --header="Pragma: no-cache" --header="Expires: -1" --output-document=version.txt --no-clobber --no-dns-cache --inet4-only --no-cache --no-cookies --no-check-certificate --recursive $ListVersion >/dev/null 2>&1
        #wget --header="Cache-Control: no-cache, no-store, max-age=0, must-revalidate" --header="Pragma: no-cache" --header="Expires: -1" --output-document=modrinth.txt --no-clobber --no-dns-cache --inet4-only --no-cache --no-cookies --no-check-certificate --recursive $ListModrinth >/dev/null 2>&1
        #wget --header="Cache-Control: no-cache, no-store, max-age=0, must-revalidate" --header="Pragma: no-cache" --header="Expires: -1" --output-document=curseforge.txt --no-clobber --no-dns-cache --inet4-only --no-cache --no-cookies --no-check-certificate --recursive $ListCurseforge >/dev/null 2>&1
        DownloadRemoteFile $ListVersion version.txt
        DownloadRemoteFile $ListModrinth modrinth.txt
        DownloadRemoteFile $ListCurseforge curseforge.txt
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
echo   - Mise ?? jour de Ferium
echo
UpdateFerium

# Set execute permissions
chmod +x tools/ferium >/dev/null 2>&1

DisplayHeader
echo   - Mise ?? jour des informations
echo
UpdateDatas
MinecraftVersion=$(cat datas/version.txt)

DisplayHeader
tools/ferium profile list >/dev/null 2>&1
RETURN=$?
if [ $RETURN -eq 1 ]; then
    echo   - Cr??ation du profile Zogg
    CreateProfile
else
    echo   - Recr??ation du profile Zogg
    DeleteProfile
    CreateProfile
fi

DisplayHeader
echo   - Pr??paration des modules
echo
PrepareModules

DisplayHeader
echo   - Installation, ou mise ?? jour, des modules
echo
InstallModules

DisplayHeader
echo   - Resum?? des modules install??s
echo
DisplayModules

echo
echo   - Fabric Mods Mount: $FabricFolder
echo

sleep 30
exit 0
