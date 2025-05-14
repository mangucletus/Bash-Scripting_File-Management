#!/bin/bash

# Bulk File Renamer
# This script renames multiple files according to specified patterns

# Function to display help information
show_help() {
    echo "Bulk File Renamer - A tool to rename multiple files at once"
    echo ""
    echo "Usage: $0 [OPTIONS] <directory>"
    echo ""
    echo "Options:"
    echo "  -p PREFIX   Add PREFIX to the beginning of filenames"
    echo "  -s SUFFIX   Add SUFFIX to the end of filenames (before extension)"
    echo "  -n PATTERN  Rename files using a pattern with counter"
    echo "              Use # as placeholder for the counter (e.g., 'file-###')"
    echo "  -d          Add date prefix (YYYY-MM-DD_) to filenames"
    echo "  -r SEARCH REPLACE  Replace SEARCH with REPLACE in filenames"
    echo "  -h          Show this help message and exit"
    echo ""
    echo "Examples:"
    echo "  $0 -p 'vacation_' ~/Pictures"
    echo "  $0 -s '_edited' -d ~/Documents"
    echo "  $0 -n 'photo-###' ~/Pictures"
    echo "  $0 -r ' ' '_' ~/Documents"
    echo ""
}

# Initialize variables
prefix=""
suffix=""
number_pattern=""
add_date=false
search=""
replace=""
directory=""

# Parse command line arguments
while getopts "p:s:n:dr:h" opt; do
    case $opt in
        p) prefix="$OPTARG" ;;
        s) suffix="$OPTARG" ;;
        n) number_pattern="$OPTARG" ;;
        d) add_date=true ;;
        r) search="$OPTARG"; replace="${@:OPTIND:1}"; OPTIND=$((OPTIND + 1)) ;;
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

# Function to rename files with a counter pattern
rename_with_counter() {
    local dir="$1"
    local pattern="$2"
    local count=1
    
    # Get number of digits from pattern (count #'s)
    num_chars=$(echo "$pattern" | grep -o "#" | wc -l)
    
    # Replace # with format specifier for printf
    printf_pattern="${pattern//'#'/%}"
    
    # For each file in the directory
    for file in "$dir"/*; do
        # Skip if it's a directory
        if [ -d "$file" ]; then
            continue
        fi
        
        # Get file extension and base name
        filename=$(basename "$file")
        extension="${filename##*.}"
        
        # Format the counter according to the number of # characters
        formatted_count=$(printf "%0${num_chars}d" $count)
        
        # Apply the pattern with the counter
        new_name=$(printf "$printf_pattern" $formatted_count)
        
        # Add extension back
        new_name="$new_name.$extension"
        
        # Rename the file
        mv "$file" "$dir/$new_name"
        echo "Renamed: $filename -> $new_name"
        
        # Increment counter
        ((count++))
    done
}

# Function to apply prefix, suffix, and date to files
rename_with_affixes() {
    local dir="$1"
    local prefix="$2"
    local suffix="$3"
    local add_date="$4"
    
    # Get current date in YYYY-MM-DD format
    current_date=""
    if [ "$add_date" = true ]; then
        current_date=$(date +"%Y-%m-%d_")
    fi
    
    # For each file in the directory
    for file in "$dir"/*; do
        # Skip if it's a directory
        if [ -d "$file" ]; then
            continue
        fi
        
        # Get file name and extension
        filename=$(basename "$file")
        extension="${filename##*.}"
        basename="${filename%.*}"
        
        # Build new filename
        new_name="${current_date}${prefix}${basename}${suffix}.${extension}"
        
        # Rename the file
        mv "$file" "$dir/$new_name"
        echo "Renamed: $filename -> $new_name"
    done
}

# Function to replace text in filenames
rename_with_replace() {
    local dir="$1"
    local search="$2"
    local replace="$3"
    
    # For each file in the directory
    for file in "$dir"/*; do
        # Skip if it's a directory
        if [ -d "$file" ]; then
            continue
        fi
        
        # Get filename
        filename=$(basename "$file")
        
        # Replace text in filename
        new_name="${filename//$search/$replace}"
        
        # Only rename if there's a change
        if [ "$filename" != "$new_name" ]; then
            mv "$file" "$dir/$new_name"
            echo "Renamed: $filename -> $new_name"
        fi
    done
}

# Perform the renaming based on provided options
echo "Starting file renaming in: $directory"

# Counter-based renaming takes precedence
if [ ! -z "$number_pattern" ]; then
    rename_with_counter "$directory" "$number_pattern"
# Text replacement
elif [ ! -z "$search" ]; then
    rename_with_replace "$directory" "$search" "$replace"
# Affixes (prefix, suffix, date)
else
    rename_with_affixes "$directory" "$prefix" "$suffix" "$add_date"
fi

echo "File renaming completed successfully!"