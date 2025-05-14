#!/bin/bash

# File Sync Utility
# This script synchronizes files between two folders with two-way sync capability
# Usage: ./file_sync.sh [source_folder] [destination_folder] [options]

# Constants for log levels
INFO="INFO"
WARNING="WARNING"
ERROR="ERROR"

# Log file path
LOG_FILE="file_sync.log"

# Function to log messages
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Also print to console
    if [[ "$level" == "$ERROR" ]]; then
        echo -e "\e[31m[$level] $message\e[0m"  # Red color for errors
    elif [[ "$level" == "$WARNING" ]]; then
        echo -e "\e[33m[$level] $message\e[0m"  # Yellow color for warnings
    else
        echo "[$level] $message"
    fi
}

# Function to show help
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

# Function to check if a file exists
file_exists() {
    local file_path=$1
    if [ -f "$file_path" ]; then
        return 0  # True
    else
        return 1  # False
    fi
}

# Function to get file modification time in seconds since epoch
get_mod_time() {
    local file_path=$1
    if file_exists "$file_path"; then
        stat -c %Y "$file_path" 2>/dev/null || stat -f %m "$file_path" 2>/dev/null
    else
        echo "0"  # Return 0 if file doesn't exist
    fi
}

# Function to compare files based on modification time
# Returns: 
#   0 - Files are identical or don't need sync
#   1 - Source is newer
#   2 - Destination is newer
#   3 - Both have changes (conflict)
compare_files() {
    local source_file=$1
    local dest_file=$2
    
    # Check if both files exist
    local source_exists=0
    local dest_exists=0
    
    file_exists "$source_file" && source_exists=1
    file_exists "$dest_file" && dest_exists=1
    
    # If neither file exists, no action needed
    if [ $source_exists -eq 0 ] && [ $dest_exists -eq 0 ]; then
        return 0
    fi
    
    # If only source exists, copy to destination
    if [ $source_exists -eq 1 ] && [ $dest_exists -eq 0 ]; then
        return 1
    fi
    
    # If only destination exists, copy to source
    if [ $source_exists -eq 0 ] && [ $dest_exists -eq 1 ]; then
        return 2
    fi
    
    # Both files exist, compare modification times
    local source_time=$(get_mod_time "$source_file")
    local dest_time=$(get_mod_time "$dest_file")
    
    # Check if files are identical using checksum
    if [ "$(md5sum "$source_file" | cut -d ' ' -f 1)" == "$(md5sum "$dest_file" | cut -d ' ' -f 1)" ]; then
        return 0  # Files are identical
    fi
    
    # Check for conflict (both files modified since last sync)
    # For simplicity, we'll detect conflicts based on modification times
    # In a real-world scenario, you might want to store the last sync time
    
    # If source is newer
    if [ $source_time -gt $dest_time ]; then
        return 1
    # If destination is newer
    elif [ $dest_time -gt $source_time ]; then
        return 2
    # If modification times are the same but content differs (rare case)
    else
        return 3  # Conflict
    fi
}

# Function to copy a file
copy_file() {
    local source=$1
    local destination=$2
    local direction=$3  # "to_dest" or "to_source"
    
    # Create destination directory if it doesn't exist
    mkdir -p "$(dirname "$destination")"
    
    # Copy the file
    cp -p "$source" "$destination"
    
    if [ $? -eq 0 ]; then
        if [ "$direction" == "to_dest" ]; then
            log_message "$INFO" "Copied file to destination: $destination"
        else
            log_message "$INFO" "Copied file to source: $destination"
        fi
        return 0
    else
        log_message "$ERROR" "Failed to copy: $source -> $destination"
        return 1
    fi
}

