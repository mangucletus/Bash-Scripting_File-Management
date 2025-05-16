#!/bin/bash

# File Sync Utility
# This script synchronizes files between two folders with two-way sync capability.
# It compares modification times and file checksums to determine sync direction.
# Usage: ./file_sync.sh [source_folder] [destination_folder] [options]

# Constants to represent log levels for easier log formatting and filtering
INFO="INFO"
WARNING="WARNING"
ERROR="ERROR"

# Path to the log file where sync actions and errors will be recorded
LOG_FILE="file_sync.log"

# Function to log messages to both the log file and the console with color coding
log_message() {
    local level=$1      # Log level: INFO, WARNING, or ERROR
    local message=$2    # Message content
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")  # Current timestamp

    # Append log entry to the log file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    # Display log message in the terminal with optional color formatting
    if [[ "$level" == "$ERROR" ]]; then
        echo -e "\e[31m[$level] $message\e[0m"  # Red for errors
    elif [[ "$level" == "$WARNING" ]]; then
        echo -e "\e[33m[$level] $message\e[0m"  # Yellow for warnings
    else
        echo "[$level] $message"               # Default for info
    fi
}

# Function to display usage information
show_help() {
    echo "File Sync Utility"
    echo "Usage: ./file_sync.sh [source_folder] [destination_folder] [options]"
    echo ""
    echo "Options:"
    echo "  --dry-run       Show what would be done without making changes"
    echo "  --force         Overwrite files without asking"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./file_sync.sh ~/Documents/folder1 ~/Documents/folder2"
    echo "  ./file_sync.sh ~/Documents/folder1 ~/Documents/folder2 --dry-run"
}

# Utility function to check whether a given file path exists
file_exists() {
    local file_path=$1
    if [ -f "$file_path" ]; then
        return 0  # File exists
    else
        return 1  # File does not exist
    fi
}

# Function to get the last modification time of a file in seconds since epoch
get_mod_time() {
    local file_path=$1
    if file_exists "$file_path"; then
        # Use stat command for Linux or macOS compatibility
        stat -c %Y "$file_path" 2>/dev/null || stat -f %m "$file_path" 2>/dev/null
    else
        echo "0"  # Return 0 if file does not exist
    fi
}

# Function to compare two files and decide the sync action
# Returns:
#   0 = Files are identical
#   1 = Source is newer
#   2 = Destination is newer
#   3 = Conflict detected (both changed)
compare_files() {
    local source_file=$1
    local dest_file=$2

    local source_exists=0
    local dest_exists=0

    file_exists "$source_file" && source_exists=1
    file_exists "$dest_file" && dest_exists=1

    if [ $source_exists -eq 0 ] && [ $dest_exists -eq 0 ]; then
        return 0  # No files to compare
    elif [ $source_exists -eq 1 ] && [ $dest_exists -eq 0 ]; then
        return 1  # Only source exists, needs to copy to destination
    elif [ $source_exists -eq 0 ] && [ $dest_exists -eq 1 ]; then
        return 2  # Only destination exists, needs to copy to source
    fi

    # Both files exist, compare contents using checksums
    if [ "$(md5sum "$source_file" | cut -d ' ' -f 1)" == "$(md5sum "$dest_file" | cut -d ' ' -f 1)" ]; then
        return 0  # Files are identical
    fi

    # Compare modification times if checksums differ
    local source_time=$(get_mod_time "$source_file")
    local dest_time=$(get_mod_time "$dest_file")

    if [ $source_time -gt $dest_time ]; then
        return 1  # Source is newer
    elif [ $dest_time -gt $source_time ]; then
        return 2  # Destination is newer
    else
        return 3  # Conflict: same timestamp but different content
    fi
}

# Function to copy a file from source to destination or vice versa
copy_file() {
    local source=$1
    local destination=$2
    local direction=$3  # Used for logging: "to_dest" or "to_source"

    mkdir -p "$(dirname "$destination")"  # Ensure destination directory exists
    cp -p "$source" "$destination"        # Copy file with permissions and timestamp

    if [ $? -eq 0 ]; then
        if [ "$direction" == "to_dest" ]; then
            log_message "$INFO" "Copied file to destination: $destination"
        else
            log_message "$INFO" "Copied file to source: $destination"
        fi
    else
        log_message "$ERROR" "Failed to copy: $source -> $destination"
    fi
}

