#!/bin/bash
# Script to configure displays for mirrored 1080p output on boot
# Handles single and multiple monitor setups

# Wait for X server to be ready
sleep 2

# Get list of connected displays
DISPLAYS=$(xrandr | grep " connected" | awk '{print $1}')
DISPLAY_COUNT=$(echo "$DISPLAYS" | wc -l)

# If no displays detected, exit
if [ $DISPLAY_COUNT -eq 0 ]; then
    exit 0
fi

# Get the first display as primary
PRIMARY=$(echo "$DISPLAYS" | head -n 1)

# Set primary display to 1920x1080
xrandr --output "$PRIMARY" --mode 1920x1080 --primary

# If there are multiple displays, mirror them
if [ $DISPLAY_COUNT -gt 1 ]; then
    # Mirror all other displays to the primary
    echo "$DISPLAYS" | tail -n +2 | while read -r DISPLAY; do
        # Try to set to 1920x1080, if it fails, use --auto then --scale
        if xrandr --output "$DISPLAY" --mode 1920x1080 --same-as "$PRIMARY" 2>/dev/null; then
            echo "Mirrored $DISPLAY at 1920x1080"
        else
            # If 1920x1080 is not available, use auto mode and scale
            xrandr --output "$DISPLAY" --auto --same-as "$PRIMARY" --scale-from 1920x1080
            echo "Mirrored $DISPLAY with scaling"
        fi
    done
fi

# Force refresh
xrandr --auto
