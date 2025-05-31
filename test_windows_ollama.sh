#!/bin/bash

echo "Testing MinerU with Windows Ollama configuration..."
echo ""

# Get Windows host IP
WINDOWS_HOST=$(grep -m 1 nameserver /etc/resolv.conf | awk '{print $2}')
echo "Windows host IP: $WINDOWS_HOST"
echo ""

# Test connectivity to Ollama
echo "Testing Ollama connectivity..."
if curl -s --connect-timeout 5 "http://${WINDOWS_HOST}:11434/api/version" > /dev/null 2>&1; then
    echo "✓ Successfully connected to Ollama on Windows"
    curl -s "http://${WINDOWS_HOST}:11434/api/version" | jq .
else
    echo "✗ Cannot connect to Ollama on Windows at http://${WINDOWS_HOST}:11434"
    echo "  Please ensure:"
    echo "  1. Ollama is running on Windows"
    echo "  2. Windows Firewall allows connections on port 11434"
    echo "  3. Ollama is listening on all interfaces (not just localhost)"
    echo ""
    echo "  To make Ollama listen on all interfaces, set this environment variable on Windows:"
    echo "  OLLAMA_HOST=0.0.0.0:11434"
fi
echo ""

# Check if model is available
echo "Checking for required model..."
if curl -s --connect-timeout 5 "http://${WINDOWS_HOST}:11434/api/tags" | jq -r '.models[].name' | grep -q "qwen2.5:7b-instruct-q4_K_M"; then
    echo "✓ Model qwen2.5:7b-instruct-q4_K_M is available"
else
    echo "✗ Model qwen2.5:7b-instruct-q4_K_M not found"
    echo "  Please run on Windows: ollama pull qwen2.5:7b-instruct-q4_K_M"
fi