#!/bin/bash

# Disk Space Analyzer: This script analyzes disk usage and displays folder and file sizes in a tree-like structure

# Function to display help information
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

# Function to convert bytes to human readable format
format_size() {
    local size=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    
    while [ $size -ge 1024 ] && [ $unit -lt 4 ]; do
        size=$(($size / 1024))
        unit=$((unit + 1))
    done
    
    echo "$size ${units[$unit]}"
}

# Function to print indented text
print_indent() {
    local indent=$1
    local text=$2
    local i=0
    
    while [ $i -lt $indent ]; do
        echo -n "│   "
        i=$((i + 1))
    done
    
    echo "$text"
}

# Initialize variables
max_depth=2
top_entries=10
min_size=1
include_files=false
sort_by="size"
directory=""

# Parse command line arguments
while getopts "d:n:s:fhSNT" opt; do
    case $opt in
        d) max_depth="$OPTARG" ;;
        n) top_entries="$OPTARG" ;;
        s) min_size="$OPTARG" ;;
        f) include_files=true ;;
        S) sort_by="size" ;;
        N) sort_by="name" ;;
        T) sort_by="type" ;;
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

# Create temporary directory for our processing
temp_dir=$(mktemp -d)
if [ $? -ne 0 ]; then
    echo "Error: Failed to create temporary directory"
    exit 1
fi

# Clean up temporary directory when script exits
trap 'rm -rf "$temp_dir"' EXIT

echo "Analyzing disk space in: $directory"
echo "This might take a while for large directories..."

# Function to analyze and display disk usage recursively
analyze_directory() {
    local dir="$1"
    local current_depth="$2"
    local indent="$3"
    
    # If we've reached max depth, stop recursion
    if [ "$current_depth" -gt "$max_depth" ]; then
        return
    fi
    
    # Create temporary file for storing entries
    local entries_file="$temp_dir/entries_$current_depth"
    > "$entries_file"
    
    # Process each entry in the directory
    for entry in "$dir"/*; do
        # Skip if entry doesn't exist (e.g., permission issues)
        [ -e "$entry" ] || continue
        
        # Get entry name
        local name=$(basename "$entry")
        
        # Get size and determine if it's a directory
        local size=0
        local is_dir=false
        
        if [ -d "$entry" ]; then
            is_dir=true
            # Use du to get directory size
            size=$(du -sk "$entry" 2>/dev/null | cut -f1)
        elif [ -f "$entry" ] && [ "$include_files" = true ]; then
            # Use ls to get file size in KB
            size=$(ls -sk "$entry" 2>/dev/null | awk '{print $1}')
        else
            continue
        fi
        
        # Skip entries smaller than minimum size
        if [ "$size" -lt "$min_size" ]; then
            continue
        fi
        
        # Append to entries file for sorting
        echo "$size|$name|$entry|$is_dir" >> "$entries_file"
    done
    
    # Sort entries based on sort option
    local sorted_file="$temp_dir/sorted_$current_depth"
    case "$sort_by" in
        "size")
            # Sort by size (largest first)
            sort -t'|' -k1 -nr "$entries_file" > "$sorted_file"
            ;;
        "name")
            # Sort by name (alphabetically)
            sort -t'|' -k2 "$entries_file" > "$sorted_file"
            ;;
        "type")
            # Sort by type (directories first)
            sort -t'|' -k4 -r "$entries_file" > "$sorted_file"
            ;;
    esac
    
    # Display top entries
    local count=0
    while IFS='|' read -r size name path is_dir; do
        # Limit to top N entries
        if [ "$count" -ge "$top_entries" ]; then
            break
        fi
        
        # Format size for display
        local formatted_size=$(format_size $(($size * 1024)))
        
        # Display entry with appropriate symbol and size
        if [ "$is_dir" = "true" ]; then
            print_indent "$indent" "├── 📁 $name [$formatted_size]"
            
            # Recursively analyze subdirectories
            analyze_directory "$path" $((current_depth + 1)) $((indent + 1))
        else
            print_indent "$indent" "├── 📄 $name [$formatted_size]"
        fi
        
        count=$((count + 1))
    done < "$sorted_file"
    
    # If no entries were displayed, show a message
    if [ "$count" -eq 0 ]; then
        print_indent "$indent" "├── (No items larger than $min_size KB)"
    fi
}

# Get total size of starting directory
total_size=$(du -sh "$directory" 2>/dev/null | cut -f1)

# Display header and start analysis
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