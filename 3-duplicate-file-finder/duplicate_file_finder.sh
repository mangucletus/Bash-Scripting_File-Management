#!/bin/bash

# Duplicate File Finder: This script finds duplicate files in a directory
# by grouping them first by size, then comparing their contents using MD5 checksums.

# Function: Display help information and usage examples
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

# Initialize default option values
interactive=false    # Whether to prompt user for action on each duplicate
auto_delete=false    # Whether to automatically delete duplicates
move_dir=""          # Directory to move duplicates to, if specified
recursive=false      # Whether to scan subdirectories recursively
directory=""         # Target directory to scan for duplicates

# Parse command line options using getopts
while getopts "idm:rh" opt; do
    case $opt in
        i) interactive=true ;;          # Enable interactive mode
        d) auto_delete=true ;;          # Enable automatic deletion of duplicates
        m) move_dir="$OPTARG" ;;        # Set target directory to move duplicates
        r) recursive=true ;;            # Enable recursive directory scanning
        h) show_help; exit 0 ;;         # Show help and exit
        \?) echo "Invalid option: -$OPTARG" >&2; show_help; exit 1 ;; # Handle unknown options
    esac
done

# Get the positional argument after options (the target directory)
shift $((OPTIND - 1))
directory="$1"

# Validate directory argument
if [ -z "$directory" ]; then
    echo "Error: Directory not specified"
    show_help
    exit 1
fi

if [ ! -d "$directory" ]; then
    echo "Error: '$directory' is not a valid directory"
    exit 1
fi

# If a move directory is specified, ensure it exists or create it
if [ ! -z "$move_dir" ] && [ ! -d "$move_dir" ]; then
    echo "Creating directory for duplicates: $move_dir"
    mkdir -p "$move_dir"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create directory '$move_dir'"
        exit 1
    fi
fi

# Create a temporary directory for intermediate files
temp_dir=$(mktemp -d)
if [ $? -ne 0 ]; then
    echo "Error: Failed to create temporary directory"
    exit 1
fi

# Ensure temporary files are cleaned up when the script exits
trap 'rm -rf "$temp_dir"' EXIT

echo "Starting duplicate file scan in: $directory"
echo "This might take a while depending on the number and size of files..."

# Function: Find all files in the target directory
# Supports optional recursive search
find_files() {
    local search_dir="$1"
    
    if [ "$recursive" = true ]; then
        find "$search_dir" -type f   # Include subdirectories
    else
        find "$search_dir" -maxdepth 1 -type f   # Only current directory
    fi
}

# Step 1: Group files by their size in bytes
echo "Step 1: Grouping files by size..."
find_files "$directory" | while read file; do
    size=$(stat -c %s "$file")              # Get file size in bytes
    echo "$file" >> "$temp_dir/size_$size" # Append filename to a size group file
done

# Step 2: Within each size group, compare files using MD5 checksums
echo "Step 2: Comparing file contents with MD5 hashes..."
duplicates_found=0

for size_file in "$temp_dir"/size_*; do
    [ -f "$size_file" ] || continue        # Skip if the file doesn't exist

    if [ $(wc -l < "$size_file") -le 1 ]; then
        continue    # Skip groups with only one file
    fi

    while read file; do
        hash=$(md5sum "$file" | cut -d ' ' -f 1)       # Compute MD5 hash
        echo "$file" >> "$temp_dir/hash_$hash"         # Group by hash
    done < "$size_file"
done

# Step 3: Process the groups of duplicate files
echo "Step 3: Processing duplicate files..."

for hash_file in "$temp_dir"/hash_*; do
    [ -f "$hash_file" ] || continue

    if [ $(wc -l < "$hash_file") -le 1 ]; then
        continue    # Skip unique hashes
    fi

    # Read duplicate files into an array
    duplicates=($(cat "$hash_file"))
    original_file="${duplicates[0]}"   # First file is considered the original

    echo "Found duplicate files (hash: $(basename "$hash_file" | cut -d '_' -f 2)):"
    echo "  Original: $original_file"

    # Process each duplicate file (excluding the original)
    for ((i=1; i<${#duplicates[@]}; i++)); do
        duplicate="${duplicates[$i]}"
        echo "  Duplicate: $duplicate"

        if [ "$interactive" = true ]; then
            # Prompt user for action
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

        duplicates_found=$((duplicates_found + 1))   # Count duplicates handled
    done
    echo ""
done

# Final summary report
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
