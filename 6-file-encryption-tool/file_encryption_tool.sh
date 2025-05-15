#!/bin/bash

# ================================
# File Encryption Tool
# Description:
#   This script provides simple file encryption and decryption using OpenSSL
#   with AES-256-CBC algorithm and PBKDF2 key derivation.
# Usage:
#   ./file_encryption.sh [encrypt|decrypt] [input_file] [output_file]
# ================================

# Function: Display help message and usage examples
show_help() {
    echo "File Encryption Tool"
    echo "Usage:"
    echo "  ./file_encryption.sh encrypt [input_file] [output_file]   # Encrypts a file"
    echo "  ./file_encryption.sh decrypt [input_file] [output_file]   # Decrypts a file"
    echo ""
    echo "Examples:"
    echo "  ./file_encryption.sh encrypt secret.txt secret.enc"
    echo "  ./file_encryption.sh decrypt secret.enc secret_decrypted.txt"
}

# Function: Check if OpenSSL is installed on the system
check_openssl() {
    # `command -v openssl` checks if 'openssl' is available
    if ! command -v openssl &> /dev/null; then
        echo "Error: OpenSSL is not installed. Please install it first."
        exit 1
    fi
}

# Function: Encrypt a file using OpenSSL
encrypt_file() {
    local input_file=$1       # First argument: file to encrypt
    local output_file=$2      # Second argument: destination encrypted file

    # Validate that the input file exists
    if [ ! -f "$input_file" ]; then
        echo "Error: Input file '$input_file' does not exist."
        exit 1
    fi

    # Prompt the user for encryption password (silent input)
    echo "Enter password for encryption:"
    read -s password
    echo "Confirm password:"
    read -s password_confirm

    # Ensure the two entered passwords match
    if [ "$password" != "$password_confirm" ]; then
        echo "Error: Passwords do not match."
        exit 1
    fi

    # Encrypt the file using OpenSSL AES-256-CBC
    # Options:
    #   -salt: adds random salt for stronger encryption
    #   -pbkdf2: uses a modern key derivation function
    #   -iter 10000: performs 10,000 iterations to strengthen the key derivation
    #   -pass stdin: reads password from standard input (provided via echo)
    echo "Encrypting file..."
    echo "$password" | openssl enc -aes-256-cbc -salt -pbkdf2 -iter 10000 \
        -in "$input_file" -out "$output_file" -pass stdin

    # Check if the encryption was successful
    if [ $? -eq 0 ]; then
        echo "File successfully encrypted to '$output_file'"
    else
        echo "Error: Encryption failed."
        exit 1
    fi
}

# Function: Decrypt a file using OpenSSL
decrypt_file() {
    local input_file=$1       # First argument: encrypted file to decrypt
    local output_file=$2      # Second argument: destination decrypted file

    # Validate that the input file exists
    if [ ! -f "$input_file" ]; then
        echo "Error: Input file '$input_file' does not exist."
        exit 1
    fi

    # Prompt the user for decryption password (silent input)
    echo "Enter password for decryption:"
    read -s password

    # Decrypt the file using OpenSSL with matching options as encryption
    echo "Decrypting file..."
    echo "$password" | openssl enc -d -aes-256-cbc -pbkdf2 -iter 10000 \
        -in "$input_file" -out "$output_file" -pass stdin

    # Check if the decryption was successful
    if [ $? -eq 0 ]; then
        echo "File successfully decrypted to '$output_file'"
    else
        echo "Error: Decryption failed. The password may be incorrect or the file is not properly encrypted."
        # Clean up: delete any partially written output file
        [ -f "$output_file" ] && rm "$output_file"
        exit 1
    fi
}

# ========================
# Main Script Execution
# ========================

# Step 1: Ensure OpenSSL is available
check_openssl

# Step 2: Validate that the correct number of arguments is passed
# The script expects at least 3 arguments: action, input_file, output_file
if [ $# -lt 3 ]; then
    show_help
    exit 1
fi

# Step 3: Parse command-line arguments
action=$1           # 'encrypt' or 'decrypt'
input_file=$2       # input file path
output_file=$3      # output file path

# Step 4: Execute the appropriate function based on the action
case "$action" in
    encrypt)
        encrypt_file "$input_file" "$output_file"
        ;;
    decrypt)
        decrypt_file "$input_file" "$output_file"
        ;;
    *)
        # Unknown action: show error and usage
        echo "Error: Unknown action '$action'"
        show_help
        exit 1
        ;;
esac

# Exit script successfully
exit 0