# Function to handle conflicts when both files have changed
handle_conflict() {
    local source_file=$1
    local dest_file=$2

    if [ "$FORCE_MODE" == "true" ]; then
        # Automatically resolve by copying source to destination
        log_message "$WARNING" "Conflict resolved (force mode, source wins): $source_file"
        copy_file "$source_file" "$dest_file" "to_dest"
        return
    fi

    # Create a backup before resolving conflict
    local backup_file="${dest_file}.backup.$(date +%s)"
    cp "$dest_file" "$backup_file"
    log_message "$WARNING" "Conflict detected: $source_file and $dest_file"
    log_message "$INFO" "Created backup: $backup_file"

    # Prompt user to choose resolution if not a dry run
    if [ "$DRY_RUN" != "true" ]; then
        echo ""
        echo "Conflict detected between:"
        echo "  Source: $source_file"
        echo "  Destination: $dest_file"
        echo ""
        echo "Choose an action:"
        echo "  1) Keep source version (copy to destination)"
        echo "  2) Keep destination version (copy to source)"
        echo "  3) Skip this file"
        read -p "Enter choice [1-3]: " choice

        case $choice in
            1) copy_file "$source_file" "$dest_file" "to_dest" ;;
            2) copy_file "$dest_file" "$source_file" "to_source" ;;
            3) log_message "$INFO" "Skipped conflicted file: $source_file" ;;
            *) log_message "$WARNING" "Invalid choice, skipping file: $source_file" ;;
        esac
    else
        log_message "$INFO" "Dry run: Conflict would require manual resolution: $source_file"
    fi
}

# Core function to synchronize files between source and destination directories
sync_files() {
    local source_dir=$1
    local dest_dir=$2

    # Normalize paths to ensure trailing slash
    [[ "$source_dir" != */ ]] && source_dir="$source_dir/"
    [[ "$dest_dir" != */ ]] && dest_dir="$dest_dir/"

    log_message "$INFO" "Starting sync from $source_dir to $dest_dir"

    # Step 1: Sync files from source to destination
    find "$source_dir" -type f -not -path "*/\.*" | while read source_file; do
        local rel_path="${source_file#$source_dir}"          # Relative path
        local dest_file="$dest_dir$rel_path"                 # Destination file path

        compare_files "$source_file" "$dest_file"            # Determine sync action
        local comparison_result=$?

        case $comparison_result in
            0) log_message "$INFO" "No sync needed: $rel_path" ;;
            1)
                [ "$DRY_RUN" == "true" ] \
                    && log_message "$INFO" "Dry run: Would copy to destination: $rel_path" \
                    || copy_file "$source_file" "$dest_file" "to_dest"
                ;;
            2)
                [ "$DRY_RUN" == "true" ] \
                    && log_message "$INFO" "Dry run: Would copy to source: $rel_path" \
                    || copy_file "$dest_file" "$source_file" "to_source"
                ;;
            3) handle_conflict "$source_file" "$dest_file" ;;
        esac
    done

    # Step 2: Sync files that exist only in the destination
    find "$dest_dir" -type f -not -path "*/\.*" | while read dest_file; do
        local rel_path="${dest_file#$dest_dir}"
        local source_file="$source_dir$rel_path"

        if ! file_exists "$source_file"; then
            [ "$DRY_RUN" == "true" ] \
                && log_message "$INFO" "Dry run: Would copy to source: $rel_path" \
                || copy_file "$dest_file" "$source_file" "to_source"
        fi
    done

    log_message "$INFO" "Sync completed between $source_dir and $dest_dir"
}

# Main Script Execution Starts Here

# Initialize global flags
SOURCE_DIR=""
DEST_DIR=""
DRY_RUN="false"
FORCE_MODE="false"

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help) show_help; exit 0 ;;
        --dry-run) DRY_RUN="true"; shift ;;
        --force) FORCE_MODE="true"; shift ;;
        *)
            if [ -z "$SOURCE_DIR" ]; then
                SOURCE_DIR="$1"
            elif [ -z "$DEST_DIR" ]; then
                DEST_DIR="$1"
            else
                log_message "$ERROR" "Unknown parameter: $1"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate input
if [ -z "$SOURCE_DIR" ] || [ -z "$DEST_DIR" ]; then
    log_message "$ERROR" "Source and destination directories are required"
    show_help
    exit 1
fi

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    log_message "$ERROR" "Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

# Create destination directory if missing
if [ ! -d "$DEST_DIR" ]; then
    log_message "$INFO" "Destination directory does not exist. Creating: $DEST_DIR"
    mkdir -p "$DEST_DIR"
    if [ $? -ne 0 ]; then
        log_message "$ERROR" "Failed to create destination directory: $DEST_DIR"
        exit 1
    fi
fi

# Inform user about modes
[ "$DRY_RUN" == "true" ] && log_message "$INFO" "Running in DRY RUN mode - no changes will be made"
[ "$FORCE_MODE" == "true" ] && log_message "$INFO" "Running in FORCE mode - conflicts will be resolved automatically"

# Begin synchronization process
sync_files "$SOURCE_DIR" "$DEST_DIR"

exit 0
