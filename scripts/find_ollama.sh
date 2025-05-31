#!/bin/bash

echo "Searching for Ollama on Windows..."
echo ""

# Try different possible Windows host IPs
POSSIBLE_IPS=(
    "$(grep -m 1 nameserver /etc/resolv.conf | awk '{print $2}')"
    "host.docker.internal"
    "$(ip route | grep default | awk '{print $3}' | head -1)"
    "172.17.0.1"
    "localhost"
    "127.0.0.1"
)

# For WSL2, try to get the Windows host IP
if command -v wslinfo >/dev/null 2>&1; then
    WSL_HOST=$(wslinfo --networking-mode | grep -q "mirrored" && echo "localhost" || echo "$(grep nameserver /etc/resolv.conf | awk '{print $2}' | head -1)")
    POSSIBLE_IPS+=("$WSL_HOST")
fi

# Remove duplicates
POSSIBLE_IPS=($(echo "${POSSIBLE_IPS[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

echo "Testing the following addresses:"
for ip in "${POSSIBLE_IPS[@]}"; do
    echo -n "  Trying $ip:11434... "
    if curl -s --connect-timeout 2 "http://$ip:11434/api/version" >/dev/null 2>&1; then
        echo "✓ SUCCESS!"
        echo ""
        echo "Found Ollama at: http://$ip:11434"
        echo "Version info:"
        curl -s "http://$ip:11434/api/version" | jq . 2>/dev/null || curl -s "http://$ip:11434/api/version"
        echo ""
        echo "To use this address, update your configuration with:"
        echo "  base_url: \"http://$ip:11434/v1\""
        exit 0
    else
        echo "✗ Failed"
    fi
done

echo ""
echo "Could not find Ollama on any of the tested addresses."
echo ""
echo "Please ensure on Windows:"
echo "1. Ollama is running (check system tray or run 'ollama serve')"
echo "2. Set OLLAMA_HOST=0.0.0.0:11434 before starting Ollama"
echo "3. Windows Firewall allows connections on port 11434"