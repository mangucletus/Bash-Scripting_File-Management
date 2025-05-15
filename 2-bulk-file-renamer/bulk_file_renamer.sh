#!/bin/bash

# Bulk File Renamer
# This script renames multiple files in a directory using different options like:
# adding prefixes, suffixes, replacing text, numbering, and adding date stamps.

# Function to display help information for users
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

# Initialize default values for all options
prefix=""
suffix=""
number_pattern=""
add_date=false
search=""
replace=""
directory=""

# Parse command-line options using getopts
# Each case handles a different flag passed to the script
while getopts "p:s:n:dr:h" opt; do
    case $opt in
        p) prefix="$OPTARG" ;;                                   # -p: Set the prefix string
        s) suffix="$OPTARG" ;;                                   # -s: Set the suffix string
        n) number_pattern="$OPTARG" ;;                           # -n: Set the counter pattern
        d) add_date=true ;;                                      # -d: Enable date prefix
        r) search="$OPTARG"; replace="${@:OPTIND:1}"; OPTIND=$((OPTIND + 1)) ;;  # -r: Set search and replace terms
        h) show_help; exit 0 ;;                                  # -h: Display help and exit
        \?) echo "Invalid option: -$OPTARG" >&2; show_help; exit 1 ;; # Invalid flag handling
    esac
done

# Remove parsed options, leaving the directory path
shift $((OPTIND - 1))
directory="$1"

# Validate the directory path
if [ -z "$directory" ]; then
    echo "Error: Directory not specified"
    show_help
    exit 1
fi

if [ ! -d "$directory" ]; then
    echo "Error: '$directory' is not a valid directory"
    exit 1
fi

# Function to rename files based on a numbering pattern
rename_with_counter() {
    local dir="$1"
    local pattern="$2"
    local count=1

    # Count how many '#' symbols exist to determine digit width
    num_chars=$(echo "$pattern" | grep -o "#" | wc -l)

    # Convert each '#' to '%' for printf formatting (e.g., "file-%03d")
    printf_pattern="${pattern//'#'/%}"

    # Iterate over files in the directory
    for file in "$dir"/*; do
        if [ -d "$file" ]; then
            continue  # Skip directories
        fi

        filename=$(basename "$file")
        extension="${filename##*.}"  # Get the file extension

        # Format the counter value with zero-padding
        formatted_count=$(printf "%0${num_chars}d" $count)

        # Generate new filename with formatted counter
        new_name=$(printf "$printf_pattern" $formatted_count)
        new_name="$new_name.$extension"

        mv "$file" "$dir/$new_name"  # Rename the file
        echo "Renamed: $filename -> $new_name"

        ((count++))  # Increment the counter
    done
}

# Function to apply prefix, suffix, and optional date to filenames
rename_with_affixes() {
    local dir="$1"
    local prefix="$2"
    local suffix="$3"
    local add_date="$4"

    current_date=""
    if [ "$add_date" = true ]; then
        current_date=$(date +"%Y-%m-%d_")  # Get today's date
    fi

    for file in "$dir"/*; do
        if [ -d "$file" ]; then
            continue  # Skip directories
        fi

        filename=$(basename "$file")
        extension="${filename##*.}"    # Extract extension
        basename="${filename%.*}"      # Extract filename without extension

        # Build new filename using affixes and optional date
        new_name="${current_date}${prefix}${basename}${suffix}.${extension}"

        mv "$file" "$dir/$new_name"  # Rename file
        echo "Renamed: $filename -> $new_name"
    done
}

# Function to replace substrings in filenames
rename_with_replace() {
    local dir="$1"
    local search="$2"
    local replace="$3"

    for file in "$dir"/*; do
        if [ -d "$file" ]; then
            continue  # Skip directories
        fi

        filename=$(basename "$file")
        new_name="${filename//$search/$replace}"  # Replace all instances

        if [ "$filename" != "$new_name" ]; then
            mv "$file" "$dir/$new_name"  # Rename only if a change occurs
            echo "Renamed: $filename -> $new_name"
        fi
    done
}

# Begin the renaming process
echo "Starting file renaming in: $directory"

# Apply renaming logic based on user input priority:
# 1. Number pattern (overrides all others)
# 2. Text replacement
# 3. Prefix, suffix, and/or date
if [ ! -z "$number_pattern" ]; then
    rename_with_counter "$directory" "$number_pattern"
elif [ ! -z "$search" ]; then
    rename_with_replace "$directory" "$search" "$replace"
else
    rename_with_affixes "$directory" "$prefix" "$suffix" "$add_date"
fi

echo "File renaming completed successfully!"
