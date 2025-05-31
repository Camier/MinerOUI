#!/bin/bash
STATS_FILE="/home/mik/MinerU/thesis_output/stats/processing_stats.json"

while true; do
    clear
    echo "=== MinerU Batch Processing Monitor ==="
    echo "Time: $(date)"
    echo ""
    
    if [ -f "$STATS_FILE" ]; then
        processed=$(jq -r '.processed // 0' "$STATS_FILE")
        failed=$(jq -r '.failed // 0' "$STATS_FILE")
        total=$(jq -r '.total_files // 0' "$STATS_FILE")
        
        if [ "$total" -gt 0 ]; then
            progress=$((($processed + $failed) * 100 / $total))
            echo "Progress: $progress% ($processed processed, $failed failed out of $total)"
        fi
    fi
    
    echo ""
    echo "GPU Usage:"
    nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader
    
    echo ""
    echo "Recent logs:"
    ls -t /home/mik/MinerU/thesis_output/logs/*.log 2>/dev/null | head -5 | xargs -I {} basename {} .log
    
    sleep 10
done