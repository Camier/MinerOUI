#!/bin/bash
# Wrapper script for common PDF processing tasks

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
MINERU_HOME="$(dirname "$SCRIPT_DIR")"

# Default values
METHOD="auto"
OUTPUT_DIR="./output"
START_PAGE=""
END_PAGE=""
LANG=""
DEBUG=false

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS] PDF_FILE"
    echo ""
    echo "Options:"
    echo "  -m, --method METHOD      Processing method: ocr, txt, or auto (default: auto)"
    echo "  -o, --output DIR         Output directory (default: ./output)"
    echo "  -s, --start PAGE         Starting page (0-indexed)"
    echo "  -e, --end PAGE           Ending page (0-indexed)"
    echo "  -l, --lang LANG          Language code for OCR (e.g., 'en', 'ch', 'fr')"
    echo "  -d, --debug              Enable debug mode"
    echo "  -h, --help               Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 document.pdf"
    echo "  $0 -m ocr -o ./results document.pdf"
    echo "  $0 -s 5 -e 10 -l en document.pdf"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--method)
            METHOD="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -s|--start)
            START_PAGE="$2"
            shift 2
            ;;
        -e|--end)
            END_PAGE="$2"
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
            PDF_FILE="$1"
            shift
            ;;
    esac
done

# Check if PDF file is provided
if [ -z "$PDF_FILE" ]; then
    echo "Error: No PDF file specified"
    usage
fi

# Check if PDF file exists
if [ ! -f "$PDF_FILE" ]; then
    echo "Error: PDF file '$PDF_FILE' not found"
    exit 1
fi

# Activate MinerU environment
cd "$MINERU_HOME"
source mineru_env/bin/activate

# Build command
CMD="magic-pdf -p \"$PDF_FILE\" -o \"$OUTPUT_DIR\" -m $METHOD"

# Add optional parameters
if [ -n "$START_PAGE" ]; then
    CMD="$CMD -s $START_PAGE"
fi

if [ -n "$END_PAGE" ]; then
    CMD="$CMD -e $END_PAGE"
fi

if [ -n "$LANG" ]; then
    CMD="$CMD -l $LANG"
fi

if [ "$DEBUG" = true ]; then
    CMD="$CMD -d true"
fi

# Display command
echo "Processing PDF with MinerU..."
echo "Command: $CMD"
echo ""

# Monitor GPU usage in background if nvidia-smi is available
if command -v nvidia-smi &> /dev/null; then
    (
        while true; do
            nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits | \
            awk -F', ' '{printf "\rGPU Usage: %s%%, Memory: %s/%s MB", $1, $2, $3}'
            sleep 1
        done
    ) &
    GPU_MONITOR_PID=$!
fi

# Execute command
eval $CMD
EXIT_CODE=$?

# Kill GPU monitor if running
if [ -n "$GPU_MONITOR_PID" ]; then
    kill $GPU_MONITOR_PID 2>/dev/null
    echo ""  # New line after GPU usage display
fi

# Check results
if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "Processing completed successfully!"
    echo "Output directory: $OUTPUT_DIR"
    
    # Show output files
    PDF_NAME=$(basename "$PDF_FILE" .pdf)
    if [ -d "$OUTPUT_DIR/$PDF_NAME/$METHOD" ]; then
        echo ""
        echo "Generated files:"
        ls -lh "$OUTPUT_DIR/$PDF_NAME/$METHOD/" | grep -E '\.(md|json|pdf)$'
    fi
else
    echo ""
    echo "Error: Processing failed with exit code $EXIT_CODE"
fi

exit $EXIT_CODE