# Function to handle file conflicts
handle_conflict() {
    local source_file=$1
    local dest_file=$2
    
    if [ "$FORCE_MODE" == "true" ]; then
        # In force mode, source wins
        log_message "$WARNING" "Conflict resolved (force mode, source wins): $source_file"
        copy_file "$source_file" "$dest_file" "to_dest"
        return
    fi
    
    # Create backup of destination file
    local backup_file="${dest_file}.backup.$(date +%s)"
    cp "$dest_file" "$backup_file"
    
    log_message "$WARNING" "Conflict detected: $source_file and $dest_file"
    log_message "$INFO" "Created backup: $backup_file"
    
    # Ask user for resolution if not in dry run mode
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
        echo ""
        read -p "Enter choice [1-3]: " choice
        
        case $choice in
            1)
                copy_file "$source_file" "$dest_file" "to_dest"
                ;;
            2)
                copy_file "$dest_file" "$source_file" "to_source"
                ;;
            3)
                log_message "$INFO" "Skipped conflicted file: $source_file"
                ;;
            *)
                log_message "$WARNING" "Invalid choice, skipping file: $source_file"
                ;;
        esac
    else
        log_message "$INFO" "Dry run: Conflict would require manual resolution: $source_file"
    fi
}

# Function to synchronize files
sync_files() {
    local source_dir=$1
    local dest_dir=$2
    
    # Make sure directories end with a slash
    [[ "$source_dir" != */ ]] && source_dir="$source_dir/"
    [[ "$dest_dir" != */ ]] && dest_dir="$dest_dir/"
    
    log_message "$INFO" "Starting sync from $source_dir to $dest_dir"
    
    # Get a list of all files in source directory
    find "$source_dir" -type f -not -path "*/\.*" | while read source_file; do
        # Get the relative file path
        local rel_path="${source_file#$source_dir}"
        local dest_file="$dest_dir$rel_path"
        
        # Compare files
        compare_files "$source_file" "$dest_file"
        local comparison_result=$?
        
        case $comparison_result in
            0) # Files are identical or don't need sync
                log_message "$INFO" "No sync needed: $rel_path"
                ;;
            1) # Source is newer
                if [ "$DRY_RUN" == "true" ]; then
                    log_message "$INFO" "Dry run: Would copy to destination: $rel_path"
                else
                    copy_file "$source_file" "$dest_file" "to_dest"
                fi
                ;;
            2) # Destination is newer
                if [ "$DRY_RUN" == "true" ]; then
                    log_message "$INFO" "Dry run: Would copy to source: $rel_path"
                else
                    copy_file "$dest_file" "$source_file" "to_source"
                fi
                ;;
            3) # Conflict
                handle_conflict "$source_file" "$dest_file"
                ;;
        esac
    done
    
    # Check for files only in destination
    find "$dest_dir" -type f -not -path "*/\.*" | while read dest_file; do
        # Get the relative file path
        local rel_path="${dest_file#$dest_dir}"
        local source_file="$source_dir$rel_path"
        
        # Check if the file exists in source
        if ! file_exists "$source_file"; then
            if [ "$DRY_RUN" == "true" ]; then
                log_message "$INFO" "Dry run: Would copy to source: $rel_path"
            else
                copy_file "$dest_file" "$source_file" "to_source"
            fi
        fi
    done
    
    log_message "$INFO" "Sync completed between $source_dir and $dest_dir"
}

# Main script execution

# Initialize variables
SOURCE_DIR=""
DEST_DIR=""
DRY_RUN="false"
FORCE_MODE="false"

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_help
            exit 0
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --force)
            FORCE_MODE="true"
            shift
            ;;
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

# Validate source and destination directories
if [ -z "$SOURCE_DIR" ] || [ -z "$DEST_DIR" ]; then
    log_message "$ERROR" "Source and destination directories are required"
    show_help
    exit 1
fi

# Check if directories exist
if [ ! -d "$SOURCE_DIR" ]; then
    log_message "$ERROR" "Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

if [ ! -d "$DEST_DIR" ]; then
    log_message "$INFO" "Destination directory does not exist. Creating: $DEST_DIR"
    mkdir -p "$DEST_DIR"
    if [ $? -ne 0 ]; then
        log_message "$ERROR" "Failed to create destination directory: $DEST_DIR"
        exit 1
    fi
fi

# Print sync mode
if [ "$DRY_RUN" == "true" ]; then
    log_message "$INFO" "Running in DRY RUN mode - no changes will be made"
fi

if [ "$FORCE_MODE" == "true" ]; then
    log_message "$INFO" "Running in FORCE mode - conflicts will be resolved automatically"
fi

# Start synchronization
sync_files "$SOURCE_DIR" "$DEST_DIR"

exit 0