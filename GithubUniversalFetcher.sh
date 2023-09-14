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

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
APPLESCRIPT_DIR="$SCRIPT_DIR/applescript-helper-tools"

download_github_folder() {
    # Input: GitHub URL and Destination directory
    local URL="$1"
    local DEST_DIR="$2"

    # Extract user, repo, branch, and folder path from the URL
    local USER REPO BRANCH FOLDER_PATH
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
        echo "Detected repository root. Cloning the repository..." >&2
        git clone -b "$BRANCH" "https://github.com/$USER/$REPO.git" "${DEST_DIR}/${REPO}" >&2
        echo "Cloned to ${DEST_DIR}/${REPO}/" >&2
        echo "${DEST_DIR}/${REPO}/"
        exit 0
    fi

    local API_URL="https://api.github.com/repos/$USER/$REPO/contents/$FOLDER_PATH?ref=$BRANCH"

    # Get the list of all files in the specified directory
    local FILES
    FILES=$(curl -s "$API_URL" | grep -Eo '"download_url": "[^"]+"' | grep -Eo "https://raw[^\" ]+")
    # echo "API Response: $FILES"

    # Download each file to the specified destination directory
    for FILE_URL in $FILES; do
        # Extract the file path from the URL to create a local directory structure
        local FILE_PATH LOCAL_PATH FILE_NAME
        FILE_PATH=${FILE_URL##*/}
        PARENT_DIR_NAME=$(basename "$FOLDER_PATH")
        FILE_NAME=$(basename "${FILE_PATH}")

        if [[ $(echo "$FILES" | wc -l) -eq 1 ]]; then
            LOCAL_PATH="${DEST_DIR}/${FILE_NAME}"
        else
            LOCAL_PATH="${DEST_DIR}/${PARENT_DIR_NAME}/${FILE_NAME}"
        fi

        # Create folder structure and download file
        mkdir -p "$(dirname "$LOCAL_PATH")"

        # echo "local path: $LOCAL_PATH"
        # echo "file url: $FILE_URL"
        # echo "file name: $FILE_NAME"
        curl "$FILE_URL" -o "$LOCAL_PATH" >&2
    done

    # echo "Downloaded to $DEST_DIR"
    echo "$DEST_DIR"
}

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <GitHub URL> [<Destination Path>]"
    echo ""
    echo "GitHubUniversalFetcher is designed to download content from any GitHub URL."
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

    # If no path is provided, default to the ~/Downloads folder
    if [[ -z "$provided_path" ]]; then
        get_visible_finder_directory
        return
    fi

    # Handle ~ for home directory
    if [[ "$provided_path" == \~* ]]; then
        echo "${provided_path/#\~/$HOME}"
        return
    fi

    # If path is absolute, return as is
    if [[ "$provided_path" == /* ]]; then
        echo "$provided_path"
        return
    fi

    # Handle other relative paths
    realpath "$provided_path"
}

get_visible_finder_directory() {
    local finder_path=""
    finder_path=$(osascript "$APPLESCRIPT_DIR/getVisibleFinderDir.js")

    # If we got a path from Finder, use it. Otherwise, default to the Downloads folder.
    if [[ -z "$finder_path" ]]; then
        echo "$HOME/Downloads/"
    else
        echo "$finder_path"
    fi
}

destination="$(download_github_folder "$1" "$(get_destination_path "$2")")"
# echo "Downloaded to $destination"

osascript -l JavaScript "$APPLESCRIPT_DIR/displayDialog.js" "$destination"
exit 0
