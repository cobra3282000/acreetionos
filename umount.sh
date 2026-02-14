#!/bin/bash
# AcreetionOS Build Cleanup Script

WORK_DIR="work/x86_64/airootfs"

echo "--- Starting AcreetionOS Cleanup ---"

# 1. Unmount virtual filesystems in reverse order
# We use -l (lazy) to detach them even if they are 'busy'
echo "[*] Unmounting virtual filesystems..."
sudo umount -l "$WORK_DIR/proc" 2>/dev/null
sudo umount -l "$WORK_DIR/sys" 2>/dev/null
sudo umount -l "$WORK_DIR/dev/pts" 2>/dev/null
sudo umount -l "$WORK_DIR/dev" 2>/dev/null
sudo umount -l "$WORK_DIR/run" 2>/dev/null

# 2. Check for any lingering bind mounts
if mount | grep "$WORK_DIR" > /dev/null; then
    echo "[!] Warning: Some mounts are still active. Attempting recursive unmount..."
    sudo umount -R "work/" 2>/dev/null
fi

# 3. Now it is safe to remove the work directory
echo "[*] Clearing work directory..."
sudo rm -rf work/

echo "--- G7/7910 Nodes Clear for Next Build ---"
