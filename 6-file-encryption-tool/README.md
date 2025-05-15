# File Encryption Tool Documentation

## Overview

This documentation covers a simple bash script for encrypting and decrypting files using OpenSSL's AES-256-CBC encryption algorithm with password-based protection.

## Requirements

- Bash shell
- OpenSSL installed on your system

## Installation

1. Download the `file_encryption.sh` script to your computer
2. Make it executable:
   ```bash
   chmod +x file_encryption.sh
   ```

## Features

- File encryption using AES-256-CBC algorithm
- Password-based encryption/decryption
- Salt and strong key derivation function (PBKDF2)
- Simple command-line interface

## Usage

### Basic Command Structure

```bash
./file_encryption.sh [action] [input_file] [output_file]
```

Where:
- `[action]` is either `encrypt` or `decrypt`
- `[input_file]` is the file you want to process
- `[output_file]` is where the result will be saved

### Examples

Encrypt a file:
```bash
./file_encryption.sh encrypt secret.txt secret.enc
```

Decrypt a file:
```bash
./file_encryption.sh decrypt secret.enc secret_decrypted.txt
```

## How It Works

### Encryption Process

1. Script checks if OpenSSL is installed
2. User provides the input file, output file, and a password
3. Password is confirmed by entering it twice
4. OpenSSL encrypts the file using AES-256-CBC with:
   - Salt for added randomness
   - PBKDF2 for secure key derivation
   - 10,000 iterations to make brute force attacks harder
5. Encrypted file is saved to the specified output location

### Decryption Process

1. Script checks if OpenSSL is installed
2. User provides the encrypted file, output file, and the password
3. OpenSSL attempts to decrypt using the provided password
4. If successful, the decrypted content is saved to the output file
5. If unsuccessful (wrong password), an error is shown

## Security Considerations

| Feature | Description | Benefit |
|---------|-------------|---------|
| AES-256-CBC | Industry-standard encryption algorithm | Strong security for sensitive files |
| Password-based | Uses a password for encryption/decryption | No key files to manage |
| Salt | Adds random data to the encryption process | Prevents attacks using precomputed tables |
| PBKDF2 | Password-Based Key Derivation Function 2 | Slows down brute force attacks |
| 10,000 iterations | Multiple rounds of key derivation | Makes password cracking more difficult |
| Hidden password input | Password doesn't appear on screen when typing | Prevents shoulder-surfing |

## Limitations

- Security depends on the strength of your password
- No file integrity verification
- Password is temporarily in memory as plaintext
- Not suitable for extremely sensitive information

## Troubleshooting

| Problem | Possible Solution |
|---------|-------------------|
| "OpenSSL is not installed" | Install OpenSSL using your package manager (e.g., `apt-get install openssl` on Ubuntu) |
| "Passwords do not match" | Make sure you type the same password both times when encrypting |
| "Decryption failed" | Ensure you're using the correct password and that the file hasn't been corrupted |
| "Input file does not exist" | Check that you've specified the correct file path |

## Flowchart

```
┌─────────────────┐
│ Start Script    │
└────────┬────────┘
         │
┌────────▼────────┐
│ Check OpenSSL   │
└────────┬────────┘
         │
┌────────▼─────────┐
│ Parse Arguments  │
└────────┬─────────┘
         │
         ▼
    ┌────────┐
    │ Action?│
    └┬──────┬┘
     │      │
┌────▼─┐  ┌─▼────┐
│Encrypt│  │Decrypt│
└───┬───┘  └───┬──┘
    │          │
┌───▼───┐   ┌──▼────┐
│Get    │   │Get    │
│Password│  │Password│
└───┬───┘   └───┬───┘
    │           │
┌───▼───┐    ┌──▼────┐
│Encrypt│    │Decrypt │
│File   │    │File    │
└───┬───┘    └───┬───┘
    │            │
    └─────┬──────┘
          │
    ┌─────▼─────┐
    │    End    │
    └───────────┘
```

## Actual Flow Diagram
![Flow Chart](./images/flow-chart6.svg)


## Best Practices

1. Use strong, unique passwords for different files
2. Store encrypted files securely
3. Back up your files before encryption
4. Remember your passwords - there's no recovery process
5. For extremely sensitive data, consider additional security measures

## Further Improvements

- Add file integrity verification
- Implement key files instead of or alongside passwords
- Add compression before encryption
- Create a more user-friendly interface