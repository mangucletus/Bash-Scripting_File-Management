#!/bin/bash

# Disk Space Analyzer: This script analyzes disk usage and displays folder and file sizes in a tree-like structure.
# It supports sorting, limiting depth, filtering by size, and choosing to show files or only folders.

# Function: show_help
# Displays usage information and help message to guide users on how to use the script
show_help() {
    echo "Disk Space Analyzer - Find what's using your disk space"
    echo ""
    echo "Usage: $0 [OPTIONS] <directory>"
    echo ""
    echo "Options:"
    echo "  -d DEPTH     Maximum depth to display (default: 2)"
    echo "  -n NUMBER    Show top N entries per directory (default: 10)"
    echo "  -s SIZE      Minimum size to display in KB (default: 1)"
    echo "  -f           Include files in the output (default: folders only)"
    echo "  -h           Show this help message and exit"
    echo ""
    echo "Sort Options:"
    echo "  -S           Sort by size (default, largest first)"
    echo "  -N           Sort by name (alphabetically)"
    echo "  -T           Sort by type (directories first)"
    echo ""
    echo "Examples:"
    echo "  $0 /home/user"
    echo "  $0 -d 3 -n 5 -f /var/log"
    echo "  $0 -s 1000 -S ~/Documents"
    echo ""
}

# Function: format_size
# Converts a size in bytes to a human-readable format using KB, MB, GB, or TB
format_size() {
    local size=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0

    # Loop to divide by 1024 until size is small enough or max unit is reached
    while [ $size -ge 1024 ] && [ $unit -lt 4 ]; do
        size=$(($size / 1024))
        unit=$((unit + 1))
    done

    # Output formatted size with the appropriate unit
    echo "$size ${units[$unit]}"
}

# Function: print_indent
# Prints a line with indentation based on folder depth
print_indent() {
    local indent=$1
    local text=$2
    local i=0

    # Print indentation marks for each depth level
    while [ $i -lt $indent ]; do
        echo -n "│   "
        i=$((i + 1))
    done

    # Print the actual content
    echo "$text"
}

# Default values for configurable options
max_depth=2          # Maximum depth to recurse into directories
top_entries=10       # Show only the top N entries per directory
min_size=1           # Minimum size (in KB) for entries to be displayed
include_files=false  # By default, only show folders
sort_by="size"       # Default sorting method
directory=""         # Directory to analyze

# Parse command-line options using getopts
while getopts "d:n:s:fhSNT" opt; do
    case $opt in
        d) max_depth="$OPTARG" ;;   # Set maximum depth
        n) top_entries="$OPTARG" ;; # Set number of entries per directory
        s) min_size="$OPTARG" ;;    # Set minimum size in KB
        f) include_files=true ;;    # Include files in output
        S) sort_by="size" ;;        # Sort by size
        N) sort_by="name" ;;        # Sort by name
        T) sort_by="type" ;;        # Sort by type
        h) show_help; exit 0 ;;     # Display help and exit
        \?) echo "Invalid option: -$OPTARG" >&2; show_help; exit 1 ;;
    esac
done

# Shift positional parameters to get the remaining argument (the directory)
shift $((OPTIND - 1))
directory="$1"

# Validate that a directory argument was provided
if [ -z "$directory" ]; then
    echo "Error: Directory not specified"
    show_help
    exit 1
fi

# Validate that the specified directory actually exists
if [ ! -d "$directory" ]; then
    echo "Error: '$directory' is not a valid directory"
    exit 1
fi

# Create a temporary directory to store intermediate data
temp_dir=$(mktemp -d)
if [ $? -ne 0 ]; then
    echo "Error: Failed to create temporary directory"
    exit 1
fi

# Ensure temporary directory is deleted when the script finishes or exits unexpectedly
trap 'rm -rf "$temp_dir"' EXIT

# Notify user that the analysis has started
echo "Analyzing disk space in: $directory"
echo "This might take a while for large directories..."

# Recursive Function: analyze_directory
# Analyzes the contents of a directory and displays the largest items with indentation
analyze_directory() {
    local dir="$1"
    local current_depth="$2"
    local indent="$3"

    # Stop if maximum depth is exceeded
    if [ "$current_depth" -gt "$max_depth" ]; then
        return
    fi

    # Create a temporary file to store the list of entries
    local entries_file="$temp_dir/entries_$current_depth"
    > "$entries_file"  # Clear or create the file

    # Loop through each item in the directory
    for entry in "$dir"/*; do
        [ -e "$entry" ] || continue  # Skip non-existing entries (e.g., permission denied)

        local name=$(basename "$entry")  # Extract name from full path
        local size=0
        local is_dir=false

        if [ -d "$entry" ]; then
            is_dir=true
            size=$(du -sk "$entry" 2>/dev/null | cut -f1)  # Get directory size in KB
        elif [ -f "$entry" ] && [ "$include_files" = true ]; then
            size=$(ls -sk "$entry" 2>/dev/null | awk '{print $1}')  # Get file size in KB
        else
            continue  # Skip if not a directory or file (or files are excluded)
        fi

        # Skip entries smaller than the defined minimum size
        if [ "$size" -lt "$min_size" ]; then
            continue
        fi

        # Save size, name, path, and type (is_dir) in a temporary file
        echo "$size|$name|$entry|$is_dir" >> "$entries_file"
    done

    # Sort the entries according to the chosen method
    local sorted_file="$temp_dir/sorted_$current_depth"
    case "$sort_by" in
        "size") sort -t'|' -k1 -nr "$entries_file" > "$sorted_file" ;;  # Sort by size descending
        "name") sort -t'|' -k2 "$entries_file" > "$sorted_file" ;;      # Sort alphabetically
        "type") sort -t'|' -k4 -r "$entries_file" > "$sorted_file" ;;   # Sort directories first
    esac

    # Display only the top N entries
    local count=0
    while IFS='|' read -r size name path is_dir; do
        if [ "$count" -ge "$top_entries" ]; then
            break
        fi

        # Convert size from KB to bytes for human-readable formatting
        local formatted_size=$(format_size $(($size * 1024)))

        if [ "$is_dir" = "true" ]; then
            # Show directory with 📁 icon and recurse into it
            print_indent "$indent" "├── 📁 $name [$formatted_size]"
            analyze_directory "$path" $((current_depth + 1)) $((indent + 1))
        else
            # Show file with 📄 icon
            print_indent "$indent" "├── 📄 $name [$formatted_size]"
        fi

        count=$((count + 1))
    done < "$sorted_file"

    # If no entries are found above threshold, show a message
    if [ "$count" -eq 0 ]; then
        print_indent "$indent" "├── (No items larger than $min_size KB)"
    fi
}

# Get total size of the base directory in human-readable format
total_size=$(du -sh "$directory" 2>/dev/null | cut -f1)

# Display header and start the analysis
echo "Directory: $directory"
echo "Total Size: $total_size"
echo "───────────────────────────────────────────────────"
analyze_directory "$directory" 1 0
echo "───────────────────────────────────────────────────"
echo "Analysis completed. Showing entries larger than $min_size KB."
if [ "$max_depth" -lt 99 ]; then
    echo "Limited to depth of $max_depth levels."
fi
echo "Displaying up to $top_entries items per directory."
