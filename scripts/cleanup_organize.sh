#!/bin/bash

# MinerU Cleanup and Organization Script

echo "MinerU Directory Cleanup and Organization"
echo "========================================"
echo ""

# Identify what to clean
echo "Found the following items to clean up:"
echo ""

# Count duplicate test outputs
TEST_DIRS=$(find . -type d -name "test_output*" -o -name "final_test" -o -name "test_ollama_output" | grep -v mineru_env)
if [ -n "$TEST_DIRS" ]; then
    echo "Test output directories (8MB total, 4 copies of same PDF):"
    echo "$TEST_DIRS" | sed 's/^/  /'
    echo ""
fi

# Check for backup files
BACKUP_FILES=$(find . -name "*.backup" -o -name "*.bak" -o -name "*~" -o -name "*.tmp" 2>/dev/null | grep -v mineru_env)
if [ -n "$BACKUP_FILES" ]; then
    echo "Backup files:"
    echo "$BACKUP_FILES" | sed 's/^/  /'
    echo ""
fi

# Check for __pycache__ directories
PYCACHE_DIRS=$(find . -type d -name "__pycache__" | grep -v mineru_env)
if [ -n "$PYCACHE_DIRS" ]; then
    echo "Python cache directories:"
    echo "$PYCACHE_DIRS" | sed 's/^/  /'
    echo ""
fi

# Ask for confirmation
echo "What would you like to do?"
echo "1) Remove all test outputs except the most recent (test_ollama_output)"
echo "2) Remove all test outputs and backup files"
echo "3) Create an 'outputs' directory and move all test outputs there"
echo "4) Cancel"
echo ""
read -p "Choose an option (1-4): " choice

case $choice in
    1)
        echo "Keeping only test_ollama_output..."
        rm -rf test_output test_output2 final_test
        echo "✓ Removed duplicate test outputs"
        ;;
    2)
        echo "Removing all test outputs and backup files..."
        rm -rf test_output test_output2 final_test test_ollama_output
        rm -f config/magic-pdf.json.backup
        find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
        echo "✓ Removed all test outputs and backup files"
        ;;
    3)
        echo "Organizing test outputs..."
        mkdir -p outputs
        mv test_output test_output2 final_test test_ollama_output outputs/ 2>/dev/null
        echo "✓ Moved all test outputs to 'outputs' directory"
        ;;
    4)
        echo "Cleanup cancelled"
        exit 0
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

# Show final structure
echo ""
echo "Current directory structure:"
echo "------------------------"
ls -la | grep -v "^total" | awk '{print $9}' | grep -v "^$" | grep -v "^\.$" | grep -v "^\.\.$" | sed 's/^/  /'

# Show disk usage
echo ""
echo "Disk usage:"
du -sh */ 2>/dev/null | sort -h | sed 's/^/  /'

echo ""
echo "✓ Cleanup complete!"