#!/usr/bin/env python3
import os
import sys
import json
import time
import subprocess
from datetime import datetime
from pathlib import Path
import multiprocessing as mp
from concurrent.futures import ProcessPoolExecutor, as_completed

class ThesisBatchProcessor:
    def __init__(self, input_dir="/home/mik/thesis", output_base="/home/mik/MinerU/thesis_output"):
        self.input_dir = Path(input_dir)
        self.output_base = Path(output_base)
        self.processed_dir = self.output_base / "processed"
        self.failed_dir = self.output_base / "failed"
        self.logs_dir = self.output_base / "logs"
        self.stats_file = self.output_base / "stats" / "processing_stats.json"
        
        # Create directories
        for dir in [self.processed_dir, self.failed_dir, self.logs_dir, self.stats_file.parent]:
            dir.mkdir(parents=True, exist_ok=True)
        
        self.stats = {
            "start_time": datetime.now().isoformat(),
            "total_files": 0,
            "processed": 0,
            "failed": 0,
            "skipped": 0,
            "processing_times": [],
            "errors": []
        }

    def get_pdf_files(self):
        """Get all PDF files from input directory"""
        pdf_files = list(self.input_dir.glob("**/*.pdf"))
        self.stats["total_files"] = len(pdf_files)
        print(f"Found {len(pdf_files)} PDF files to process")
        return sorted(pdf_files)

    def process_single_pdf(self, pdf_path):
        """Process a single PDF file"""
        start_time = time.time()
        pdf_name = pdf_path.stem
        output_dir = self.processed_dir / pdf_name
        log_file = self.logs_dir / f"{pdf_name}.log"
        
        print(f"\n[{self.stats['processed'] + self.stats['failed'] + 1}/{self.stats['total_files']}] Processing: {pdf_name}")
        
        try:
            # Check if already processed
            if output_dir.exists() and (output_dir / f"{pdf_name}.md").exists():
                print(f"  ⟳ Skipping (already processed): {pdf_name}")
                self.stats["skipped"] += 1
                return True
            
            # Run MinerU with the correct path
            cmd = [
                "/home/mik/MinerU/mineru_env/bin/magic-pdf",
                "-p", str(pdf_path),
                "-o", str(output_dir),
                "-m", "auto"
            ]
            
            with open(log_file, "w") as log:
                result = subprocess.run(
                    cmd,
                    stdout=log,
                    stderr=subprocess.STDOUT,
                    timeout=600  # 10 minute timeout per PDF
                )
            
            if result.returncode == 0:
                processing_time = time.time() - start_time
                self.stats["processed"] += 1
                self.stats["processing_times"].append(processing_time)
                print(f"  ✓ Success: {pdf_name} ({processing_time:.1f}s)")
                return True
            else:
                raise Exception(f"MinerU returned code {result.returncode}")
                
        except subprocess.TimeoutExpired:
            error_msg = f"Timeout after 10 minutes: {pdf_name}"
            self.handle_error(pdf_path, error_msg)
        except Exception as e:
            error_msg = f"Error processing {pdf_name}: {str(e)}"
            self.handle_error(pdf_path, error_msg)
        
        return False

    def handle_error(self, pdf_path, error_msg):
        """Handle processing errors"""
        print(f"  ✗ Failed: {error_msg}")
        self.stats["failed"] += 1
        self.stats["errors"].append({
            "file": str(pdf_path),
            "error": error_msg,
            "timestamp": datetime.now().isoformat()
        })
        
        # Copy failed PDF to failed directory for inspection
        failed_path = self.failed_dir / pdf_path.name
        if not failed_path.exists():
            subprocess.run(["cp", str(pdf_path), str(failed_path)])

    def process_parallel(self, max_workers=4):
        """Process PDFs in parallel"""
        pdf_files = self.get_pdf_files()
        
        print(f"\nStarting parallel processing with {max_workers} workers")
        print(f"Estimated time: {len(pdf_files) * 3 / max_workers / 60:.1f} hours\n")
        
        with ProcessPoolExecutor(max_workers=max_workers) as executor:
            future_to_pdf = {executor.submit(self.process_single_pdf, pdf): pdf 
                            for pdf in pdf_files}
            
            for future in as_completed(future_to_pdf):
                pdf = future_to_pdf[future]
                try:
                    future.result()
                except Exception as e:
                    self.handle_error(pdf, str(e))

    def save_stats(self):
        """Save processing statistics"""
        self.stats["end_time"] = datetime.now().isoformat()
        
        if self.stats["processing_times"]:
            avg_time = sum(self.stats["processing_times"]) / len(self.stats["processing_times"])
            self.stats["average_processing_time"] = avg_time
        
        with open(self.stats_file, "w") as f:
            json.dump(self.stats, f, indent=2)
        
        # Print summary
        print("\n" + "="*60)
        print("PROCESSING COMPLETE")
        print("="*60)
        print(f"Total PDFs: {self.stats['total_files']}")
        print(f"Successfully processed: {self.stats['processed']}")
        print(f"Failed: {self.stats['failed']}")
        print(f"Skipped (already processed): {self.stats['skipped']}")
        if self.stats["processing_times"]:
            print(f"Average processing time: {avg_time:.1f}s per PDF")
        print(f"\nStats saved to: {self.stats_file}")
        print(f"Logs directory: {self.logs_dir}")
        print(f"Failed PDFs copied to: {self.failed_dir}")

    def run(self, max_workers=4):
        """Main execution method"""
        try:
            self.process_parallel(max_workers)
        finally:
            self.save_stats()

if __name__ == "__main__":
    # Adjust workers based on available resources
    # Use fewer workers if running out of GPU memory
    processor = ThesisBatchProcessor()
    processor.run(max_workers=4)