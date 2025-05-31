# MinerU Directory Organization

## Current Structure Analysis

### Duplicate Test Outputs (8MB total)
- `test_output/` - Initial test output
- `test_output2/` - Second test run  
- `final_test/` - Final test before Ollama setup
- `test_ollama_output/` - Latest test with Windows Ollama (keep this)

All contain the same processed `small_ocr.pdf` file.

### Important Files
- `config/` - Configuration files
  - `magic-pdf.json` - Current active config (using Windows Ollama)
  - `magic-pdf-ollama.json` - Windows Ollama template
  - `magic-pdf.json.backup` - Backup of original config
  
- `scripts/` - Utility scripts
  - `activate_mineru.sh` - Activate virtual environment
  - `use_windows_ollama.sh` - Configure Windows Ollama
  - `find_ollama.sh` - Find Ollama service
  - `test_windows_ollama.sh` - Test Ollama connectivity
  - `cleanup_organize.sh` - Cleanup script

### Large Directories
- `mineru_env/` (6.2GB) - Python virtual environment (DO NOT DELETE)
- `models/` - Model storage directory

## Recommended Organization

```
MinerU/
├── config/                 # Configuration files
├── scripts/               # Utility scripts  
├── inputs/                # PDFs to process (create this)
├── outputs/               # Processed outputs (organize by date/project)
│   └── archive/          # Old test outputs
├── models/               # Model files
├── docs/                 # Documentation
│   ├── README.md
│   ├── README_LOCAL.md
│   ├── README_SETUP.md
│   └── *.md
└── mineru_env/          # Virtual environment
```

## Quick Cleanup Commands

```bash
# Run the cleanup script
./scripts/cleanup_organize.sh

# Or manually:

# Keep only latest test output
rm -rf test_output test_output2 final_test

# Remove all test outputs
rm -rf test_output*

# Create organized structure
mkdir -p inputs outputs/archive docs
mv *.md docs/
mv test_* outputs/archive/ 2>/dev/null
```

## Best Practices

1. **Input PDFs**: Place in `inputs/` directory
2. **Outputs**: Use descriptive names in `outputs/`
   ```bash
   magic-pdf -p inputs/document.pdf -o outputs/document_$(date +%Y%m%d) -m auto
   ```

3. **Regular Cleanup**: Run cleanup script monthly
4. **Backup Config**: Keep `config/magic-pdf.json.backup` until stable