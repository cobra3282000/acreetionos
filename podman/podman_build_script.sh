#!/usr/bin/env bash
set -e

OUTPUT_DIR="$HOME/Documents/iso_output"

echo "=> [1/5] Preparing clean workspaces and output directories..."
sudo rm -rf acreetionos_workspace
mkdir -p acreetionos_workspace
# Ensuring the output directory exists on the host system right now!
mkdir -p "$OUTPUT_DIR"

echo "=> [2/5] Generating optimized Containerfile..."
cat << 'EOF' > acreetionos_workspace/Containerfile
FROM quay.io/archlinux/archlinux:latest

ADD https://raw.githubusercontent.com/AcreetionOS-Code/acreetionos/main/pacman.conf /etc/pacman.conf

RUN pacman -Syyu --noconfirm archiso git grub && \
    pacman -Scc --noconfirm

WORKDIR /workspace
EOF

echo "=> [3/5] Building the Podman builder image AS ROOT..."
sudo podman build --no-cache -t acreetionos-builder -f acreetionos_workspace/Containerfile acreetionos_workspace/

echo "=> [4/5] Executing privileged ISO build pipeline..."
sudo podman run --rm -it --privileged \
  -v /dev:/dev:ro \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v "$(pwd)/acreetionos_workspace:/workspace" \
  -v "$OUTPUT_DIR:/host_output" \
  acreetionos-builder /bin/bash -c "
    echo '=> Cloning AcreetionOS release-1 branch...' &&
    git clone --branch release-1 https://gitlab.acreetionos.org/cobra3282000/acreetionos.git &&
    cd acreetionos &&
    
    echo '=> Stripping useless sudo commands from build scripts...' &&
    sed -i 's/sudo //g' build.sh umount.sh &&
    
    echo '=> Executing build.sh...' &&
    chmod +x *.sh &&
    ./build.sh ;
    
    EXIT_CODE=\$? ;
    
    echo '=> Harvesting generated ISOs for host export...' ;
    find . -name '*.iso' -exec cp -v {} /host_output/ \; || true ;
    find /workspace -name '*.iso' -exec cp -v {} /host_output/ \; || true ;
    
    echo '=> FORCING UNMOUNT to release filesystem locks...' ;
    ./umount.sh || echo '=> Unmount script returned an error, proceeding anyway...' ;
    
    exit \$EXIT_CODE
  "

echo "=> Restoring file ownership to $USER..."
sudo chown -R "$USER":"$USER" "$OUTPUT_DIR"

echo "================================================================="
echo "BUILD COMPLETE. I DEMAND YOU CHECK YOUR OUTPUT DIRECTORY NOW."
echo "Your AcreetionOS ISO has been extracted and is waiting for you at:"
echo "-> $OUTPUT_DIR/"
echo "================================================================="

echo "=> [5/5] FORCED CLEANUP PHASE"
echo "=> NUKING WITH SUDO PRIVILEGES TO OVERRIDE LOCKS!"
sudo rm -rf acreetionos_workspace
echo "=> Workspace completely annihilated. Environment optimized."
