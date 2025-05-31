#!/bin/bash
# Fix Ollama connectivity issues with VPN

echo "=== Ollama VPN Fix Script ==="
echo

# Option 1: Try using WSL2 IP
WSL_IP=$(ip addr show eth2 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
echo "WSL2 IP: $WSL_IP"

echo
echo "Testing connectivity options..."

# Test localhost
echo -n "1. Testing localhost (127.0.0.1): "
timeout 5 curl -s http://127.0.0.1:11434/api/version >/dev/null 2>&1 && echo "✓ Working" || echo "✗ Blocked"

# Test WSL IP
echo -n "2. Testing WSL IP ($WSL_IP): "
timeout 5 curl -s http://$WSL_IP:11434/api/version >/dev/null 2>&1 && echo "✓ Working" || echo "✗ Blocked"

# Test Windows host
echo -n "3. Testing Windows host (host.docker.internal): "
timeout 5 curl -s http://host.docker.internal:11434/api/version >/dev/null 2>&1 && echo "✓ Working" || echo "✗ Blocked"

echo
echo "=== Recommended Solutions ==="
echo
echo "1. TEMPORARY FIX - Disconnect VPN:"
echo "   - Disconnect VPN in Windows"
echo "   - Run: wsl --shutdown (in Windows)"
echo "   - Restart WSL and Ollama"
echo
echo "2. PERMANENT FIX - Use WSL IP:"
echo "   export OLLAMA_HOST=$WSL_IP:11434"
echo "   ollama serve"
echo
echo "3. VPN SPLIT TUNNELING:"
echo "   - Add 127.0.0.1 to VPN bypass list"
echo "   - Or add $WSL_IP to bypass list"
echo
echo "4. UPDATE MINERU CONFIG:"
echo "   Edit /home/mik/magic-pdf.json:"
echo "   \"base_url\": \"http://$WSL_IP:11434/v1\""