#!/bin/bash
# Quick test to demonstrate the progress bar

echo "Simulating mkarchiso output to test progress bar..."
echo ""

echo "[mkarchiso] INFO: Starting build process"
sleep 1
echo "[mkarchiso] INFO: Installing packages to '/tmp/test/'..."
sleep 1
echo "[mkarchiso] INFO: Copying custom airootfs files..."
sleep 1
echo "[mkarchiso] INFO: Creating SquashFS image, this may take some time..."
sleep 1
echo "[mkarchiso] INFO: Creating checksum file for self-test..."
sleep 1
echo "[mkarchiso] INFO: Creating ISO image..."
sleep 1
echo "[mkarchiso] INFO: Running isohybrid"
sleep 1
echo "[mkarchiso] INFO: Done!"
