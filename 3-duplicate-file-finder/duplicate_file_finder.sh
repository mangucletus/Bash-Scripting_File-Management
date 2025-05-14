#!/bin/bash

# Duplicate File Finder: This script finds duplicate files in a directory based on size and content

# Function to display help information
show_help() {
    echo "Duplicate File Finder - Find and manage duplicate files"
    echo ""
    echo "Usage: $0 [OPTIONS] <directory>"
    echo ""
    echo "Options:"
    echo "  -i          Interactive mode (ask what to do with each duplicate)"
    echo "  -d          Automatically delete duplicates (keeps first occurrence)"
    echo "  -m DIR      Move duplicates to specified directory (keeps first occurrence)"
    echo "  -r          Scan directories recursively"
    echo "  -h          Show this help message and exit"
    echo ""
    echo "Examples:"
    echo "  $0 ~/Documents"
    echo "  $0 -r -i ~/Pictures"
    echo "  $0 -d ~/Downloads"
    echo "  $0 -m ~/Duplicates ~/Music"
    echo ""
}

# Initialize variables
interactive=false
auto_delete=false
move_dir=""
recursive=false
directory=""

# Parse command line arguments
while getopts "idm:rh" opt; do
    case $opt in
        i) interactive=true ;;
        d) auto_delete=true ;;
        m) move_dir="$OPTARG" ;;
        r) recursive=true ;;
        h) show_help; exit 0 ;;
        \?) echo "Invalid option: -$OPTARG" >&2; show_help; exit 1 ;;
    esac
done

# Get directory from the remaining arguments
shift $((OPTIND - 1))
directory="$1"

# Check if directory is provided and valid
if [ -z "$directory" ]; then
    echo "Error: Directory not specified"
    show_help
    exit 1
fi

if [ ! -d "$directory" ]; then
    echo "Error: '$directory' is not a valid directory"
    exit 1
fi

# Check if move directory exists or create it
if [ ! -z "$move_dir" ] && [ ! -d "$move_dir" ]; then
    echo "Creating directory for duplicates: $move_dir"
    mkdir -p "$move_dir"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create directory '$move_dir'"
        exit 1
    fi
fi

# Create a temporary directory for our processing
temp_dir=$(mktemp -d)
if [ $? -ne 0 ]; then
    echo "Error: Failed to create temporary directory"
    exit 1
fi

# Clean up the temporary directory when the script exits
trap 'rm -rf "$temp_dir"' EXIT

echo "Starting duplicate file scan in: $directory"
echo "This might take a while depending on the number and size of files..."

# Function to find files
find_files() {
    local search_dir="$1"
    
    if [ "$recursive" = true ]; then
        find "$search_dir" -type f
    else
        find "$search_dir" -maxdepth 1 -type f
    fi
}

# Step 1: Group files by size (first level filter)
echo "Step 1: Grouping files by size..."
find_files "$directory" | while read file; do
    # Get file size in bytes
    size=$(stat -c %s "$file")
    
    # Add filename to the size group file
    echo "$file" >> "$temp_dir/size_$size"
done

# Step 2: For each size group with more than one file, compare by md5 hash
echo "Step 2: Comparing file contents with MD5 hashes..."
duplicates_found=0

for size_file in "$temp_dir"/size_*; do
    # Skip if file doesn't exist (no files of this size)
    [ -f "$size_file" ] || continue
    
    # If there's only one file of this size, it can't be a duplicate
    if [ $(wc -l < "$size_file") -le 1 ]; then
        continue
    fi
    
    # Process each file in this size group
    while read file; do
        # Calculate MD5 hash
        hash=$(md5sum "$file" | cut -d ' ' -f 1)
        
        # Store hash -> file mapping
        echo "$file" >> "$temp_dir/hash_$hash"
    done < "$size_file"
done

# Step 3: Report and handle duplicates
echo "Step 3: Processing duplicate files..."

for hash_file in "$temp_dir"/hash_*; do
    # Skip if file doesn't exist
    [ -f "$hash_file" ] || continue
    
    # If there's only one file with this hash, it's not a duplicate
    if [ $(wc -l < "$hash_file") -le 1 ]; then
        continue
    fi
    
    # Get the list of duplicate files
    duplicates=($(cat "$hash_file"))
    original_file="${duplicates[0]}"
    
    echo "Found duplicate files (hash: $(basename "$hash_file" | cut -d '_' -f 2)):"
    echo "  Original: $original_file"
    
    # Process each duplicate (skip the first one which is our "original")
    for ((i=1; i<${#duplicates[@]}; i++)); do
        duplicate="${duplicates[$i]}"
        echo "  Duplicate: $duplicate"
        
        # Handle the duplicate based on options
        if [ "$interactive" = true ]; then
            echo "What would you like to do with this duplicate?"
            echo "  [k]eep - Keep the duplicate"
            echo "  [d]elete - Delete the duplicate"
            echo "  [m]ove - Move the duplicate to $move_dir"
            read -p "Enter your choice [k/d/m]: " choice
            
            case "$choice" in
                d|D) rm "$duplicate"; echo "  Deleted: $duplicate" ;;
                m|M) 
                    if [ -z "$move_dir" ]; then
                        echo "  Move directory not specified. Keeping the file."
                    else
                        mv "$duplicate" "$move_dir/"
                        echo "  Moved to: $move_dir/$(basename "$duplicate")"
                    fi
                    ;;
                *) echo "  Keeping: $duplicate" ;;
            esac
        elif [ "$auto_delete" = true ]; then
            rm "$duplicate"
            echo "  Deleted: $duplicate"
        elif [ ! -z "$move_dir" ]; then
            mv "$duplicate" "$move_dir/"
            echo "  Moved to: $move_dir/$(basename "$duplicate")"
        fi
        
        duplicates_found=$((duplicates_found + 1))
    done
    echo ""
done

# Final report
if [ $duplicates_found -eq 0 ]; then
    echo "No duplicate files found in $directory"
else
    echo "Found $duplicates_found duplicate files in $directory"
    
    if [ "$auto_delete" = true ]; then
        echo "All duplicates have been deleted"
    elif [ ! -z "$move_dir" ]; then
        echo "All duplicates have been moved to $move_dir"
    elif [ "$interactive" = false ]; then
        echo "No action taken. Use -d to delete or -m to move duplicates."
    fi
fi

echo "Duplicate file scanning completed successfully!"