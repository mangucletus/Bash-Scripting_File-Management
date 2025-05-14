#!/bin/bash

# File Backup System: This script backs up files from source to destination with various options

# Function to display help information
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
    echo "Examples:"
    echo "  $0 ~/Documents ~/Backups"
    echo "  $0 -c -t ~/Pictures ~/Backups"
    echo "  $0 -i -l ~/Projects ~/Backups"
    echo "  $0 -d 7 -c ~/Documents ~/Backups"
    echo ""
}

# Initialize variables
backup_type="full"
days=0
compress=false
create_log=false
add_timestamp=false
exclude_pattern=""
source_dir=""
backup_dir=""

# Parse command line arguments
while getopts "fid:cle:th" opt; do
    case $opt in
        f) backup_type="full" ;;
        i) backup_type="incremental" ;;
        d) backup_type="differential"; days="$OPTARG" ;;
        c) compress=true ;;
        l) create_log=true ;;
        t) add_timestamp=true ;;
        e) exclude_pattern="$OPTARG" ;;
        h) show_help; exit 0 ;;
        \?) echo "Invalid option: -$OPTARG" >&2; show_help; exit 1 ;;
    esac
done

# Get source and backup directories from remaining arguments
shift $((OPTIND - 1))
source_dir="$1"
backup_dir="$2"

# Check if directories are provided
if [ -z "$source_dir" ] || [ -z "$backup_dir" ]; then
    echo "Error: Source and backup directories must be specified"
    show_help
    exit 1
fi

# Check if source directory exists
if [ ! -d "$source_dir" ]; then
    echo "Error: Source directory '$source_dir' does not exist"
    exit 1
fi

# Add timestamp to backup directory if requested
if [ "$add_timestamp" = true ]; then
    timestamp=$(date +"%Y%m%d_%H%M%S")
    backup_dir="${backup_dir}_${timestamp}"
fi

# Create backup directory if it doesn't exist
if [ ! -d "$backup_dir" ]; then
    mkdir -p "$backup_dir"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create backup directory '$backup_dir'"
        exit 1
    fi
fi

# Initialize log file if requested
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

# Log function
log_message() {
    local message="$1"
    echo "$message"
    if [ "$create_log" = true ]; then
        echo "$message" >> "$log_file"
    fi
}

log_message "Starting backup from '$source_dir' to '$backup_dir'"
log_message "Backup type: $backup_type"

# Function to perform the backup based on type
perform_backup() {
    local src="$1"
    local dst="$2"
    local backup_files=()
    local rsync_options="-a --info=progress2"
    
    # Add exclude pattern if specified
    if [ ! -z "$exclude_pattern" ]; then
        rsync_options="$rsync_options --exclude='$exclude_pattern'"
    fi
    
    # Configure rsync based on backup type
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
            
            # Find files modified in the last X days
            find_results=$(find "$src" -type f -mtime -"$days")
            
            # If no files found, log and exit
            if [ -z "$find_results" ]; then
                log_message "No files modified in the last $days days. Nothing to back up."
                return 0
            fi
            
            # Create a temporary file with the list of files to back up
            temp_file=$(mktemp)
            echo "$find_results" > "$temp_file"
            rsync_options="$rsync_options --files-from=$temp_file"
            ;;
    esac
    
    # Perform the actual backup using rsync
    if [ "$compress" = true ]; then
        log_message "Creating compressed backup..."
        
        # Create a temporary directory for files before compression
        temp_dir=$(mktemp -d)
        
        # First copy files to temp directory
        eval rsync $rsync_options "$src/" "$temp_dir/"
        
        # Create archive name
        archive_name=$(basename "$src")
        
        # Compress the files
        tar -czf "$dst/${archive_name}_backup.tar.gz" -C "$temp_dir" .
        backup_result=$?
        
        # Clean up temp directory
        rm -rf "$temp_dir"
        
        if [ "$backup_result" -eq 0 ]; then
            log_message "Compressed backup created successfully: $dst/${archive_name}_backup.tar.gz"
        else
            log_message "Error: Failed to create compressed backup"
            return 1
        fi
    else
        # Regular backup without compression
        eval rsync $rsync_options "$src/" "$dst/"
        if [ $? -eq 0 ]; then
            log_message "Backup completed successfully"
        else
            log_message "Error: Backup operation failed"
            return 1
        fi
    fi
    
    # Clean up any temporary files
    if [ "$backup_type" = "differential" ]; then
        rm -f "$temp_file"
    fi
    
    return 0
}

# Perform the backup
perform_backup "$source_dir" "$backup_dir"
backup_status=$?

# Final log entry
if [ "$create_log" = true ]; then
    echo "----------------------------------------" >> "$log_file"
    echo "Backup finished at $(date)" >> "$log_file"
    echo "Status: $([ $backup_status -eq 0 ] && echo "SUCCESS" || echo "FAILED")" >> "$log_file"
fi

# Final status message
if [ $backup_status -eq 0 ]; then
    log_message "Backup process completed successfully!"
    if [ "$create_log" = true ]; then
        log_message "Log file created: $log_file"
    fi
else
    log_message "Backup process failed. Please check for errors."
fi

exit $backup_status