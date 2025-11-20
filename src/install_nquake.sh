#!/bin/bash

# ================================================================================
# nQuake Installer for macOS (Intel & Apple Silicon)
# ================================================================================
# Version: 2.4.0
# Author: x86DX2 - nelson.junior@x86.com.br
# Description: Automated installer for nQuake - The ultimate QuakeWorld experience
#
# Features:
#   ✓ Full compatibility with Intel and Apple Silicon Macs (M1/M2/M3/M4)
#   ✓ Automatic dependency checking and installation guidance
#   ✓ Smart pak1.pak detection from original Quake installation
#   ✓ Visual progress bars for all downloads
#   ✓ Automatic ezQuake macOS binary download from official releases
#   ✓ Support for addons: Clan Arena, Team Fortress, HD Textures
#   ✓ Proxy server support for restricted networks
#   ✓ Colorized output for better user experience
#
# Requirements: curl, unzip (automatically checked)
# ================================================================================

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Check if required tools are installed
curl_bin=$(which curl)
if [ "$curl_bin" = "" ]
then
	echo -e "${RED}✗ Error:${NC} curl is not installed."
	echo -e "${YELLOW}Please install curl and run the nQuake installation again.${NC}"
	echo -e "${CYAN}Tip: Install via Homebrew with: ${BOLD}brew install curl${NC}"
	exit 1
fi

unzip_bin=$(which unzip)
if [ "$unzip_bin" = "" ]
then
	echo -e "${RED}✗ Error:${NC} unzip is not installed."
	echo -e "${YELLOW}Please install unzip and run the nQuake installation again.${NC}"
	echo -e "${CYAN}Tip: Install via Homebrew with: ${BOLD}brew install unzip${NC}"
	exit 1
fi

# Get the directory where the script is located (before any cd commands)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Download function with progress and timeout
error=false
function distdl {
	echo -ne "${CYAN}→${NC} Downloading ${BOLD}$2${NC}...\n"
	curl -L --progress-bar --connect-timeout 30 --max-time 300 -o "$2" "$1/$2" 2>&1 | tr '\r' '\n' | tail -1
	if [ -s "$2" ]
	then
		if [ "$(du "$2" | cut -f1)" -gt 0 ]
		then
			error=false
			echo -e "${GREEN}✓ Download complete${NC}"
		else
			error=true
			echo -e "${RED}✗ Failed (empty file)${NC}"
		fi
	else
		error=true
		echo -e "${RED}✗ Failed (download error)${NC}"
	fi
}

echo
echo -e "${BOLD}${MAGENTA}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${MAGENTA}║                                                          ║${NC}"
echo -e "${BOLD}${MAGENTA}║                ${WHITE}nQuake Installer for macOS${MAGENTA}                ║${NC}"
echo -e "${BOLD}${MAGENTA}║                      ${CYAN}Version 2.4.0${MAGENTA}                       ║${NC}"
echo -e "${BOLD}${MAGENTA}║                                                          ║${NC}"
echo -e "${BOLD}${MAGENTA}╚══════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${YELLOW}Press ENTER to use ${BOLD}[default]${NC}${YELLOW} option.${NC}"
echo

# Create the nQuake folder
echo -e "${BOLD}${BLUE}═══ Installation Directory ═══${NC}"
defaultdir="~/Applications/nQuake"
read -p "Where do you want to install nQuake? [$defaultdir]: " directory
eval directory=$directory
if [ "$directory" = "" ]
then
	directory=$defaultdir
fi
eval directory=$directory
if [ -d "$directory" ]
then
	if [ -w "$directory" ]
	then
		created=false
	else
		echo
		echo -e "${RED}✗ Error:${NC} You do not have write access to ${BOLD}$directory${NC}. Exiting."
		exit 1
	fi
else
	if [ -e "$directory" ]
	then
		echo
		echo -e "${RED}✗ Error:${NC} ${BOLD}$directory${NC} already exists and is a file, not a directory. Exiting."
		exit 1
	else
		mkdir -p "$directory" 2> /dev/null
		created=true
	fi
fi
if [ -d "$directory" ] && [ -w "$directory" ]
then
	cd "$directory"
	directory=$(pwd)
	echo -e "${GREEN}✓${NC} Installation directory: ${BOLD}$directory${NC}"
