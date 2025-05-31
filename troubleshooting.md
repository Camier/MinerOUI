# MinerU Troubleshooting Guide

## Common Issues and Solutions

### 1. CUDA/GPU Issues

#### Problem: "CUDA out of memory" error
**Solution:**
- Close other GPU-intensive applications
- Process PDFs in smaller batches
- Reduce page ranges using `-s` and `-e` options
- Monitor GPU memory with `nvidia-smi`

#### Problem: "CUDA not available" or using CPU instead of GPU
**Solution:**
```bash
# Check CUDA availability
cd /home/mik/MinerU
source mineru_env/bin/activate
python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
```

If CUDA is not available:
- Verify NVIDIA drivers: `nvidia-smi`
- Reinstall PyTorch with CUDA support
- Check configuration in `magic-pdf.json`: ensure `"device-mode": "cuda"`

### 2. Installation Issues

#### Problem: "magic-pdf: command not found"
**Solution:**
```bash
# Activate the environment first
source /home/mik/MinerU/scripts/activate_mineru.sh
# Or use full path
/home/mik/MinerU/mineru_env/bin/magic-pdf
```

#### Problem: Missing dependencies
**Solution:**
```bash
cd /home/mik/MinerU
source mineru_env/bin/activate
pip install -U "magic-pdf[full]"
```

### 3. Model Issues

#### Problem: "Model not found" errors
**Solution:**
```bash
# Re-download models
cd /home/mik/MinerU
source mineru_env/bin/activate
python download_models_hf.py
```

#### Problem: Slow model loading
**Solution:**
- Models are cached after first use
- Check disk space in `~/.cache/huggingface/`
- Ensure models path in config is correct

### 4. Processing Issues

#### Problem: Poor OCR quality
**Solutions:**
- Specify correct language: `-l en` or `-l ch`
- Use higher quality/resolution PDFs
- For mixed language documents, use multiple language codes

#### Problem: Tables not extracted properly
**Solution:**
- Ensure table detection is enabled in config
- Try OCR mode for complex tables: `-m ocr`
- Check `max_time` setting in table-config

#### Problem: Formulas not recognized
**Solution:**
- Verify formula detection is enabled in config
- OCR mode typically works better for formulas
- Check if MFR model is loaded properly

### 5. Output Issues

#### Problem: Missing output files
**Solution:**
- Check error logs in output directory
- Ensure write permissions for output directory
- Look for `.log` files in batch processing

#### Problem: Corrupted output
**Solution:**
- Try reprocessing with debug mode: `-d true`
- Check input PDF isn't corrupted
- Process specific page ranges to isolate issues

### 6. Performance Issues

#### Problem: Processing is very slow
**Solutions:**
- Verify GPU is being used (check nvidia-smi during processing)
- Use text mode for text-based PDFs: `-m txt`
- Process in smaller chunks
- Disable unnecessary features in config

#### Problem: High memory usage
**Solution:**
- Process fewer pages at once
- Reduce parallel jobs in batch processing
- Close other applications

### 7. Configuration Issues

#### Problem: Config file not found
**Solution:**
```bash
# Check config location
ls -la /home/mik/magic-pdf.json
ls -la /home/mik/MinerU/config/magic-pdf.json

# Copy config if needed
cp /home/mik/magic-pdf.json /home/mik/MinerU/config/
```

### 8. Debugging Commands

#### Check Python and package versions
```bash
cd /home/mik/MinerU
source mineru_env/bin/activate
python --version
pip show magic-pdf
pip show torch
```

#### Test CUDA setup
```bash
python -c "import torch; print(torch.cuda.get_device_name(0))"
```

#### Verbose processing
```bash
magic-pdf -p test.pdf -o ./debug_output -m auto -d true
```

#### Check model files
```bash
ls -la ~/.cache/huggingface/hub/models--opendatalab--PDF-Extract-Kit-1.0/
```

### 9. Environment Issues

#### Problem: Virtual environment issues
**Solution:**
```bash
# Recreate virtual environment
cd /home/mik/MinerU
rm -rf mineru_env
python3 -m venv mineru_env
source mineru_env/bin/activate
pip install -U pip
pip install -U "magic-pdf[full]"
```

### 10. Getting Help

If issues persist:

1. Check the official documentation:
   - https://github.com/opendatalab/MinerU

2. Enable debug mode and check logs:
   ```bash
   magic-pdf -p problem.pdf -o ./debug -m auto -d true 2>&1 | tee debug.log
   ```

3. Verify system requirements:
   - NVIDIA GPU with 6GB+ VRAM
   - CUDA 11.8 or higher
   - Python 3.8+

4. Common log locations:
   - Processing logs: `output_dir/logs/`
   - System logs: Check terminal output
   - GPU logs: `nvidia-smi -l 1`