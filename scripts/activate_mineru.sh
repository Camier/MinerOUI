#!/bin/bash
# Script to quickly activate MinerU environment

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
MINERU_HOME="$(dirname "$SCRIPT_DIR")"

echo "Activating MinerU environment..."
cd "$MINERU_HOME"
source mineru_env/bin/activate

echo "MinerU environment activated!"
echo "Python version: $(python --version)"
echo "MinerU home: $MINERU_HOME"
echo ""
echo "Available commands:"
echo "  magic-pdf -p <pdf_file> -o <output_dir> -m <method>"
echo ""
echo "Methods:"
echo "  ocr  - Use OCR for all content"
echo "  txt  - Extract text from text-based PDFs"
echo "  auto - Automatically choose best method (default)"
echo ""
echo "Example:"
echo "  magic-pdf -p document.pdf -o ./output -m auto"