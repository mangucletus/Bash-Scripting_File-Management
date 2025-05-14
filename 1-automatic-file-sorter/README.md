# Automatic File Sorter

A simple bash script that organizes files in a directory based on their file types.

## Overview

The Automatic File Sorter is a beginner-friendly bash script that helps you organize messy folders by automatically categorizing files into appropriate subdirectories based on their file extensions.

## Features

- Automatically sorts files into categorized folders
- Creates necessary subdirectories if they don't exist
- Supports common file formats for documents, images, videos, audio, and archives
- Simple command-line interface
- Preserves original filenames

## File Organization Structure

| Category   | Location             | Supported Extensions                                  |
|------------|----------------------|------------------------------------------------------|
| Documents  | ./Documents/         | pdf, doc, docx, txt, rtf, odt, xls, xlsx, ppt, pptx, csv |
| Images     | ./Images/            | jpg, jpeg, png, gif, bmp, svg, tiff                  |
| Videos     | ./Videos/            | mp4, mkv, avi, mov, wmv, flv, webm                   |
| Audio      | ./Audio/             | mp3, wav, ogg, flac, aac, wma                        |
| Archives   | ./Archives/          | zip, rar, tar, gz, 7z                                |
| Others     | ./Others/            | all other file types                                 |

## How to Use

1. Make the script executable:
   ```
   chmod +x file_sorter.sh
   ```

2. Run the script with the target directory as an argument:
   ```
   ./file_sorter.sh /path/to/directory
   ```

3. The script will create category folders and move files accordingly.

## Demo | Example

```
$ ./file_sorter.sh ~/Downloads
Starting to organize files in: /home/cletusmangu/Downloads
Category folders created successfully.
Moved: document.pdf to /home/cletusmangu/Downloads/Documents
Moved: image.jpg to /home/cletusmangu/Downloads/Images
Moved: video.mp4 to /home/cletusmangu/Downloads/Videos
File sorting completed successfully!
```

## Flow Diagram

```
START
  |
  v
Check if directory path is provided
  |
  v
Validate directory exists
  |
  v
Create category folders if they don't exist
  |
  v
For each file in the directory:
  |
  v
  Is it a directory? --> Yes --> Skip to next file
  |
  v
  No
  |
  v
  Extract file extension
  |
  v
  Determine target category based on extension
  |
  v
  Move file to appropriate category folder
  |
  v
END: Display completion message
```

## Customization

You can easily modify the script to:
- Add more file extensions
- Create additional category folders
- Change the naming of category folders

Simply edit the case statement in the `sort_files()` function to add or modify file extensions and their corresponding categories.

## Limitations

- The script will not sort files that are in subdirectories of the target directory
- Files without extensions will be placed in the "Others" folder
- Files with the same name in the destination folder will be overwritten

## Future Improvements

- Add option for recursive sorting (including subdirectories)
- Add conflict resolution for duplicate filenames
- Add a dry run mode to preview changes before execution
- Implement logging of all file operations