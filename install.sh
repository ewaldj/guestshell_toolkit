
#!/bin/bash
 
# repository information
OWNER="ewaldj"
REPO="guestshell_toolkit"
BRANCH="main"
 
PLATFORM=$(uname -m)
 
case "$PLATFORM" in
    x86_64)
        DIR_PATH="rpm/x86_64"
        ARCH="x86_64"
        ;;
    aarch64 | arm64)
        DIR_PATH="rpm/aarch64"
        ARCH="aarch64"
        ;;
    *)
        echo "Unsupported $PLATFORM"
        exit 1
        ;;
esac
 
echo -e "\n### architecture recognised: $ARCH ###\n"
# create api_url
API_URL="https://api.github.com/repos/$OWNER/$REPO/contents/$DIR_PATH?ref=$BRANCH"
 
# check connection
echo -e "\n### check connection to GitHub.com ### \n"
if ! curl -s --head https://github.com | head -n 1 | grep "200" > /dev/null; then
    echo -e "\n### Unable to connect to GitHub.com ### "
    exit 1
fi
 
# create folder
mkdir -p rpm
echo -e "\n### download and install rmp files ###\n"
 
# json pars with  grep/sed/awk
echo "Load file list from $API_URL..."
curl -s "$API_URL" | grep '"download_url":' | sed -E 's/.*"download_url": "([^"]+)".*/\1/' | while read -r url; do
    filename=$(basename "$url")
    echo "load file $filename ..."
    curl -s -L "$url" -o "rpm/$filename"
done
 
echo -e "\n### install rpm files ####\n"
 
# install all rpm files
sudo rpm -Uvh rpm/*.rpm --force
 
# install eping.py and epinga.py
echo -e "\n ### download and install eping.py and epinga.py ###\n"
mkdir -p eping
 
# download eping
cd eping
curl -O https://raw.githubusercontent.com/ewaldj/eping/refs/heads/main/eping.py
curl -O https://raw.githubusercontent.com/ewaldj/eping/refs/heads/main/epinga.py
chmod +x eping.py
chmod +x epinga.py
cd ..
 
# add directories to PATH in .bashrc
# each line only extends PATH if the directory is not already in it,
# so sourcing .bashrc multiple times does not create duplicates
FILE="$HOME/.bashrc"
touch "$FILE"
 
# remove the old unguarded eping line from earlier versions of this script
sed -i '\|^export PATH="\$HOME/eping/:\$PATH"$|d' "$FILE"
 
add_path_line() {
    # $1 = directory, $2 = prepend|append
    local dir="$1"
    local line
    if [ "$2" = "prepend" ]; then
        line="case \":\$PATH:\" in *\":$dir:\"*) ;; *) export PATH=\"$dir:\$PATH\" ;; esac"
    else
        line="case \":\$PATH:\" in *\":$dir:\"*) ;; *) export PATH=\"\$PATH:$dir\" ;; esac"
    fi
    if ! grep -Fxq "$line" "$FILE"; then
        echo "$line" >> "$FILE"
        echo "### PATH entry for $dir added to .bashrc ###"
    else
        echo "### PATH entry for $dir already exists in .bashrc ###"
    fi
}
 
echo -e "\n### update PATH in .bashrc ###\n"
add_path_line '$HOME/eping' prepend
add_path_line '/usr/local/sbin' append
add_path_line '/usr/sbin' append
add_path_line '/sbin' append
 
# cleanup - delete rpm directory
rm -r rpm/
echo -e "\n### done - run 'source ~/.bashrc' or log in again ###"
echo -e "\n### done - have a nice day - www.jeitler.cc ###\n"