else
	echo
	echo -e "${RED}✗ Error:${NC} You do not have write access to ${BOLD}$directory${NC}. Exiting."
	exit 1
fi
echo

# Ask for addons
echo -e "${BOLD}${BLUE}═══ Optional Addons ═══${NC}"
read -p "Do you want to install the Clan Arena addon? (y/n) [n]: " clanarena
read -p "Do you want to install the Team Fortress addon? (y/n) [n]: " fortress
read -p "Do you want to install the High Resolution Textures addon? (y/n) [n]: " textures
echo

# Search for pak1.pak
echo -e "${BOLD}${BLUE}═══ Full Game Files ═══${NC}"
echo -e "${YELLOW}Note:${NC} pak1.pak is required for the full Quake experience."
# defaultsearchdir="~/"
defaultsearchdir="$SCRIPT_DIR"
pak=""
read -p "Do you want setup to search for pak1.pak? (y/n) [n]: " search
if [ "$search" = "y" ]
then
	read -p "Enter path to search for pak1.pak [$defaultsearchdir]: " path
	if [ "$path" = "" ]
	then
		path=$defaultsearchdir
	fi
	eval path=$path
	echo -e "${CYAN}→${NC} Searching for pak1.pak in ${BOLD}$path${NC}..."
	pak=$(echo $(find "$path" -type f -iname "pak1.pak" -size +30M -size -35M -exec echo {} \; 2> /dev/null) | cut -d " " -f1)
	if [ "$pak" != "" ]
	then
		echo -e "${GREEN}✓ Found pak1.pak:${NC} $pak"
	else
		echo -e "${YELLOW}⚠ Could not find pak1.pak${NC}"
		echo -e "${CYAN}Tip:${NC} You can add it later to the ${BOLD}id1${NC} folder."
	fi
fi
echo

# Setup proxy server
read -p "Do you want to use a proxy server? (y/n) [n]: " useproxy
if [ "$useproxy" = "y" ]
then
	read -p "Enter <IP>:<port> to the proxy server: " ip
	if [ "$ip" = "" ]
	then
		echo
		echo "* Proxy settings cancelled."
	else
		read -p "Enter <username>[:<password>] to use for proxy server [off]: " userpass
		if [ "$userpass" = "" ]
		then
			proxy="-x $ip"
		else
			proxy="-x $ip -u $userpass"
		fi
	fi
fi
echo

# Download nquake.ini
echo -ne "${CYAN}→${NC} Downloading mirror list... "
curl $proxy -s -L --connect-timeout 30 --max-time 60 -o nquake.ini https://raw.githubusercontent.com/nQuake/client-win32/master/etc/nquake.ini
if [ -s "nquake.ini" ]
then
	echo -e "${GREEN}✓ done${NC}"
else
	echo -e "\n${BOLD}${RED}═══ Installation Failed ═══${NC}"
	echo -e "${RED}✗ Error:${NC} Could not download nquake.ini. Better luck next time. Exiting."
	if [ "$created" = true ]
	then
		cd
		echo
		read -p "The directory $directory is about to be removed, press Enter to confirm or CTRL+C to exit." remove
		rm -rf "$directory"
	fi
	exit
fi

# List all the available mirrors
echo -e "${BOLD}${BLUE}═══ Download Location ═══${NC}"
echo "From what mirror would you like to download nQuake?"
grep "[0-9]\{1,2\}=\".*" nquake.ini | cut -d "\"" -f2 | nl
read -p "Enter mirror number [random]: " mirror
mirror=$(grep "^$mirror=\(http\|https\|ftp\)://[^ ]*$" nquake.ini | cut -d "=" -f2)
if [ "$mirror" = "" ]
then
	echo
	echo -ne "${CYAN}→${NC} Using random mirror: ${BOLD}"
	RANGE=$(expr $(grep "[0-9]\{1,2\}=\".*" nquake.ini | cut -d "\"" -f2 | nl | tail -n1 | cut -f1) + 1)
	while [ "$mirror" = "" ]
	do
		number=$RANDOM
		let "number %= $RANGE"
		mirror=$(grep "^$number=\(http\|https\|ftp\)://[^ ]*$" nquake.ini | cut -d "=" -f2)
		mirrorname=$(grep "^$number=\".*" nquake.ini | cut -d "\"" -f2)
	done
	echo -e "$mirrorname${NC}"
