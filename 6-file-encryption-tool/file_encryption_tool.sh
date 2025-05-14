#!/bin/bash

# File Encryption Tool
# This script encrypts and decrypts files using OpenSSL AES-256-CBC encryption
# Usage: ./file_encryption.sh [encrypt|decrypt] [input_file] [output_file]

# Display help message
show_help() {
    echo "File Encryption Tool"
    echo "Usage:"
    echo "  ./file_encryption.sh encrypt [input_file] [output_file]"
    echo "  ./file_encryption.sh decrypt [input_file] [output_file]"
    echo ""
    echo "Examples:"
    echo "  ./file_encryption.sh encrypt secret.txt secret.enc"
    echo "  ./file_encryption.sh decrypt secret.enc secret_decrypted.txt"
}

# Check if OpenSSL is installed
check_openssl() {
    if ! command -v openssl &> /dev/null; then
        echo "Error: OpenSSL is not installed. Please install it first."
        exit 1
    fi
}

# Encrypt a file
encrypt_file() {
    local input_file=$1
    local output_file=$2
    
    # Check if input file exists
    if [ ! -f "$input_file" ]; then
        echo "Error: Input file '$input_file' does not exist."
        exit 1
    fi
    
    # Prompt for password (will be hidden when typing)
    echo "Enter password for encryption:"
    read -s password
    echo "Confirm password:"
    read -s password_confirm
    
    # Check if passwords match
    if [ "$password" != "$password_confirm" ]; then
        echo "Error: Passwords do not match."
        exit 1
    fi
    
    # Use OpenSSL to encrypt the file with AES-256-CBC
    # -salt adds random salt to make encryption stronger
    # -pbkdf2 uses a better key derivation function
    # -iter 10000 specifies 10000 iterations for key derivation (more secure)
    echo "Encrypting file..."
    echo "$password" | openssl enc -aes-256-cbc -salt -pbkdf2 -iter 10000 \
        -in "$input_file" -out "$output_file" -pass stdin
    
    # Check if encryption was successful
    if [ $? -eq 0 ]; then
        echo "File successfully encrypted to '$output_file'"
    else
        echo "Error: Encryption failed."
        exit 1
    fi
}

# Decrypt a file
decrypt_file() {
    local input_file=$1
    local output_file=$2
    
    # Check if input file exists
    if [ ! -f "$input_file" ]; then
        echo "Error: Input file '$input_file' does not exist."
        exit 1
    fi
    
    # Prompt for password (will be hidden when typing)
    echo "Enter password for decryption:"
    read -s password
    
    # Use OpenSSL to decrypt the file
    echo "Decrypting file..."
    echo "$password" | openssl enc -d -aes-256-cbc -pbkdf2 -iter 10000 \
        -in "$input_file" -out "$output_file" -pass stdin
    
    # Check if decryption was successful
    if [ $? -eq 0 ]; then
        echo "File successfully decrypted to '$output_file'"
    else
        echo "Error: Decryption failed. The password may be incorrect or the file is not properly encrypted."
        # Remove the output file if it was created
        [ -f "$output_file" ] && rm "$output_file"
        exit 1
    fi
}

# Main script execution

# Check for OpenSSL
check_openssl

# Check if enough arguments are provided
if [ $# -lt 3 ]; then
    show_help
    exit 1
fi

action=$1
input_file=$2
output_file=$3

# Process based on action
case "$action" in
    encrypt)
        encrypt_file "$input_file" "$output_file"
        ;;
    decrypt)
        decrypt_file "$input_file" "$output_file"
        ;;
    *)
        echo "Error: Unknown action '$action'"
        show_help
        exit 1
        ;;
esac

exit 0