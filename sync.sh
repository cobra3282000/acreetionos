#!/usr/bin/env bash
# ==========================================================
# AcreetionOS Git Mirror Sync Script
# Mirrors source repo → destination repo via SSH
# Author: Natalie
# ==========================================================

set -e  # Exit immediately if a command exits with a non-zero status

# --- Configuration ---
SOURCE_REPO="git@github.com:cobra3282000/acreetionos.git"
DEST_REPO="git@github.com:AcreetionOS-Linux/acreetionos.git"
WORKDIR="$HOME/Projects/acreetionos"

# --- Functions ---
log() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1" >&2
    exit 1
}

# --- Start ---
log "Starting AcreetionOS repository mirror process..."

# Clean up old working directory if it exists
if [ -d "$WORKDIR" ]; then
    log "Removing old working directory..."
    rm -rf "$WORKDIR"
fi

# Clone source repository (mirror)
log "Cloning source repository..."
git clone --mirror "$SOURCE_REPO" "$WORKDIR" || error "Failed to clone source repository."

cd "$WORKDIR"

# Add destination remote
log "Adding destination remote..."
git remote add destination "$DEST_REPO" || error "Failed to add destination remote."

# Fetch latest from source
log "Fetching updates from source..."
git fetch --all --prune || error "Failed to fetch updates."

# Push mirrored data to destination
log "Pushing all refs to destination..."
git push --mirror destination || error "Failed to push to destination."

log "✅ Sync complete: Destination repository updated successfully."
