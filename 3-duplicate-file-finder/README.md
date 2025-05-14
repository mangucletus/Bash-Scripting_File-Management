# Duplicate File Finder

A bash script that identifies duplicate files and offers options to manage them.

## Overview

The Duplicate File Finder bash script that helps you find and manage duplicate files on your system. It uses a two-step process to efficiently identify duplicates: first grouping files by size, then comparing their content using MD5 hashes.

## Features

- Find duplicate files based on content (not just filenames)
- Works with any file type
- Optional recursive directory scanning
- Interactive mode to decide what to do with each duplicate
- Options to automatically delete or move duplicates
- Preserves the first occurrence of each file
- Detailed reporting of actions taken

## How to Use

1. Make the script executable:
   ```
   chmod +x duplicate_finder.sh
   ```

2. Run the script with the target directory:
   ```
   ./duplicate_finder.sh [OPTIONS] /path/to/directory
   ```

## Command Line Options

| Option | Format | Description | Example |
|--------|--------|-------------|---------|
| `-i` | `-i` | Interactive mode | `-i` |
| `-d` | `-d` | Auto-delete duplicates | `-d` |
| `-m` | `-m DIR` | Move duplicates to DIR | `-m ~/Duplicates` |
| `-r` | `-r` | Scan recursively | `-r` |
| `-h` | `-h` | Show help message | `-h` |

## Examples

### Basic scan (report only)

```bash
./duplicate_finder.sh ~/Documents
```

This will scan the Documents folder and report any duplicates found, but won't take any action.

### Interactive mode with recursive scanning

```bash
./duplicate_finder.sh -r -i ~/Pictures
```

This will scan the Pictures folder and all its subdirectories, then ask what you want to do with each duplicate found.

### Auto-delete duplicates

```bash
./duplicate_finder.sh -d ~/Downloads
```

This will scan the Downloads folder and automatically delete any duplicate files, keeping only the first occurrence of each.

### Move duplicates to another folder

```bash
./duplicate_finder.sh -m ~/Duplicates ~/Music
```

This will scan the Music folder and move any duplicate files to the Duplicates folder.

## How It Works

The script uses a multi-step approach to efficiently find duplicates:

1. **Size Comparison**: First, files are grouped by their size. Only files with the same size can be duplicates.
2. **Content Comparison**: Files of the same size are then compared using MD5 hash checksums of their content.
3. **Results Processing**: Files with identical MD5 hashes are reported as duplicates.

This approach is much more efficient than comparing every file against every other file, especially for large directories.

## Flow Diagram

```
START
  |
  v
Parse command line options
  |
  v
Validate directories
  |
  v
Create temporary workspace
  |
  v
Group files by size
  |
  v
For each size group with multiple files:
  |  Calculate MD5 hashes
  |  Group files by hash
  |
  v
For each hash group with multiple files:
  |  Mark files as duplicates
  |  Process according to options:
  |    - Report only
  |    - Interactive processing
  |    - Auto-delete
  |    - Move to directory
  |
  v
Display summary
  |
  v
Clean up temporary files
  |
  v
END
```

## Technical Details

### Determining File Uniqueness

The script uses a two-step process to identify duplicates:

1. **File Size**: Using the `stat -c %s` command to get file size in bytes
2. **File Content**: Using the `md5sum` command to generate a hash of the file content

This approach minimizes the number of expensive content comparisons needed.

### Temporary Files Structure

The script creates a temporary directory with two types of files:
- `size_XXXXX`: Lists of files with the same size (where XXXXX is the size in bytes)
- `hash_XXXXX`: Lists of files with the same MD5 hash (where XXXXX is the hash)

### Memory and Performance Considerations

- For very large directories, the script may take a considerable amount of time
- The script processes files in batches by size to minimize memory usage
- Recursive scanning can significantly increase processing time

## Limitations

- The script doesn't check for hard links or symbolic links
- Very large files may slow down processing
- The MD5 algorithm has an extremely small theoretical chance of hash collisions
- No built-in way to ignore certain file types or directories

## Future Improvements

- Add option to list duplicates in CSV format
- Add ability to exclude certain directories or file types
- Implement parallel processing for faster scanning
- Add progress indicators for large directories
- Support for comparing files across multiple source directories