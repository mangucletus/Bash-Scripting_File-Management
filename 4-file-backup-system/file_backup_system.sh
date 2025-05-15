#!/bin/bash

# =============================
# File Backup System Script
# =============================
# This script allows users to perform full, incremental, or differential backups
# with additional options like compression, logging, and timestamping.

# -----------------------------
# Function: Display help message
# -----------------------------
show_help() {
    echo "File Backup System - Back up your important files"
    echo ""
    echo "Usage: $0 [OPTIONS] <source_directory> <backup_directory>"
    echo ""
    echo "Options:"
    echo "  -f          Full backup (copy all files, default)"
    echo "  -i          Incremental backup (only new or modified files)"
    echo "  -d DAYS     Differential backup (files modified in the last DAYS days)"
    echo "  -c          Compress the backup (creates a .tar.gz archive)"
    echo "  -l          Create a log file of the backup operation"
    echo "  -t          Add timestamp to backup directory name"
    echo "  -e PATTERN  Exclude files matching PATTERN (e.g., '*.tmp')"
    echo "  -h          Show this help message and exit"
    echo ""
}

# -----------------------------
# Initialize default settings
# -----------------------------
backup_type="full"      # Default backup type is full
days=0                  # Used only for differential backups
compress=false          # Whether to compress the backup
create_log=false        # Whether to create a log file
add_timestamp=false     # Whether to append a timestamp to the backup dir
exclude_pattern=""      # File pattern to exclude (if any)
source_dir=""           # Source directory path (user input)
backup_dir=""           # Backup directory path (user input)

# -----------------------------
# Parse command-line arguments
# -----------------------------
while getopts "fid:cle:th" opt; do
    case $opt in
        f) backup_type="full" ;;                        # Full backup
        i) backup_type="incremental" ;;                 # Incremental backup
        d) backup_type="differential"; days="$OPTARG" ;;# Differential backup with specified days
        c) compress=true ;;                             # Enable compression
        l) create_log=true ;;                           # Enable logging
        t) add_timestamp=true ;;                        # Enable timestamp
        e) exclude_pattern="$OPTARG" ;;                 # Set exclude pattern
        h) show_help; exit 0 ;;                         # Display help and exit
        \?) echo "Invalid option: -$OPTARG" >&2; show_help; exit 1 ;;  # Invalid option
    esac
done

# -----------------------------
# Get positional arguments
# -----------------------------
shift $((OPTIND - 1))
source_dir="$1"
backup_dir="$2"

# -----------------------------
# Validate required directories
# -----------------------------
if [ -z "$source_dir" ] || [ -z "$backup_dir" ]; then
    echo "Error: Source and backup directories must be specified"
    show_help
    exit 1
fi

if [ ! -d "$source_dir" ]; then
    echo "Error: Source directory '$source_dir' does not exist"
    exit 1
fi

# -----------------------------
# Add timestamp to backup dir (if enabled)
# -----------------------------
if [ "$add_timestamp" = true ]; then
    timestamp=$(date +"%Y%m%d_%H%M%S")
    backup_dir="${backup_dir}_${timestamp}"
fi

# -----------------------------
# Create the backup directory (if it doesn't exist)
# -----------------------------
if [ ! -d "$backup_dir" ]; then
    mkdir -p "$backup_dir"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create backup directory '$backup_dir'"
        exit 1
    fi
fi

# -----------------------------
# Set up logging (if enabled)
# -----------------------------
log_file=""
if [ "$create_log" = true ]; then
    log_file="${backup_dir}/backup_log_$(date +"%Y%m%d_%H%M%S").txt"
    echo "Backup started at $(date)" > "$log_file"
    echo "Source: $source_dir" >> "$log_file"
    echo "Destination: $backup_dir" >> "$log_file"
    echo "Backup type: $backup_type" >> "$log_file"
    if [ "$backup_type" = "differential" ]; then
        echo "Modified in the last $days days" >> "$log_file"
    fi
    echo "Compression: $([ "$compress" = true ] && echo "Enabled" || echo "Disabled")" >> "$log_file"
    echo "----------------------------------------" >> "$log_file"
