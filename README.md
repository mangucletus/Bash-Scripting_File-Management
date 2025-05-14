# Bash Scripting - File Management

This repository contains seven different file management utilities, each designed to solve specific file organization, management, and security challenges. Each utility is contained in its own directory with detailed documentation.

## Table of Contents

1. [Automatic File Sorter](#automatic-file-sorter)
2. [Bulk File Renamer](#bulk-file-renamer)
3. [Duplicate File Finder](#duplicate-file-finder)
4. [File Backup System](#file-backup-system)
5. [Disk Space Analyzer](#disk-space-analyzer)
6. [File Encryption Tool](#file-encryption-tool)
7. [File Sync Utility](#file-sync-utility)

## Automatic File Sorter

**Description:** A script that automatically organizes files in a directory based on their file types, sorting them into appropriate subfolders.

**Key Features:**
- Automatic file type detection
- Creation of category-based subfolders (Documents, Images, Videos, etc.)
- Configurable file type mapping
- Detailed sorting logs

**Skills Demonstrated:**
- File handling
- String manipulation
- Conditional statements
- Directory management

[Detailed Documentation for Automatic File Sorter](./file_sorter/README.md)

## Bulk File Renamer

**Description:** A tool that allows users to rename multiple files at once using customizable patterns and rules.

**Key Features:**
- Custom naming patterns and conventions
- Add prefixes/suffixes to filenames
- Sequential numbering options
- Date-based naming formats
- Preview changes before applying

**Skills Demonstrated:**
- Loops
- Regular expressions
- Command-line argument parsing
- String formatting

[Detailed Documentation for Bulk File Renamer](./file_renamer/README.md)

## Duplicate File Finder

**Description:** A utility to identify and manage duplicate files within a directory structure, helping users reclaim disk space.

**Key Features:**
- Size-based initial comparison
- Content hash verification
- Interactive duplicate management
- Options to delete or move duplicate files
- Detailed reporting

**Skills Demonstrated:**
- File comparison algorithms
- Hash functions
- Array manipulation
- Interactive user interfaces

[Detailed Documentation for Duplicate File Finder](./duplicate_finder/README.md)

## File Backup System

**Description:** A program that automates the backup of important files to specified destinations with various backup options.

**Key Features:**
- Full and incremental backup options
- Compression capabilities
- Scheduled backups
- Backup verification
- Restore functionality

**Skills Demonstrated:**
- File copying and synchronization
- Date/time handling
- Task scheduling
- Compression algorithms

[Detailed Documentation for File Backup System](./backup_system/README.md)

## Disk Space Analyzer

**Description:** A tool that analyzes disk usage, identifying the directories and files consuming the most space.

**Key Features:**
- Hierarchical directory size analysis
- Visual tree-like representation
- Sorting and filtering options
- Export reports in various formats

**Skills Demonstrated:**
- Recursive directory traversal
- Data sorting and filtering
- Output formatting
- Data visualization techniques

[Detailed Documentation for Disk Space Analyzer](./space_analyzer/README.md)

## File Encryption Tool

**Description:** A security utility that encrypts and decrypts files using password protection to safeguard sensitive information.

**Key Features:**
- Strong encryption algorithms
- Secure password handling
- Batch encryption capabilities
- Encrypted file management

**Skills Demonstrated:**
- Cryptography implementation
- Secure data handling
- Input/output operations
- Security best practices

[Detailed Documentation for File Encryption Tool](./encryption_tool/README.md)

## File Sync Utility

**Key Features:**
- Two-way synchronization
- Conflict detection and resolution
- Scheduled sync operations
- Detailed sync logs and reports
- Skip rules for specific files or patterns

**Skills Demonstrated:**
- File comparison mechanisms
- Error handling
- Logging systems
- Conflict resolution strategies

[Detailed Documentation for File Sync Utility](./sync_utility/README.md)

## Installation and Usage

Each utility can be installed and used independently. Navigate to the specific project directory and follow the instructions in the individual README files.

## System Requirements

- Python 3.6 or higher
- Operating System: Windows, macOS, or Linux
- Additional dependencies listed in each project's documentation