fi
mkdir -p id1
echo

# Download all the packages
echo -e "${BOLD}${BLUE}═══ Downloading Packages ═══${NC}"
distdl $mirror qsw106.zip
if [ "$error" = false ]
then
	distdl $mirror gpl.zip
fi
if [ "$error" = false ]
then
	distdl $mirror non-gpl.zip
fi
if [ "$error" = false ]
then
	distdl https://github.com/QW-Group/ezquake-source/releases/latest/download ezQuake-macOS-universal.zip
fi
if [ "$error" = false ]
then
	if [ "$clanarena" = "y" ]
	then
		distdl $mirror addon-clanarena.zip
	fi
fi
if [ "$error" = false ]
then
	if [ "$fortress" = "y" ]
	then
		distdl $mirror addon-fortress.zip
	fi
fi
if [ "$error" = false ]
then
	if [ "$textures" = "y" ]
	then
		distdl $mirror addon-textures.zip
	fi
fi

# Terminate installation if not all packages were downloaded
if [ "$error" = true ]
then
	echo -e "\n${BOLD}${RED}═══ Installation Failed ═══${NC}"
	echo -e "${RED}✗${NC} Some distribution files failed to download. Better luck next time. Exiting."
	rm -rf "$directory/qsw106.zip" "$directory/gpl.zip" "$directory/non-gpl.zip" "$directory/ezQuake-macOS-universal.zip" "$directory/addon-clanarena.zip" "$directory/addon-fortress.zip" "$directory/addon-textures.zip" "$directory/nquake.ini"
	if [ "$created" = true ]
	then
		cd
		echo
		read -p "The directory $directory is about to be removed, press Enter to confirm or CTRL+C to exit." remove
		rm -rf "$directory"
	fi
	exit
fi

# Extract all the packages
echo -e "\n${BOLD}${BLUE}═══ Installing Files ═══${NC}"
echo -ne "${CYAN}→${NC} Extracting Quake v1.06 Shareware..."
unzip -qqo qsw106.zip ID1/PAK0.PAK 2> /dev/null
echo -e " ${GREEN}✓${NC}"
echo -ne "${CYAN}→${NC} Extracting nQuake setup files (1 of 2)..."
unzip -qqo gpl.zip 2> /dev/null
echo -e " ${GREEN}✓${NC}"
echo -ne "${CYAN}→${NC} Extracting nQuake setup files (2 of 2)..."
unzip -qqo non-gpl.zip 2> /dev/null
echo -e " ${GREEN}✓${NC}"
echo -ne "${CYAN}→${NC} Extracting nQuake macOS files..."
unzip -qqo ezQuake-macOS-universal.zip 2> /dev/null
echo -e " ${GREEN}✓${NC}"
if [ "$clanarena" = "y" ]
then
	echo -ne "${CYAN}→${NC} Extracting Clan Arena addon..."
	unzip -qqo addon-clanarena.zip 2> /dev/null
	echo -e " ${GREEN}✓${NC}"
fi
if [ "$fortress" = "y" ]
then
	echo -ne "${CYAN}→${NC} Extracting Team Fortress addon..."
	unzip -qqo addon-fortress.zip 2> /dev/null
	echo -e " ${GREEN}✓${NC}"
fi
if [ "$textures" = "y" ]
then
	echo -ne "${CYAN}→${NC} Extracting High Resolution Textures addon..."
	unzip -qqo addon-textures.zip 2> /dev/null
	echo -e " ${GREEN}✓${NC}"
fi
if [ "$pak" != "" ]
then
	echo -ne "${CYAN}→${NC} Copying pak1.pak..."
	cp "$pak" "$directory/id1/pak1.pak" 2> /dev/null
	rm -rf "$directory/id1/gpl_maps.pk3" "$directory/id1/readme.txt"
	echo -e " ${GREEN}✓${NC}"
fi

# Cleanup
echo -e "\n${BOLD}${BLUE}═══ Cleaning Up ═══${NC}"
# Rename files
echo -ne "${CYAN}→${NC} Renaming files..."
mv "$directory/id1/PAK0.PAK" "$directory/id1/pak0.pak" 2> /dev/null
echo -e " ${GREEN}✓${NC}"

