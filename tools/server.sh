#!/bin/bash
doBuildSystem() {
	echo "v2023-10-04"
}

HOSTNAME=$(hostname)
SELF=$(realpath $0)
SCRIPT=$(basename $SELF)
CWD=$(dirname $SELF)

cd $CWD

# Display introduction
doIntro() {
	echo
	echo "Minecraft Mods Managment: $HOSTNAME"
	doBuildSystem
	echo
}

# Show date/time header
doHeader() {
	NOW=`date +"%Y/%m/%d %H:%M:%S"`
	echo "- $NOW"
	echo ""
}

if [ "$(id -u)" != "0" ]; then
    doIntro
    doHeader
    echo "This script must be run as root !!!" 1>&2
    exit 1
fi

doIntro
doHeader

ProfileName=zogg
MinecraftVersion=Inconnue
ListVersion=https://github.com/kraoc/mods/raw/main/lists/version.txt
ListModrinth=https://github.com/kraoc/mods/raw/main/lists/server_modrinth.txt
ListCurseforge=https://github.com/kraoc/mods/raw/main/lists/server_curseforge.txt
FeriumApp=https://github.com/kraoc/mods/raw/main/tools/ferium

FabricFolder=/opt/docker/pterodactyl/mounts/fabric

# Script display header
function DisplayHeader() {
    clear
    doIntro
    doHeader
    echo "  - Version $MinecraftVersion"
}

# Delete already existing profile
function DeleteProfile() {
    echo "  * Delete Ferium profile: $ProfileName"
    ./tools/ferium profile delete --profile-name $ProfileName >/dev/null 2>&1
}

# Create profile
function CreateProfile() {
    echo "  * Create Ferium profile: $ProfileName"
    ./tools/ferium profile create --name $ProfileName --mod-loader fabric --output-dir $FabricFolder --game-version $MinecraftVersion >/dev/null 2>&1
    ./tools/ferium profile switch --profile-name $ProfileName >/dev/null 2>&1
    ./tools/ferium profile configure
}

# Download Remote File
function DownloadRemoteFile() {
    SRC=$1
    DST=$2
    echo "      - Download: $SRC to $DST"
    rm -f $DST >/dev/null 2>&1
    wget --header="Cache-Control: no-cache, no-store, max-age=0, must-revalidate" --header="Pragma: no-cache" --header="Expires: -1" --output-document=$DST --no-clobber --no-dns-cache --inet4-only --no-cache --no-cookies --no-check-certificate --recursive $SRC >/dev/null 2>&1
}

# Update Ferium
function UpdateFerium() {
    echo "  * Update Ferium"
    mkdir -p ./tools >/dev/null 2>&1
    cd ./tools/
        DownloadRemoteFile $FeriumApp ferium
    cd ..
    # Set execute permissions
    chmod +x ./tools/ferium >/dev/null 2>&1
}

# Update all versions and modules datas
function UpdateDatas() {
    echo "  * Update Datas"
    mkdir -p ./datas >/dev/null 2>&1
    cd ./datas/
        rm -f ./datas.zip >/dev/null 2>&1
        DownloadRemoteFile $ListVersion version.txt
        DownloadRemoteFile $ListModrinth modrinth.txt
        DownloadRemoteFile $ListCurseforge curseforge.txt
    cd ..
}

# Add specified module in profile
function InstallInProfile() {
    MOD=$1
    echo "      - Add to profile $ProfileName: $MOD"
    ./tools/ferium add --dependencies required $MOD
}

# Prepare modules for Zogg profile
function PrepareModules() {
    echo "  * Prepare modules"
    while read -r line
    do
        InstallInProfile $line
    done < ./datas/modrinth.txt
    while read -r line
    do
        InstallInProfile $line
    done < ./datas/curseforge.txt
}

# Download modules
function InstallModules() {
    echo "  * Install modules"
    ./tools/ferium upgrade
}

# Display modules
function DisplayModules() {
    echo "  * Display installed modules"
    ./tools/ferium list > ../mods.log
    ./tools/ferium list
}

DisplayHeader
UpdateFerium

DisplayHeader
UpdateDatas
MinecraftVersion=$(cat datas/version.txt)

DisplayHeader
./tools/ferium profile list >/dev/null 2>&1
RETURN=$?
if [ $RETURN -eq 1 ]; then
    CreateProfile
else
    DeleteProfile
    CreateProfile
fi

DisplayHeader
PrepareModules
sleep 10

DisplayHeader
InstallModules
sleep 10

DisplayHeader
DisplayModules

echo
echo "  * Fabric Mods Mount: $FabricFolder"
echo

sleep 30
exit 0
