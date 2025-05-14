#!/bin/bash

# Automatic File Sorter
# This script organizes files in a folder based on their file extensions

# Check if directory path is provided
if [ $# -eq 0 ]; then
    echo "Please provide a directory path."
    echo "Usage: $0 /path/to/directory"
    exit 1
fi

# Set the source directory from command line argument
source_dir="$1"

# Check if the provided path is a valid directory
if [ ! -d "$source_dir" ]; then
    echo "Error: $source_dir is not a valid directory!"
    exit 1
fi

echo "Starting to organize files in: $source_dir"

# Function to create category folders if they don't exist
create_folders() {
    # Create category folders
    mkdir -p "$source_dir/Documents"
    mkdir -p "$source_dir/Images"
    mkdir -p "$source_dir/Videos"
    mkdir -p "$source_dir/Audio"
    mkdir -p "$source_dir/Archives"
    mkdir -p "$source_dir/Others"
    
    echo "Category folders created successfully."
}

# Function to move files to appropriate folders
sort_files() {
    # Loop through all files in the source directory
    for file in "$source_dir"/*; do
        # Skip if it's a directory
        if [ -d "$file" ]; then
            continue
        fi
        
        # Get the file extension (convert to lowercase for consistency)
        filename=$(basename "$file")
        extension="${filename##*.}"
        extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
        
        # Determine target folder based on file extension
        case "$extension" in
            # Document files
            pdf|doc|docx|txt|rtf|odt|xls|xlsx|ppt|pptx|csv)
                target_dir="$source_dir/Documents"
                ;;
            # Image files
            jpg|jpeg|png|gif|bmp|svg|tiff)
                target_dir="$source_dir/Images"
                ;;
            # Video files
            mp4|mkv|avi|mov|wmv|flv|webm)
                target_dir="$source_dir/Videos"
                ;;
            # Audio files
            mp3|wav|ogg|flac|aac|wma)
                target_dir="$source_dir/Audio"
                ;;
            # Archive files
            zip|rar|tar|gz|7z)
                target_dir="$source_dir/Archives"
                ;;
            # All other files
            *)
                target_dir="$source_dir/Others"
                ;;
        esac
        
        # Move the file to the target directory
        mv "$file" "$target_dir/"
        echo "Moved: $filename to $target_dir"
    done
}

# Main program execution
create_folders
sort_files

echo "File sorting completed successfully!"