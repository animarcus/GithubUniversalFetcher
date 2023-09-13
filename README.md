# Github Universal Fetcher

GitHubUniversalFetcher is a command-line tool that allows users to download content from any GitHub URL. Whether you're interested in a specific file, a folder, or an entire repository, GitHubUniversalFetcher has you covered.

## Table of Contents

- [Github Universal Fetcher](#github-universal-fetcher)
  - [Table of Contents](#table-of-contents)
  - [Installation](#installation)
  - [Usage](#usage)
  - [Examples](#examples)
  - [Raycast Integration](#raycast-integration)
    - [Setting up for Raycast](#setting-up-for-raycast)

## Installation

1. Clone this repository or download the `GithubUniversalFetcher.sh` script.
2. Provide execute permissions: `chmod +x GithubUniversalFetcher.sh`
3. Optionally, move the script to a directory in your PATH for easier access.
4. Ensure you have `curl` and `jq` installed on your system. The script will check for their presence and provide installation links if either is missing.

## Usage

Run the script with the desired GitHub URL and optionally specify a destination path.

```code
./GithubUniversalFetcher.sh <GitHub URL> [<Destination Path>]
```

- `<GitHub URL>`: The URL of the file, folder, or repository on GitHub you wish to download.
- `[<Destination Path>]`: (Optional) The directory where the content should be downloaded. If not provided, the current directory is used.

## Examples

1. Download a specific file:

```code
./GithubUniversalFetcher.sh https://github.com/user/repo/blob/main/file.txt /path/to/save
```

1. Download an entire folder:

```code
./GithubUniversalFetcher.sh https://github.com/user/repo/tree/main/folder
```

1. Download an entire repository:

```code
./GithubUniversalFetcher.sh https://github.com/user/repo
```

This works regardless of the branch.

## Raycast Integration

GitHubUniversalFetcher can be easily integrated with [Raycast](https://www.raycast.com/) as a script command, allowing you to utilize its capabilities directly from the Raycast interface.

### Setting up for Raycast

1. Ensure you've installed Raycast from the [official website](https://www.raycast.com/).
2. Clone this repository or download the `GithubUniversalFetcher.sh` script.
3. Move the script to a directory that Raycast will scan for script commands. By default, Raycast looks in `~/.raycast/script-commands/`.
4. Provide execute permissions: `chmod +x ~/.raycast/script-commands/GithubUniversalFetcher.sh`
5. Open Raycast and refresh script commands by using the shortcut `cmd + shift + r`.

Once set up, you can invoke Raycast, search for "GitHubUniversalFetcher", and run the command. Raycast will prompt you for the GitHub URL and an optional destination path.
