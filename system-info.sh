#!/bin/bash
echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "OS: $(uname -s)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
echo "Disk usage:"
df -h / | tail -1
echo "Memory:"
free -h 2>/dev/null || vm_stat 2>/dev/null || echo "(not available on this OS)"
echo "Current user: $(whoami)"
echo "Date: $(date)"



