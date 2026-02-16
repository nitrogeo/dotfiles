#!/bin/bash

# --- Colors ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[33m'
ORANGE='\033[38;2;245;169;127m'
MAGENTA='\033[35m'
CYAN='\033[36m'
NC='\033[0m' # No Color


# Target directory (where your GitHub repo is) - must use the full path to avoid tilde (~) expansion issues
TARGET="/home/nitro/Documents/[1] developer + git~/dotfiles"



# 1. SHOW STATUS FIRST
echo -e "${MAGENTA}--- Current Git Status (What's changed in your repo) ---${NC}"
cd "$TARGET" || exit
cd "$TARGET" || { echo "❌ Error: Could not find $TARGET"; exit 1; }
git status -s
echo -e "${MAGENTA}-------------------------------------------------------${NC}"


# 2. ASK TO COPY FILES
echo -e "${YELLOW}Do you want to copy your current local configs to the local github directory? (y/n)${NC}"
read -r sync_choice

if [[ "$sync_choice" == "y" ]]; then
    # Ensure directories exist:

	# Create subdirectories in the repo if they don't exist
	mkdir -p "$TARGET/hypr"
	mkdir -p "$TARGET/waybar"
	mkdir -p "$TARGET/kitty"
	mkdir -p "$TARGET/espanso"
	mkdir -p "$TARGET/notes"
	mkdir -p "$TARGET/rofi"
	mkdir -p "$TARGET/scripts"


	# Copy the files
	# Copy contents of directories
	cp -a /home/nitro/.config/hypr/. "$TARGET/hypr/"
	cp -a /home/nitro/.config/waybar/. "$TARGET/waybar/"
	cp -a /home/nitro/.config/rofi/. "$TARGET/rofi/"
	cp -a "/home/nitro/scripts" "$TARGET/scripts"

	# Copy specific files
	cp -a /home/nitro/.config/kitty/kitty.conf "$TARGET/kitty/"
	cp -a /home/nitro/.config/espanso/match/base.yml "$TARGET/espanso/"

	# Copy obsidian linux notes (wildcard (*) handles the quote eror)
	cp -a "/home/nitro/Documents/@notes/@obsidian/nitro"*"/linux offline notes/." "$TARGET/notes/" 2>/dev/null || echo -e "${ORANGE}⚠️ Warning: Obsidian notes folder not found.${NC}"


	echo -e "${GREEN}✅ configs copied to {${CYAN}$TARGET${GREEN}}~${NC}"

else
    echo -e "${BLUE}Skipping copy...${NC}"
fi



# 3. CHOOSE PUSH METHOD
echo ""
echo -e "${YELLOW}How do you want to handle the GitHub push?${NC}"
echo "1) Terminal (Automated)"
echo "2) GitHub Desktop (Manual)"
echo "3) Exit without pushing"
read -r push_method

case $push_method in
    1)
        # Terminal Path
        echo -e "${BLUE}Enter commit message:${NC}"
        read -r commit_msg
        
        echo -e "${YELLOW}Add description? (y/n)${NC}"
        read -r add_desc
        
        git add .
        if [[ "$add_desc" == "y" ]]; then
            echo -e "${BLUE}Enter description:${NC}"
            read -r commit_desc
            git commit -m "$commit_msg" -m "$commit_desc"
        else
            git commit -m "$commit_msg"
        fi
        
        echo -e "${MAGENTA}🚀 pushing to gitHub...${NC}"
        git push
        echo "done!"
        ;;
    2)
        # GitHub Desktop Path
        echo -e "${MAGENTA}opening GitHub Desktop...${NC}" # (or just open it manually)
        # This command attempts to launch it, but might vary by install (Flatpak vs Native)
        github-desktop & 
        exit 0
        ;;
    *)
        echo -e "${MAGENTA}exiting without pushing to GitHub~${NC}"
        exit 0
        ;;
esac