# Bulk File Renamer

A flexible bash script for renaming multiple files using various patterns and rules.

## Overview

The Bulk File Renamer is a bash script that helps you rename multiple files at once using prefixes, suffixes, counters, dates, or search-and-replace patterns.

## Features

- Add prefixes to filenames
- Add suffixes to filenames (preserving extensions)
- Number files sequentially using customizable patterns
- Add date prefixes in YYYY-MM-DD format
- Replace specific text in filenames
- Combine multiple renaming options
- Preserves file extensions

## How to Use

1. Make the script executable:
   ```
   chmod +x bulk_renamer.sh
   ```

2. Run the script with the desired options:
   ```
   ./bulk_renamer.sh [OPTIONS] <directory>
   ```

## Command Line Options

| Option | Format | Description | Example |
|--------|--------|-------------|---------|
| `-p` | `-p PREFIX` | Add prefix to filenames | `-p "vacation_"` |
| `-s` | `-s SUFFIX` | Add suffix before extension | `-s "_edited"` |
| `-n` | `-n PATTERN` | Rename using pattern with counter | `-n "photo-###"` |
| `-d` | `-d` | Add date prefix (YYYY-MM-DD_) | `-d` |
| `-r` | `-r SEARCH REPLACE` | Replace text in filenames | `-r " " "_"` |
| `-h` | `-h` | Show help message | `-h` |

## Demo | Example

### Adding a prefix to all files

```bash
./bulk_renamer.sh -p "vacation_" ~/Pictures
```

Before:
```
beach.jpg
mountain.jpg
sunset.jpg
```

After:
```
vacation_beach.jpg
vacation_mountain.jpg
vacation_sunset.jpg
```

### Adding a suffix and date to filenames

```bash
./bulk_renamer.sh -s "_edited" -d ~/Documents
```

Before:
```
report.docx
notes.txt
```

After:
```
2025-05-14_report_edited.docx
2025-05-14_notes_edited.txt
```

### Numbering files sequentially

```bash
./bulk_renamer.sh -n "photo-###" ~/Pictures
```

Before:
```
IMG_1234.jpg
DSC_5678.jpg
DCIM_9012.jpg
```

After:
```
photo-001.jpg
photo-002.jpg
photo-003.jpg
```

### Replacing spaces with underscores

```bash
./bulk_renamer.sh -r " " "_" ~/Documents
```

Before:
```
my document.docx
meeting notes.txt
```

After:
```
my_document.docx
meeting_notes.txt
```

## Skeleton Flow Diagram

```
START
  |
  v
Parse command line options
  |
  v
Validate directory
  |
  v
Determine renaming operation:
  |
  +----------------+---------------+---------------+
  |                |               |               |
  v                v               v               v
Counter pattern?   Search/replace? Affixes?        Help?
  |                |               |               |
  v                v               v               v
rename_with_counter rename_with_replace rename_with_affixes Show help
  |                |               |
  +----------------+---------------+
  |
  v
Print completion message
  |
  v
END
```

## Actual Flow Diagram
![Flow Chart](./images/flow-chart2.png)

## Understanding the Script

### Counter Pattern (`-n`)

When using the `-n` option with a pattern like "file-###":
- Each # character represents one digit
- The script will replace these with sequential numbers
- The number of # characters determines padding (e.g., ### will produce 001, 002, etc.)

### Search and Replace (`-r`)

The `-r` option follows this pattern:
- First argument is the text to search for
- Second argument is the replacement text
- All occurrences in each filename will be replaced

### Prefix, Suffix, and Date

These options can be combined:
- Prefix is added at the start of the filename
- Date is added before the prefix in YYYY-MM-DD_ format
- Suffix is added before the extension

## Limitations

- The script processes only files in the specified directory (not subdirectories)
- Files are processed in the order returned by the shell
- No conflict handling for duplicate filenames
- Limited error checking for edge cases

## Future Improvements

- Add recursive operation for subdirectories
- Preview changes before applying
- Support for regular expressions in search/replace
- Add undo functionality
- Handle filename conflicts