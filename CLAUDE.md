# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AcreetionOS is an Arch Linux-based distribution that creates bootable ISO images using the archiso framework. The project builds a live Linux distribution with Cinnamon desktop environment, targeting x86_64 architecture with custom configurations and packages.

## Build Commands

### Primary Build Process
- **Full build**: `./build.sh` - Cleans workspace and builds ISO
- **Manual build**: `./mkarchiso.sh` - Runs mkarchiso directly
- **Clean workspace**: `./refresh.sh` - Removes work/ and out/ directories

### Build Process Details
1. `refresh.sh` removes previous build artifacts (work/, out/)
2. `mkarchiso.sh` calls the archiso build system with AcreetionOS label
3. Final ISO is output to `../ISO/` directory
4. Build uses custom `pacman.conf` for package management

## Architecture

### Key Configuration Files
- **profiledef.sh**: Main archiso profile configuration defining ISO metadata, boot modes, and file permissions
- **packages.x86_64**: Complete package list for the distribution (250+ packages)
- **pacman.conf**: Custom Pacman configuration for package management
- **bootstrap_packages.x86_64**: Bootstrap packages for initial system

### Directory Structure
- **airootfs/**: Root filesystem overlay that becomes the live system
  - `etc/`: System configuration files
  - `usr/`: User binaries, scripts, and local customizations
  - `root/`: Root user files and installation scripts
  - `cinnamon-configs/`: Desktop environment customizations
- **grub/**: GRUB bootloader configuration
- **syslinux/**: SYSLINUX bootloader configuration
- **efiboot/**: EFI boot configuration

### Key Features
- Uses squashfs compression with xz and x86 BCJ filter optimization
- Supports both BIOS and UEFI boot modes (32-bit and 64-bit)
- Includes Calamares installer (calamares-git package)
- Pre-configured with Cinnamon desktop, Firefox, development tools
- Custom installation and post-installation scripts in airootfs/usr/bin/

### Package Management
The distribution includes:
- Base Arch packages and kernel
- Cinnamon desktop environment
- Development tools (base-devel, git, python, rust, nodejs)
- Hardware support (various firmware packages, drivers)
- System utilities and networking tools
- Custom AUR packages (calamares-git, calamares-config)

## Development Notes

- Build process requires sudo privileges for archiso operations
- ISO builds are resource-intensive and create large work directories
- Package list can be modified by editing packages.x86_64
- Custom scripts and configurations go in airootfs/ overlay
- File permissions are explicitly defined in profiledef.sh