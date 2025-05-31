#!/bin/bash
# Script for batch processing multiple PDFs

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
MINERU_HOME="$(dirname "$SCRIPT_DIR")"

# Default values
METHOD="auto"
OUTPUT_BASE_DIR="./batch_output"
INPUT_DIR=""
FILE_PATTERN="*.pdf"
MAX_PARALLEL=1
LANG=""
DEBUG=false

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --input DIR          Input directory containing PDFs (required)"
    echo "  -o, --output DIR         Base output directory (default: ./batch_output)"
    echo "  -m, --method METHOD      Processing method: ocr, txt, or auto (default: auto)"
    echo "  -p, --pattern PATTERN    File pattern (default: *.pdf)"
    echo "  -j, --parallel NUM       Number of parallel jobs (default: 1)"
    echo "  -l, --lang LANG          Language code for OCR"
    echo "  -d, --debug              Enable debug mode"
    echo "  -h, --help               Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -i ./pdfs"
    echo "  $0 -i ./documents -o ./results -m ocr -j 2"
    echo "  $0 -i ./pdfs -p '*.PDF' -l en"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input)
            INPUT_DIR="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_BASE_DIR="$2"
            shift 2
            ;;
        -m|--method)
            METHOD="$2"
            shift 2
            ;;
        -p|--pattern)
            FILE_PATTERN="$2"
            shift 2
            ;;
        -j|--parallel)
            MAX_PARALLEL="$2"
            shift 2
            ;;
        -l|--lang)
            LANG="$2"
            shift 2
            ;;
        -d|--debug)
            DEBUG=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Check if input directory is provided
if [ -z "$INPUT_DIR" ]; then
    echo "Error: Input directory not specified"
    usage
fi

# Check if input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory '$INPUT_DIR' not found"
    exit 1
fi

# Find PDF files
PDF_FILES=($(find "$INPUT_DIR" -maxdepth 1 -name "$FILE_PATTERN" -type f))

if [ ${#PDF_FILES[@]} -eq 0 ]; then
    echo "No PDF files found matching pattern '$FILE_PATTERN' in '$INPUT_DIR'"
    exit 1
fi

echo "Found ${#PDF_FILES[@]} PDF files to process"
echo "Output directory: $OUTPUT_BASE_DIR"
echo "Method: $METHOD"
echo "Parallel jobs: $MAX_PARALLEL"
echo ""

# Create output directory
mkdir -p "$OUTPUT_BASE_DIR"

# Create log directory
LOG_DIR="$OUTPUT_BASE_DIR/logs"
mkdir -p "$LOG_DIR"

# Activate MinerU environment
cd "$MINERU_HOME"
source mineru_env/bin/activate

# Function to process a single PDF
process_pdf() {
    local pdf_file="$1"
    local pdf_name=$(basename "$pdf_file" .pdf)
    local pdf_name_clean=$(echo "$pdf_name" | sed 's/[^a-zA-Z0-9_-]/_/g')
    local output_dir="$OUTPUT_BASE_DIR/$pdf_name_clean"
    local log_file="$LOG_DIR/${pdf_name_clean}.log"
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Processing: $pdf_name"
    
    # Build command
    local cmd="magic-pdf -p \"$pdf_file\" -o \"$output_dir\" -m $METHOD"
    
    if [ -n "$LANG" ]; then
        cmd="$cmd -l $LANG"
    fi
    
    if [ "$DEBUG" = true ]; then
        cmd="$cmd -d true"
    fi
    
    # Execute command
    if eval $cmd > "$log_file" 2>&1; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ Completed: $pdf_name"
        return 0
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ Failed: $pdf_name (see $log_file)"
        return 1
    fi
}

# Export function and variables for parallel execution
export -f process_pdf
export OUTPUT_BASE_DIR METHOD LANG DEBUG LOG_DIR MINERU_HOME

# Track statistics
TOTAL=${#PDF_FILES[@]}
PROCESSED=0
FAILED=0

# Create summary file
SUMMARY_FILE="$OUTPUT_BASE_DIR/processing_summary.txt"
echo "Batch Processing Summary" > "$SUMMARY_FILE"
echo "========================" >> "$SUMMARY_FILE"
echo "Start time: $(date)" >> "$SUMMARY_FILE"
echo "Total files: $TOTAL" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

# Process PDFs
if [ "$MAX_PARALLEL" -eq 1 ]; then
    # Sequential processing
    for pdf_file in "${PDF_FILES[@]}"; do
        if process_pdf "$pdf_file"; then
            ((PROCESSED++))
        else
            ((FAILED++))
        fi
    done
else
    # Parallel processing
    printf '%s\n' "${PDF_FILES[@]}" | xargs -P "$MAX_PARALLEL" -I {} bash -c 'process_pdf "$@"' _ {}
    
    # Count results from logs
    PROCESSED=$(grep -l "local output dir is" "$LOG_DIR"/*.log 2>/dev/null | wc -l)
    FAILED=$((TOTAL - PROCESSED))
fi

# Final summary
echo ""
echo "========================================"
echo "Batch processing completed!"
echo "Total files: $TOTAL"
echo "Successfully processed: $PROCESSED"
echo "Failed: $FAILED"
echo "========================================"

# Update summary file
echo "" >> "$SUMMARY_FILE"
echo "End time: $(date)" >> "$SUMMARY_FILE"
echo "Successfully processed: $PROCESSED" >> "$SUMMARY_FILE"
echo "Failed: $FAILED" >> "$SUMMARY_FILE"

# List failed files if any
if [ $FAILED -gt 0 ]; then
    echo "" >> "$SUMMARY_FILE"
    echo "Failed files:" >> "$SUMMARY_FILE"
    for log_file in "$LOG_DIR"/*.log; do
        if ! grep -q "local output dir is" "$log_file" 2>/dev/null; then
            pdf_name=$(basename "$log_file" .log)
            echo "  - $pdf_name" >> "$SUMMARY_FILE"
        fi
    done
fi

echo ""
echo "Summary saved to: $SUMMARY_FILE"
echo "Logs saved to: $LOG_DIR"

exit 0