# Remove the Windows specific files
echo -ne "${CYAN}→${NC} Removing Windows specific binaries..."
rm -rf "$directory/ezquake.exe"
echo -e " ${GREEN}✓${NC}"

# Remove distribution files
echo -ne "${CYAN}→${NC} Removing distribution files..."
rm -rf "$directory/qsw106.zip" "$directory/gpl.zip" "$directory/non-gpl.zip" "$directory/ezQuake-macOS-universal.zip" "$directory/addon-clanarena.zip" "$directory/addon-fortress.zip" "$directory/addon-textures.zip" "$directory/nquake.ini"
echo -e " ${GREEN}✓${NC}"

# Convert DOS files to UNIX
echo -ne "${CYAN}→${NC} Converting DOS files to UNIX..."
# Check if 'file' command exists
if command -v file >/dev/null 2>&1; then
	for file in "$directory"/*.txt "$directory/id1"/*.txt "$directory/qw"/*.txt "$directory/ezquake/cfg"/* "$directory/ezquake/configs"/* "$directory/ezquake"/*.txt "$directory/fortress"/*.cfg "$directory/prox/configs"/*.cfg
	do
		if [ -f "$file" ]
		then
			# Only convert text files, skip binaries and files with encoding issues
			if file "$file" | grep -q "text" 2>/dev/null
			then
				awk '{ sub("\r$", ""); print }' "$file" > /tmp/.nquake.tmp 2>/dev/null && mv /tmp/.nquake.tmp "$file"
			fi
		fi
	done
else
	# Fallback: convert all files without checking type
	for file in "$directory"/*.txt "$directory/id1"/*.txt "$directory/qw"/*.txt "$directory/ezquake/cfg"/* "$directory/ezquake/configs"/* "$directory/ezquake"/*.txt "$directory/fortress"/*.cfg "$directory/prox/configs"/*.cfg
	do
		if [ -f "$file" ]
		then
			awk '{ sub("\r$", ""); print }' "$file" > /tmp/.nquake.tmp 2>/dev/null && mv /tmp/.nquake.tmp "$file"
		fi
	done
fi
echo -e " ${GREEN}✓${NC}"

# ezQuake.app setup - symlink clean and safe
if [ -d "$directory/ezQuake.app" ]
then
    echo -ne "${CYAN}→${NC} Setting up ezQuake.app bundle..."
    RES="$directory/ezQuake.app/Contents/Resources"

    # Remove any old symlinks or wrong directories
    rm -rf "$RES/id1"
    rm -rf "$RES/qw"
    rm -rf "$RES/ezquake"

    # Create correct symlinks
    ln -s "$directory/id1"     "$RES/id1"
    ln -s "$directory/qw"      "$RES/qw"
    ln -s "$directory/ezquake" "$RES/ezquake"

    # Copy game files into app bundle instead of symlinking
    # This ensures ezQuake finds them without needing -basedir
    mkdir -p "$directory/ezQuake.app/Contents/Resources/id1"
    cp -f "$directory/id1"/*.pak "$directory/ezQuake.app/Contents/Resources/id1/" 2>/dev/null

    echo -e " ${GREEN}✓${NC}"
fi

# Set the correct permissions
echo -ne "${CYAN}→${NC} Setting permissions..."
find "$directory" -type f -exec chmod -f 644 {} \;
find "$directory" -type d -exec chmod -f 755 {} \;
chmod -f +x "$directory/ezQuake.app/Contents/MacOS"/* 2> /dev/null
echo -e " ${GREEN}✓${NC}"

echo
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║                                                          ║${NC}"
echo -e "${BOLD}${GREEN}║                 ✓ Installation Complete!                 ║${NC}"
echo -e "${BOLD}${GREEN}║                                                          ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo
if [ -d "$directory/ezQuake.app" ]
then
	echo -e "${WHITE}nQuake was successfully installed!${NC}"
	echo -e "${CYAN}➜${NC} To start playing, open ${BOLD}ezQuake.app${NC} in:"
	echo -e "   ${YELLOW}$directory${NC}"
else
	echo -e "${WHITE}nQuake was successfully installed!${NC}"
	echo -e "${CYAN}➜${NC} Check your nQuake directory for the game files:"
	echo -e "   ${YELLOW}$directory${NC}"
fi
echo
echo -e "${MAGENTA}${BOLD}Happy gibbing! 🎮${NC}"
echo