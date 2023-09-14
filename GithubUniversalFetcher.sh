#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title GitHub Universal Fetcher
# @raycast.mode fullOutput
# @raycast.description Download content from any GitHub URL using DownGit. (Default path is either the currently focused finder window or the Desktop)

# Optional parameters:
# @raycast.icon 📥
# @raycast.packageName Github Universal Fetcher package
# @raycast.needsConfirmation false
# @raycast.author Marcus Hamelink
# @raycast.authorURL https://github.com/animarcus
# @raycast.argument1 { "type": "text", "placeholder": "GitHub URL" }
# @raycast.argument2 { "type": "text", "placeholder": "Destination Path", "optional": true }

download_github_folder() {
    # Input: GitHub URL and Destination directory
    local URL="$1"
    local DEST_DIR="$2"
    if [ -z "$DEST_DIR" ] || [ "$DEST_DIR" == "." ] || [ "$DEST_DIR" == "./" ]; then
        DEST_DIR=$(pwd)
    fi

    # Extract user, repo, branch, and folder path from the URL
    local USER
    local REPO
    local BRANCH
    local FOLDER_PATH
    # Extract user, repo, branch, and folder path from the URL
    if [[ "$URL" =~ https://github.com/([^/]+)/([^/]+)/(blob|tree)/([^/]+)/?(.*) ]]; then
        USER=${BASH_REMATCH[1]}
        REPO=${BASH_REMATCH[2]}
        BRANCH=${BASH_REMATCH[4]}
        FOLDER_PATH=${BASH_REMATCH[5]}
    else
        echo "Invalid GitHub URL format"
        exit 1
    fi

    # Convert spaces in folder path to %20 for URL encoding
    FOLDER_PATH=${FOLDER_PATH// /%20}

    # If FOLDER_PATH is empty, it means the entire repo (or specific branch) needs to be cloned
    if [ -z "$FOLDER_PATH" ]; then
        echo "Detected repository root. Cloning the repository..."
        git clone -b "$BRANCH" "https://github.com/$USER/$REPO.git" "${DEST_DIR}/${REPO}"
        echo "Cloned to ${DEST_DIR}/${REPO}/"
        exit 0
    fi

    local API_URL="https://api.github.com/repos/$USER/$REPO/contents/$FOLDER_PATH?ref=$BRANCH"

    # Get the list of all files in the specified directory
    local FILES
    FILES=$(curl -s "$API_URL" | grep -Eo '"download_url": "[^"]+"' | grep -Eo "https://raw[^\" ]+")
    # Download each file
    for FILE_URL in $FILES; do
        # Extract the file path from the URL to create a local directory structure
        local FILE_PATH
        local LOCAL_PATH
        local FILE_NAME
        FILE_PATH=${FILE_URL##*/}

        PARENT_DIR_NAME=$(basename "$FOLDER_PATH")

        FILE_NAME=$(basename "${FILE_PATH}")

        # LOCAL_PATH="${DEST_DIR}/${PARENT_DIR_NAME}/${FILE_NAME}"
        if [[ $(echo "$FILES" | wc -l) -eq 1 ]]; then
            LOCAL_PATH="${DEST_DIR}/${FILE_NAME}"
        else
            LOCAL_PATH="${DEST_DIR}/${PARENT_DIR_NAME}/${FILE_NAME}"
        fi

        # Create folder structure and download file
        mkdir -p "$(dirname "$LOCAL_PATH")"

        # echo "FILE name: $FILE_NAME"
        # echo "FILE path: $FILE_PATH"
        # echo "LOCAL_PATH: $LOCAL_PATH"
        # find "$(dirname "$LOCAL_PATH")" | cat
        # echo "Attempting to download to: $LOCAL_PATH"
        curl "$FILE_URL" -o "$LOCAL_PATH"
    done

    echo "Downloaded to $DEST_DIR"
}

# Check for the correct number of arguments
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <GitHub URL> [<Destination Path>]"
    echo ""
    echo "GitHubUniversalFetcher is designed to download content from any GitHub URL using DownGit."
    echo "It handles file, folder, or entire repository URLs from GitHub."
    echo ""
    echo "Parameters:"
    echo "  <GitHub URL>            : URL of the file, folder, or repository on GitHub."
    echo "  [<Destination Path>]    : (Optional) Directory to download the content. Defaults to the current directory."
    echo ""
    echo "Examples:"
    echo "  $0 https://github.com/user/repo/blob/main/file.txt /path/to/save"
    echo "  $0 https://github.com/user/repo/tree/main/folder"
    echo "  $0 https://github.com/user/repo"
    exit 1
fi

get_destination_path() {
    local provided_path="$1"
    if [[ -n "$provided_path" ]]; then
        echo "$provided_path"
    else
        if [[ -z "$RAYCAST_SCHEMA_VERSION" ]]; then
            # If not run from Raycast, return the provided path
            echo "$provided_path"
            return
        fi
        # If path is not provided, try to get the focused Finder window path
        local focused_finder_path
        focused_finder_path=$(osascript -e 'tell app "Finder" to get the POSIX path of (target of front window as alias)' 2>/dev/null)
        if [[ -z "$focused_finder_path" ]]; then
            # If no Finder window is focused, default to the desktop
            echo "$HOME/Desktop"
        else
            echo "$focused_finder_path"
        fi
    fi
}

echo args: "$1" "$(get_destination_path "$2")"
download_github_folder "$1" "$(get_destination_path "$2")"
