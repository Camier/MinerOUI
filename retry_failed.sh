#!/bin/bash
FAILED_DIR="/home/mik/MinerU/thesis_output/failed"

if [ -d "$FAILED_DIR" ] && [ "$(ls -A $FAILED_DIR)" ]; then
    echo "Retrying failed PDFs..."
    for pdf in "$FAILED_DIR"/*.pdf; do
        echo "Retrying: $(basename "$pdf")"
        # Run the Python script for single PDF processing
        /home/mik/MinerU/mineru_env/bin/python /home/mik/MinerU/process_thesis_batch.py --single "$pdf"
    done
else
    echo "No failed PDFs to retry"
fi