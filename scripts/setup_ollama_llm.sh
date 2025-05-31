#!/bin/bash
# Script to set up Ollama with optimal LLM for MinerU enhancement

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
MINERU_HOME="$(dirname "$SCRIPT_DIR")"

echo "==================================="
echo "Ollama LLM Setup for MinerU"
echo "==================================="

# Function to check if Ollama is responding
check_ollama() {
    if curl -s -m 5 http://localhost:11434/api/version > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Step 1: Check Ollama installation
echo "1. Checking Ollama installation..."
if ! command -v ollama &> /dev/null; then
    echo "ERROR: Ollama not found. Please install it first:"
    echo "curl -fsSL https://ollama.com/install.sh | sh"
    exit 1
fi

OLLAMA_VERSION=$(ollama --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
echo "✓ Ollama version: $OLLAMA_VERSION"

# Step 2: Check/Start Ollama service
echo ""
echo "2. Checking Ollama service..."
if systemctl is-active --quiet ollama; then
    echo "✓ Ollama service is running"
else
    echo "Starting Ollama service..."
    echo "Please run: sudo systemctl start ollama"
    echo "Then run this script again"
    exit 1
fi

# Step 3: Wait for Ollama to be ready
echo ""
echo "3. Waiting for Ollama API..."
for i in {1..30}; do
    if check_ollama; then
        echo "✓ Ollama API is ready"
        break
    fi
    echo -n "."
    sleep 1
done

if ! check_ollama; then
    echo ""
    echo "ERROR: Ollama API not responding. Try:"
    echo "1. sudo systemctl restart ollama"
    echo "2. Check logs: sudo journalctl -u ollama -f"
    exit 1
fi

# Step 4: List current models
echo ""
echo "4. Current Ollama models:"
ollama list || echo "No models installed"

# Step 5: Recommend and pull model
echo ""
echo "5. Recommended models for 8GB VRAM:"
echo "   a) qwen2.5:7b-instruct-q4_K_M (4.3GB) - Best for document analysis"
echo "   b) mistral:7b-instruct-q4_0 (4.1GB) - Good general purpose"
echo "   c) llama3.2:3b-instruct-q4_K_M (2.0GB) - Lightweight option"
echo ""

read -p "Which model to install? (a/b/c or enter model name): " choice

case $choice in
    a)
        MODEL="qwen2.5:7b-instruct-q4_K_M"
        ;;
    b)
        MODEL="mistral:7b-instruct-q4_0"
        ;;
    c)
        MODEL="llama3.2:3b-instruct-q4_K_M"
        ;;
    *)
        MODEL="$choice"
        ;;
esac

echo ""
echo "Pulling model: $MODEL"
echo "This may take several minutes..."
ollama pull "$MODEL"

# Step 6: Test the model
echo ""
echo "6. Testing model..."
echo "Sending test prompt..."
TEST_RESPONSE=$(echo '{"model": "'$MODEL'", "prompt": "Extract the title from this text: Introduction to Machine Learning", "stream": false}' | \
    curl -s -X POST http://localhost:11434/api/generate \
    -H "Content-Type: application/json" \
    -d @- | jq -r '.response' 2>/dev/null || echo "Test failed")

if [ "$TEST_RESPONSE" != "Test failed" ] && [ -n "$TEST_RESPONSE" ]; then
    echo "✓ Model test successful"
    echo "Response: $TEST_RESPONSE"
else
    echo "⚠ Model test failed. Check Ollama logs."
fi

# Step 7: Create MinerU config update
echo ""
echo "7. Creating MinerU configuration..."

cat > "$MINERU_HOME/config/magic-pdf-ollama.json" << EOF
{
    "bucket_info": {
        "bucket-name-1": ["ak", "sk", "endpoint"],
        "bucket-name-2": ["ak", "sk", "endpoint"]
    },
    "models-dir": "/home/mik/.cache/huggingface/hub/models--opendatalab--PDF-Extract-Kit-1.0/snapshots/94736d90d98216c30edeef5577ae89a7be656bf5/models",
    "layoutreader-model-dir": "/home/mik/.cache/huggingface/hub/models--hantian--layoutreader/snapshots/641226775a0878b1014a96ad01b9642915136853",
    "device-mode": "cuda",
    "layout-config": {
        "model": "doclayout_yolo"
    },
    "formula-config": {
        "mfd_model": "yolo_v8_mfd",
        "mfr_model": "unimernet_small",
        "enable": true
    },
    "table-config": {
        "model": "rapid_table",
        "sub_model": "slanet_plus",
        "enable": true,
        "max_time": 700
    },
    "llm-aided-config": {
        "formula_aided": {
            "api_key": "ollama",
            "base_url": "http://localhost:11434/v1",
            "model": "$MODEL",
            "enable": true
        },
        "text_aided": {
            "api_key": "ollama",
            "base_url": "http://localhost:11434/v1",
            "model": "$MODEL",
            "enable": true
        },
        "title_aided": {
            "api_key": "ollama",
            "base_url": "http://localhost:11434/v1",
            "model": "$MODEL",
            "enable": true
        }
    },
    "config_version": "1.2.0"
}
EOF

echo "✓ Created enhanced config: $MINERU_HOME/config/magic-pdf-ollama.json"

# Step 8: Create helper script
cat > "$MINERU_HOME/scripts/process_pdf_with_llm.sh" << 'EOFSCRIPT'
#!/bin/bash
# Process PDF with Ollama LLM enhancement

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
MINERU_HOME="$(dirname "$SCRIPT_DIR")"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <pdf_file> [output_dir]"
    exit 1
fi

PDF_FILE="$1"
OUTPUT_DIR="${2:-./output_llm}"

# Check if Ollama is running
if ! curl -s -m 2 http://localhost:11434/api/version > /dev/null 2>&1; then
    echo "ERROR: Ollama not responding. Please ensure it's running:"
    echo "sudo systemctl start ollama"
    exit 1
fi

# Activate MinerU environment
cd "$MINERU_HOME"
source mineru_env/bin/activate

# Copy Ollama config to home directory (MinerU looks there)
cp "$MINERU_HOME/config/magic-pdf-ollama.json" /home/mik/magic-pdf.json

echo "Processing with LLM enhancement..."
magic-pdf -p "$PDF_FILE" -o "$OUTPUT_DIR" -m auto

# Restore original config
cp "$MINERU_HOME/config/magic-pdf.json" /home/mik/magic-pdf.json

echo "Processing complete! Check $OUTPUT_DIR"
EOFSCRIPT

chmod +x "$MINERU_HOME/scripts/process_pdf_with_llm.sh"
echo ""
echo "✓ Created helper script: $MINERU_HOME/scripts/process_pdf_with_llm.sh"

# Step 9: GPU configuration info
echo ""
echo "9. GPU Configuration:"
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader

echo ""
echo "==================================="
echo "Setup Complete!"
echo "==================================="
echo ""
echo "To use MinerU with LLM enhancement:"
echo "1. Ensure Ollama is running: sudo systemctl status ollama"
echo "2. Use the enhanced script:"
echo "   $MINERU_HOME/scripts/process_pdf_with_llm.sh document.pdf"
echo ""
echo "To switch models later:"
echo "   ollama pull <model_name>"
echo "   Update model in: $MINERU_HOME/config/magic-pdf-ollama.json"
echo ""
echo "Installed model: $MODEL"