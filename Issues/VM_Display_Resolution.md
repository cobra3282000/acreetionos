# VM Display Resolution Issue

## Problem

The display resolution in virtual machines was not being set correctly, leading to a poor user experience.

## Solution

A script was implemented to automatically configure the display resolution when the system boots.

## Implementation Details

1.  A shell script named `setup-displays.sh` was created in `/usr/local/bin/`.
2.  This script uses the `xrandr` command to detect connected displays and automatically set their resolution.
3.  The script was made executable by adding an entry to the `profiledef.sh` file.
4.  LightDM (the display manager) was configured to run this script by editing the `/etc/lightdm/lightdm.conf` file and setting the `display-setup-script`.

This ensures that the display resolution is correctly configured before the login screen appears.
