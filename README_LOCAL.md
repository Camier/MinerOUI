# MinerU - PDF Extraction with CUDA Acceleration

MinerU is installed and configured for GPU-accelerated PDF extraction in `/home/mik/MinerU`.

## System Information
- **GPU**: NVIDIA GeForce RTX 3070 Laptop GPU (8GB VRAM)
- **CUDA Version**: 12.9
- **Python**: 3.10.12
- **MinerU Version**: 1.3.12

## Quick Start

### 1. Activate Environment
```bash
source /home/mik/MinerU/scripts/activate_mineru.sh
```

Or manually:
```bash
cd /home/mik/MinerU
source mineru_env/bin/activate
```

### 2. Basic Usage
```bash
# Auto mode (recommended) - automatically selects best method
magic-pdf -p document.pdf -o ./output -m auto

# OCR mode - for scanned PDFs or images
magic-pdf -p document.pdf -o ./output -m ocr

# Text mode - for text-based PDFs only
magic-pdf -p document.pdf -o ./output -m txt
```

### 3. Helper Scripts

#### Process Single PDF
```bash
/home/mik/MinerU/scripts/process_pdf.sh document.pdf
/home/mik/MinerU/scripts/process_pdf.sh -m ocr -o ./results document.pdf
/home/mik/MinerU/scripts/process_pdf.sh -s 5 -e 10 -l en document.pdf
```

#### Batch Process Multiple PDFs
```bash
/home/mik/MinerU/scripts/batch_process.sh -i ./pdfs
/home/mik/MinerU/scripts/batch_process.sh -i ./pdfs -o ./results -j 2
```

## Configuration

Configuration file: `/home/mik/MinerU/config/magic-pdf.json`

Key settings:
- **device-mode**: "cuda" (GPU acceleration enabled)
- **formula-config**: Enabled for mathematical formula detection
- **table-config**: Enabled for table extraction
- **models-dir**: Models stored in `~/.cache/huggingface/hub/`

## Command Options

### magic-pdf Options
- `-p, --path`: Input PDF file path (required)
- `-o, --output-dir`: Output directory (required)
- `-m, --method`: Processing method (ocr/txt/auto)
- `-l, --lang`: Language code for OCR
- `-s, --start`: Starting page (0-indexed)
- `-e, --end`: Ending page (0-indexed)
- `-d, --debug`: Enable debug mode

### Language Support
For OCR accuracy, specify language codes:
- English: `en`
- Chinese: `ch`
- French: `fr`
- German: `de`
- Japanese: `japan`
- Korean: `korean`
- Russian: `ru`

Full list: https://paddlepaddle.github.io/PaddleOCR/latest/en/ppocr/blog/multi_languages.html

## Output Files

MinerU generates multiple output files:
- `*.md`: Markdown formatted text
- `*_layout.pdf`: PDF with layout analysis visualization
- `*_spans.pdf`: PDF with text spans highlighted
- `*_content_list.json`: Structured content data
- `*_model.json`: Model detection results
- `*_middle.json`: Intermediate processing data
- `images/`: Extracted images

## GPU Monitoring

Monitor GPU usage during processing:
```bash
watch -n 1 nvidia-smi
```

The `process_pdf.sh` script automatically displays GPU usage.

## Examples

### Extract specific pages with language
```bash
magic-pdf -p multilingual.pdf -o ./output -s 10 -e 20 -l en
```

### Process scanned document
```bash
magic-pdf -p scanned_doc.pdf -o ./output -m ocr
```

### Batch process with parallel jobs
```bash
/home/mik/MinerU/scripts/batch_process.sh -i ./documents -j 2 -m auto
```

## Directory Structure
```
/home/mik/MinerU/
├── mineru_env/         # Python virtual environment
├── config/             # Configuration files
│   └── magic-pdf.json  # Main configuration
├── scripts/            # Helper scripts
│   ├── activate_mineru.sh
│   ├── process_pdf.sh
│   └── batch_process.sh
├── test_output/        # Test outputs
└── models/             # Model storage (if needed)
```

## Performance Tips

1. **GPU Memory**: Monitor GPU memory usage, especially for large PDFs
2. **Batch Size**: Automatically adjusted based on available GPU memory
3. **Parallel Processing**: Use `-j` option in batch_process.sh carefully
4. **Method Selection**: 
   - Use `auto` for mixed content
   - Use `txt` for pure text PDFs (fastest)
   - Use `ocr` for scanned documents

## Troubleshooting

See `troubleshooting.md` for common issues and solutions.

## Additional Resources
- GitHub: https://github.com/opendatalab/MinerU
- Documentation: https://github.com/opendatalab/MinerU/blob/master/README.md