fi

# -----------------------------
# Function: Log messages to console and log file
# -----------------------------
log_message() {
    local message="$1"
    echo "$message"
    if [ "$create_log" = true ]; then
        echo "$message" >> "$log_file"
    fi
}

# -----------------------------
# Start of backup process
# -----------------------------
log_message "Starting backup from '$source_dir' to '$backup_dir'"
log_message "Backup type: $backup_type"

# -----------------------------
# Function: Perform the backup
# -----------------------------
perform_backup() {
    local src="$1"
    local dst="$2"
    local rsync_options="-a --info=progress2"  # Archive mode, show progress

    # Add exclude pattern if specified
    if [ ! -z "$exclude_pattern" ]; then
        rsync_options="$rsync_options --exclude='$exclude_pattern'"
    fi

    # -------------------------
    # Backup Type Logic
    # -------------------------
    case "$backup_type" in
        "full")
            log_message "Performing full backup..."
            ;;
        "incremental")
            log_message "Performing incremental backup (only new or modified files)..."
            rsync_options="$rsync_options --update"
            ;;
        "differential")
            log_message "Performing differential backup (files modified in the last $days days)..."

            # Find recently modified files
            find_results=$(find "$src" -type f -mtime -"$days")

            # If no files found, exit early
            if [ -z "$find_results" ]; then
                log_message "No files modified in the last $days days. Nothing to back up."
                return 0
            fi

            # Write list of modified files to temporary file
            temp_file=$(mktemp)
            echo "$find_results" > "$temp_file"

            # Use rsync with file list
            rsync_options="$rsync_options --files-from=$temp_file"
            ;;
    esac

    # -------------------------
    # Perform Backup Operation
    # -------------------------
    if [ "$compress" = true ]; then
        log_message "Creating compressed backup..."

        # Create a temporary directory to stage files
        temp_dir=$(mktemp -d)

        # Copy files to temp directory using rsync
        eval rsync $rsync_options "$src/" "$temp_dir/"

        # Create tar.gz archive from temp directory
        archive_name=$(basename "$src")
        tar -czf "$dst/${archive_name}_backup.tar.gz" -C "$temp_dir" .
        backup_result=$?

        # Clean up
        rm -rf "$temp_dir"

        if [ "$backup_result" -eq 0 ]; then
            log_message "Compressed backup created successfully: $dst/${archive_name}_backup.tar.gz"
        else
            log_message "Error: Failed to create compressed backup"
            return 1
        fi
    else
        # Run rsync directly without compression
        eval rsync $rsync_options "$src/" "$dst/"
        if [ $? -eq 0 ]; then
            log_message "Backup completed successfully"
        else
            log_message "Error: Backup operation failed"
            return 1
        fi
    fi

    # Clean up temp file if differential backup was used
    if [ "$backup_type" = "differential" ]; then
        rm -f "$temp_file"
    fi

    return 0
}

# -----------------------------
# Trigger the backup function
# -----------------------------
perform_backup "$source_dir" "$backup_dir"
backup_status=$?

# -----------------------------
# Log backup completion status
# -----------------------------
if [ "$create_log" = true ]; then
    echo "----------------------------------------" >> "$log_file"
    echo "Backup finished at $(date)" >> "$log_file"
    echo "Status: $([ $backup_status -eq 0 ] && echo "SUCCESS" || echo "FAILED")" >> "$log_file"
fi

# -----------------------------
# Final success or failure message
# -----------------------------
if [ $backup_status -eq 0 ]; then
    log_message "Backup process completed successfully!"
    if [ "$create_log" = true ]; then
        log_message "Log file created: $log_file"
    fi
else
    log_message "Backup process failed. Please check for errors."
fi

exit $backup_status
