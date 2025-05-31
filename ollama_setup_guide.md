# Ollama Setup Guide for MinerU LLM Enhancement

## Current Status
- Ollama is installed (v0.6.7) but the service appears to have connectivity issues
- System has sufficient resources: 8GB VRAM, 19GB RAM, 550GB free disk space

## Manual Setup Steps

### 1. Fix Ollama Service
```bash
# Check service status
sudo systemctl status ollama

# If not running properly, restart:
sudo systemctl restart ollama

# Check logs if issues persist:
sudo journalctl -u ollama -f
```

### 2. Verify Ollama API
```bash
# Test API endpoint
curl http://localhost:11434/api/version

# If timeout, check firewall:
sudo ufw status
```

### 3. Install Recommended Model
For your RTX 3070 8GB, I recommend **Qwen 2.5 7B** (4-bit quantization):

```bash
# Pull the model (4.3GB download)
ollama pull qwen2.5:7b-instruct-q4_K_M

# Alternative lighter options:
# ollama pull mistral:7b-instruct-q4_0     # 4.1GB
# ollama pull llama3.2:3b-instruct-q4_K_M  # 2.0GB
```

### 4. Test Model
```bash
# Quick test
ollama run qwen2.5:7b-instruct-q4_K_M "What is the capital of France?"
```

### 5. Configure MinerU with Ollama

The enhanced configuration has been prepared at:
`/home/mik/MinerU/config/magic-pdf-ollama.json`

Key settings:
- **base_url**: `http://localhost:11434/v1` (Ollama's OpenAI-compatible endpoint)
- **api_key**: `ollama` (placeholder, not used by Ollama)
- **model**: The model name you pulled
- **enable**: `true` for all LLM features

### 6. Use Enhanced Processing

#### Option A: Run Setup Script
```bash
/home/mik/MinerU/scripts/setup_ollama_llm.sh
```

#### Option B: Manual Processing
```bash
# Activate MinerU
source /home/mik/MinerU/scripts/activate_mineru.sh

# Copy Ollama config
cp /home/mik/MinerU/config/magic-pdf-ollama.json /home/mik/magic-pdf.json

# Process with LLM enhancement
magic-pdf -p document.pdf -o ./output_enhanced -m auto
```

## Benefits of LLM Enhancement

With Ollama LLM enabled, MinerU will:
1. **Better Formula Recognition**: LLM helps disambiguate complex mathematical notation
2. **Improved Title Extraction**: Hierarchical title structure understanding
3. **Context-Aware Text**: Better handling of abbreviated terms and technical jargon

## Troubleshooting

### Ollama Connection Issues
1. Check if port 11434 is blocked:
   ```bash
   sudo netstat -tlnp | grep 11434
   ```

2. Try manual start:
   ```bash
   ollama serve
   ```

3. Check environment variables:
   ```bash
   echo $OLLAMA_HOST  # Should be empty or localhost:11434
   ```

### Performance Issues
- Monitor GPU usage during processing: `nvidia-smi -l 1`
- Ollama and MinerU will share GPU memory
- If OOM errors, try smaller model or process in batches

## Alternative: Direct API Testing
```bash
# Test Ollama's OpenAI compatibility
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5:7b-instruct-q4_K_M",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

## Next Steps
1. Run the setup script when Ollama service is working
2. Test with a sample PDF to verify enhancement
3. Compare output quality with and without LLM

## Resources
- Ollama Models: https://ollama.com/library
- Ollama Docs: https://github.com/ollama/ollama
- MinerU + LLM: Enhanced extraction quality for complex documents