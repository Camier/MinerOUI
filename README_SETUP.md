# MinerU CUDA Setup on WSL2

This repository contains scripts and configuration for MinerU with CUDA acceleration on WSL2.

## System Specs
- GPU: NVIDIA RTX 3070 8GB
- CUDA: 12.9
- WSL2 Ubuntu
- Python: 3.10+

## Installation Steps
1. Clone this repo
2. Install MinerU: `pip install -U "magic-pdf[full]"`
3. Download models: `python download_models_hf.py`
4. Copy `magic-pdf.json` to home directory

## Usage
```bash
magic-pdf -p document.pdf -o ./output -m auto
```

## Known Issues
- Ollama integration has WSL2 networking issues
- Use without LLM enhancement for now