#!/bin/bash

# -------------------------------
# Automatic File Sorter Script
# -------------------------------
# This script helps organize files in a specified directory
# into categorized folders based on their file extensions.
# Categories include: Documents, Images, Videos, Audio, Archives, Others.

# -------------------------------
# Step 1: Input Validation
# -------------------------------

# Check if the user has provided a directory path as an argument.
if [ $# -eq 0 ]; then
    echo "Please provide a directory path."
    echo "Usage: $0 /path/to/directory"  # Shows how to use the script
    exit 1  # Exit the script if no directory is provided
fi

# Assign the first command-line argument to the variable 'source_dir'
source_dir="$1"

# Check if the provided path actually exists and is a directory
if [ ! -d "$source_dir" ]; then
    echo "Error: $source_dir is not a valid directory!"
    exit 1  # Exit if the path is not a directory
fi

# Inform the user that file sorting is starting
echo "Starting to organize files in: $source_dir"

# -------------------------------
# Step 2: Folder Creation
# -------------------------------

# Define a function that creates folders for each file category
create_folders() {
    # Use 'mkdir -p' to create folders if they don't exist already
    mkdir -p "$source_dir/Documents"  # For document files
    mkdir -p "$source_dir/Images"     # For image files
    mkdir -p "$source_dir/Videos"     # For video files
    mkdir -p "$source_dir/Audio"      # For audio files
    mkdir -p "$source_dir/Archives"   # For compressed files
    mkdir -p "$source_dir/Others"     # For uncategorized or unknown file types

    echo "Category folders created successfully."
}

# -------------------------------
# Step 3: File Sorting Logic
# -------------------------------

# Define a function to sort files into the correct category folders
sort_files() {
    # Iterate over each item in the source directory
    for file in "$source_dir"/*; do
        # Skip directories, only process files
        if [ -d "$file" ]; then
            continue  # Go to the next item
        fi

        # Extract the filename from the path
        filename=$(basename "$file")

        # Extract the file extension (everything after the last '.')
        extension="${filename##*.}"

        # Convert the extension to lowercase to ensure consistent matching
        extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

        # Decide the destination folder based on the file extension
        case "$extension" in
            # Document files (Word, Excel, PDF, etc.)
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
            # Archive/compressed files
            zip|rar|tar|gz|7z)
                target_dir="$source_dir/Archives"
                ;;
            # Anything else goes into the 'Others' folder
            *)
                target_dir="$source_dir/Others"
                ;;
        esac

        # Move the file to the determined target directory
        mv "$file" "$target_dir/"
        echo "Moved: $filename to $target_dir"
    done
}

# -------------------------------
# Step 4: Execute the Functions
# -------------------------------

create_folders  # First, create all the required category folders
sort_files      # Then, start sorting and moving files

# Inform the user that sorting is complete
echo "File sorting completed successfully!"
