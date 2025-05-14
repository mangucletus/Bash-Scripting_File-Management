# File Backup System

A flexible bash script for backing up important files with various backup types and options.

## Overview

This File Backup System script helps you create backups of important directories and files. It supports full, incremental, and differential backups with options for compression, logging, and exclusion patterns.

## Features

- Multiple backup types:
  - Full backup (copies all files)
  - Incremental backup (copies only new or modified files)
  - Differential backup (copies files modified within a specified timeframe)
- Compression option to create .tar.gz archives
- Detailed backup logging
- Timestamped backup directories
- File exclusion patterns
- Simple command-line interface

## Requirements

- Bash shell
- rsync (for efficient file copying)
- tar (for compression)

## How to Use

1. Make the script executable:
   ```
   chmod +x file_backup_system.sh
   ```

2. Run the script with source and destination directories:
   ```
   ./file_backup_system.sh [OPTIONS] <source_directory> <backup_directory>
   ```

## Command Line Options

| Option | Format | Description | Example |
|--------|--------|-------------|---------|
| `-f` | `-f` | Full backup (default) | `-f` |
| `-i` | `-i` | Incremental backup | `-i` |
| `-d` | `-d DAYS` | Differential backup of files modified in the last DAYS days | `-d 7` |
| `-c` | `-c` | Compress the backup into a .tar.gz archive | `-c` |
| `-l` | `-l` | Create a log file of the backup operation | `-l` |
| `-t` | `-t` | Add timestamp to backup directory name | `-t` |
| `-e` | `-e PATTERN` | Exclude files matching PATTERN | `-e "*.tmp"` |
| `-h` | `-h` | Show help message | `-h` |

## Examples

### Simple Full Backup

```bash
./file_backup_system.sh ~/Documents ~/Backups
```

This will copy all files from the Documents directory to the Backups directory.

### Compressed Backup with Timestamp

```bash
./file_backup_system.sh -c -t ~/Pictures ~/Backups
```

This will create a compressed archive of all files in the Pictures directory and store it in a timestamped directory under Backups.

### Incremental Backup with Logging

```bash
./file_backup_system.sh -i -l ~/Projects ~/Backups
```

This will copy only new or modified files from Projects to Backups and create a detailed log file.

### Differential Backup (Last 7 Days)

```bash
./file_backup_system.sh -d 7 -c ~/Documents ~/Backups
```

This will back up only files that were modified in the last 7 days from Documents and compress them.

## Understanding Backup Types

### Full Backup

A full backup copies all files from the source to the destination, regardless of when they were last modified or backed up. This is the simplest and most comprehensive backup type.

### Incremental Backup

An incremental backup copies only files that are new or have been modified since the last backup. This is efficient for regular backups as it minimizes the amount of data transferred.

### Differential Backup

A differential backup copies files that have been modified within a specified time period (e.g., the last 7 days). This is useful when you want to back up recent changes without a full backup history.

## Flow Diagram

```
START
  |
  v
Parse command line options
  |
  v
Check source and destination directories
  |
  v
Set up backup environment:
  - Create destination directory if needed
  - Set up logging if requested
  - Apply timestamp if requested
  |
  v
Determine backup type:
  +----------------+----------------+----------------+
  |                |                |                |
  v                v                v                |
Full backup    Incremental      Differential        |
Copy all files  Copy new/modified  Copy files modified  |
                files only         in last X days     |
  |                |                |                |
  +----------------+----------------+----------------+
  |
  v
Apply options:
  - Compression (tar.gz)
  - Exclusion patterns
  |
  v
Execute backup operation
  |
  v
Log results and clean up
  |
  v
END
```

## Log File Format

If logging is enabled (`-l` option), the script creates a log file with the following information:

```
Backup started at [date and time]
Source: [source directory]
Destination: [backup directory]
Backup type: [full/incremental/differential]
[Additional parameters if applicable]
Compression: [Enabled/Disabled]
----------------------------------------
[Operation messages and file listings]
----------------------------------------
Backup finished at [date and time]
Status: [SUCCESS/FAILED]
```

## Technical Details

### Using rsync

The script uses `rsync` for file copying because it's efficient and provides features like:
- Preserving file attributes and permissions
- Skipping files that haven't changed
- Built-in exclusion patterns
- Progress reporting

### Compression

When compression is enabled (`-c` option), the script:
1. Copies files to a temporary directory
2. Creates a tar.gz archive from those files
3. Places the archive in the backup directory
4. Removes the temporary files

This approach ensures that even large directories can be efficiently compressed.

## Limitations

- The script doesn't manage backup rotation or pruning old backups
- No built-in scheduling (though you can use cron for this)
- Incremental backups don't track which files were previously backed up
- No built-in verification of backup integrity

## Future Improvements

- Add backup verification option
- Implement backup rotation to automatically remove old backups
- Add restore functionality
- Add encryption options for secure backups
- Implement multi-threaded compression for large backups

## Setting Up Scheduled Backups

You can use cron to schedule regular backups. For example, to run a backup every day at 2 AM:

1. Open your crontab:
   ```
   crontab -e
   ```

2. Add a line like:
   ```
   0 2 * * * /path/to/file_backup_system.sh -i -l -t ~/Documents ~/Backups
   ```

This will run an incremental backup with logging and timestamping every day at 2 AM.