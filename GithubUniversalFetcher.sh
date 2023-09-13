#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title GitHubUniversalFetcher
# @raycast.mode fullOutput
# @raycast.description Download content from any GitHub URL.

# Optional parameters:
# @raycast.icon 📥
# @raycast.packageName GitHub Tools
# @raycast.needsConfirmation false
# @raycast.author Marcus Hamelink
# @raycast.authorURL https://github.com/animarcus
# @raycast.argument1 { "type": "text", "placeholder": "GitHub URL" }
# @raycast.argument2 { "type": "text", "placeholder": "Destination Path", "optional": true }

# Function to check if the provided URL is valid
function is_valid_url() {
    local url="$1"
    if [[ $url =~ ^https://github\.com/.*$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to download content from GitHub
function download_github_content() {
    local url="$1"
    local path="$2"

    # Check if the URL is valid
    if ! is_valid_url "$url"; then
        echo "Invalid GitHub URL: $url"
        exit 1
    fi

    # Remove trailing slash from path (if any)
    path="${path%/}"

    # Extract the name for the dedicated directory only if it's not a single file
    if [[ "$url" == *"/tree/"* ]]; then
        # For folder URLs, use the branch or folder name
        folder_name=$(basename "$url")
        path="$path/$folder_name"
    elif [[ "$url" != *"/blob/"* ]]; then
        # For repository URLs, use the repository name
        folder_name=$(basename "$url")
        path="$path/$folder_name"
    fi

    # Determine if it's a file, folder, or repository URL
    if [[ "$url" == *"/blob/"* ]]; then
        # It's a file URL
        file_url="${url//github.com/raw.githubusercontent.com}"
        file_url="${file_url//blob\//}"
        curl -L "$file_url" -o "$path/$(basename "$url")"
    elif [[ "$url" == *"/tree/"* ]]; then
        # It's a folder URL
        repo=$(echo "$url" | awk -F'/' '{print $4"/"$5}')
        branch=$(echo "$url" | awk -F'/' '{print $7}')
        sub_path=$(echo "$url" | cut -d '/' -f 8-)
        api_url="https://api.github.com/repos/$repo/git/trees/$branch:$sub_path?recursive=1"
        content_json="$(curl -s "$api_url")"

        # Extract all file paths
        files=$(echo "$content_json" | jq -r '.tree[] | select(.type=="blob") | .path')

        # Download each file
        for file in $files; do
            file_url="https://raw.githubusercontent.com/$repo/$branch/$file"
            curl -L "$file_url" -o "$path/$file" --create-dirs
        done
    else
        # Assume it's a repository URL
        repo=$(echo "$url" | awk -F'/' '{print $4"/"$5}')
        branch="master" # default branch, can be changed if necessary
        archive_url="https://github.com/$repo/archive/refs/heads/$branch.tar.gz"
        mkdir -p "$path"
        curl -L "$archive_url" | tar xz -C "$path"
    fi

    full_path=$(realpath "$path")

    echo "$full_path"
}

# Check for required tools: curl and jq
if ! command -v curl &>/dev/null; then
    echo "Error: curl is not installed."
    echo "Please install curl. More info: https://curl.se/download.html"
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "Error: jq is not installed."
    echo "Please install jq. More info: https://stedolan.github.io/jq/download/"
    exit 1
fi

# Check for the correct number of arguments
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

url="$1"
path="${2:-.}" # Default to current directory if no path is provided

download_github_content "$url" "$path"
