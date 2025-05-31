#!/bin/bash

# Script to configure MinerU to use Windows Ollama

echo "Configuring MinerU to use Windows Ollama..."

# Get Windows host IP
WINDOWS_HOST=$(grep -m 1 nameserver /etc/resolv.conf | awk '{print $2}')
echo "Windows host IP: $WINDOWS_HOST"

# Update the configuration file
CONFIG_FILE="/home/mik/MinerU/config/magic-pdf.json"
OLLAMA_CONFIG="/home/mik/MinerU/config/magic-pdf-ollama.json"

# Create the Ollama configuration with the current Windows host IP
cat > "$OLLAMA_CONFIG" << EOF
{
  "models-dir": "/tmp/models",
  "device-mode": "cuda",
  "llm-aided-config": {
    "formula_aided": {
      "api_key": "not-needed",
      "base_url": "http://${WINDOWS_HOST}:11434/v1",
      "model": "qwen2.5:7b-instruct-q4_K_M",
      "enable": true
    },
    "text_aided": {
      "api_key": "not-needed",
      "base_url": "http://${WINDOWS_HOST}:11434/v1",
      "model": "qwen2.5:7b-instruct-q4_K_M",
      "enable": true
    },
    "title_aided": {
      "api_key": "not-needed",
      "base_url": "http://${WINDOWS_HOST}:11434/v1",
      "model": "qwen2.5:7b-instruct-q4_K_M",
      "enable": true
    }
  }
}
EOF

# Copy the Ollama config as the main config
cp "$OLLAMA_CONFIG" "$CONFIG_FILE"

echo "Configuration updated. MinerU is now configured to use Windows Ollama at http://${WINDOWS_HOST}:11434"
echo ""
echo "Make sure Ollama is running on Windows with the required model:"
echo "  ollama pull qwen2.5:7b-instruct-q4_K_M"
echo ""
echo "To test the configuration, run:"
echo "  magic-pdf -p small_ocr.pdf -o ./test_output_ollama -m auto"