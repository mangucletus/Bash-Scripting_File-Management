# File Sync Utility Documentation

## Overview

This File Sync Utility is a bash script that provides two-way synchronization between two folders. It compares files based on their modification times and content checksums, then copies newer files in both directions to keep folders in sync.

## Features

- Two-way synchronization (changes from both folders are propagated)
- Conflict detection and resolution
- Automatic backup of conflicted files
- Detailed logging
- Dry-run mode to preview changes without applying them
- Force mode to automatically resolve conflicts
- Support for nested directory structures

## Requirements

- Bash shell
- `find`, `md5sum`, and `stat` commands
- File read/write permissions in both directories

## Installation

1. Download the `file_sync.sh` script to your computer
2. Make it executable:
   ```bash
   chmod +x file_sync.sh
   ```

## Usage

### Basic Command Structure

```bash
./file_sync.sh [source_folder] [destination_folder] [options]
```

### Available Options

| Option | Description |
|--------|-------------|
| `--dry-run` | Show what would be done without making actual changes |
| `--force` | Automatically resolve conflicts by preferring source files |
| `--help` | Display help information |

### Examples

Basic synchronization:
```bash
./file_sync.sh ~/Documents/folder1 ~/Documents/folder2
```

Preview changes without modifying files:
```bash
./file_sync.sh ~/Documents/folder1 ~/Documents/folder2 --dry-run
```

Force synchronization (auto-resolve conflicts):
```bash
./file_sync.sh ~/Documents/folder1 ~/Documents/folder2 --force
```

## How It Works

### Synchronization Process

1. The script first scans the source directory for all files
2. For each file, it compares it with the corresponding file in the destination directory
3. Based on modification times and content checksums, it determines:
   - If files are identical (no action needed)
   - If source file is newer (copy to destination)
   - If destination file is newer (copy to source)
   - If both files have been modified (conflict)
4. It then scans the destination directory for files that don't exist in the source
5. All actions are logged to both the console and a log file

### File Comparison Logic

The script uses a combination of existence checks, modification times, and MD5 checksums to determine the state of files:

```
┌───────────────┐     ┌───────────────┐
│ Source File   │     │  Dest File    │
└───────┬───────┘     └───────┬───────┘
        │                     │
        │   ┌───────────────┐ │
        └───┤  Both exist?  ├─┘
            └───────┬───────┘
                    │
         ┌──────────┴─────────┐
         │                    │
┌────────▼───────┐   ┌────────▼───────┐
│ Only one exists │   │  Compare MD5   │
└────────┬───────┘   └────────┬───────┘
         │                    │
┌────────▼───────┐   ┌────────▼───────┐
│  Copy missing  │   │ Files differ?  │
│     file      │   └────────┬───────┘
└────────────────┘            │
                    ┌─────────┴─────────┐
                    │                   │
           ┌────────▼───────┐  ┌────────▼───────┐
           │Compare mod time│  │Files identical │
           └────────┬───────┘  └────────────────┘
                    │
        ┌───────────┴────────────┐
        │                        │
┌───────▼────────┐      ┌────────▼───────┐
│ Source newer   │      │  Dest newer    │
└───────┬────────┘      └────────┬───────┘
        │                        │
┌───────▼────────┐      ┌────────▼───────┐
│Copy to dest    │      │Copy to source  │
└────────────────┘      └────────────────┘
```

### Conflict Resolution

When a conflict is detected (both files modified since last sync):

1. A backup of the destination file is automatically created
2. If in force mode, the source file is used
3. If in interactive mode, the user is prompted to choose:
   - Keep source version
   - Keep destination version
   - Skip this file

## Logging

All actions are logged to both the console and a log file (`file_sync.log`) with timestamps and severity levels:

- `INFO`: Normal operations
- `WARNING`: Potential issues that were handled
- `ERROR`: Failed operations or critical issues

Example log entry:
```
[2025-05-14 10:15:23] [INFO] Copied file to destination: /path/to/destination/file.txt
```

## Limitations and Considerations

- **Performance**: For large directories with many files, the script may take significant time to run
- **Permissions**: The script must have read/write access to both directories
- **Binary Files**: While the script can sync binary files, conflict resolution is better suited for text files
- **Network Drives**: Syncing across network drives may be slow and more error-prone
- **Symbolic Links**: The current implementation doesn't handle symbolic links specially
- **Hidden Files**: Files that start with a dot (.) are ignored by default

## Error Handling

The script includes error handling for common scenarios:

- Non-existent directories
- Permission issues
- Failed file operations

Each error is logged with details to help diagnose the issue.

## Best Practices

1. **Start with Dry Run**: Always use `--dry-run` first to see what changes would be made
2. **Regular Syncs**: Frequent synchronization reduces the chance of conflicts
3. **Backup First**: Before first sync, consider backing up both directories
4. **Avoid Syncing System Files**: Don't use this utility for system directories
5. **Check Logs**: Review the `file_sync.log` file after each run

## Advanced Usage Scenarios

### Scheduled Synchronization

You can set up a cron job to run the sync at regular intervals:

```bash
# Run sync every hour
0 * * * * /path/to/file_sync.sh /path/to/source /path/to/destination --force >> /path/to/cron.log 2>&1
```

### One-way Sync Alternative

If you need one-way sync (similar to backup), you can use the script with `--force` option and always use the same source and destination order.

## Troubleshooting

| Issue | Possible Solution |
|-------|-------------------|
| "Source directory does not exist" | Check the path and permissions |
| "Failed to create destination directory" | Check write permissions in parent directory |
| "Failed to copy" | Check file permissions and disk space |
| Script is very slow | Reduce the number of files or use more efficient tools for large directories |
| Too many conflicts | Sync more frequently or reconsider your workflow |

## Future Improvements

- Add exclusion patterns for files/directories
- Implement file deletion syncing
- Add compression for network transfers
- Store last sync state to improve conflict detection
- Add progress indicators for large directories
- Support for remote syncing via SSH