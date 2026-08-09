#!/usr/bin/env bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 \"Location Name\" LATITUDE LONGITUDE"
    echo "Example: $0 \"Berlin\" 52.5200 13.4050"
    exit 1
fi

NAME="$1"
LAT="$2"
LON="$3"

if ! command -v bc &>/dev/null; then
    echo "Error: 'bc' is required but not installed."
    echo "Please install it using your package manager (e.g., sudo dnf install bc / sudo pacman -S bc)."
    exit 1
fi

# Convert degrees to radians & enforce leading zeros
PI=$(echo "scale=10; 4*a(1)" | bc -l)
LAT_RAD=$(echo "scale=10; $LAT * $PI / 180" | bc -l | sed 's/^\./0./; s/^-\./-0./')
LON_RAD=$(echo "scale=10; $LON * $PI / 180" | bc -l | sed 's/^\./0./; s/^-\./-0./')

# Exact GVariant entry for libgweather-4 as a variant (< ... >)
NEW_ENTRY="<(uint32 2, <('$NAME', '', false, [($LAT_RAD, $LON_RAD)], @a(dd) [])>)>"

# Check if Flatpak or native app is being used
IS_FLATPAK=false
if flatpak list 2>/dev/null | grep -q "org.gnome.Weather"; then
    IS_FLATPAK=true
fi

# Configure GSettings command
if [ "$IS_FLATPAK" = true ]; then
    GSET="flatpak run --command=gsettings org.gnome.Weather"
else
    GSET="gsettings"
fi

# Fetch current locations
CURRENT_LOCS=$($GSET get org.gnome.Weather locations 2>/dev/null)

if [ -z "$CURRENT_LOCS" ] || [ "$CURRENT_LOCS" = "@av []" ] || [ "$CURRENT_LOCS" = "[]" ]; then
    UPDATED_LOCS="[$NEW_ENTRY]"
else
    TRIMMED="${CURRENT_LOCS%]}"
    UPDATED_LOCS="${TRIMMED}, ${NEW_ENTRY}]"
fi

# Write to GSettings
if $GSET set org.gnome.Weather locations "$UPDATED_LOCS"; then
    echo "Successfully added '$NAME' ($LAT, $LON) to GNOME Weather!"
else
    echo "Error: Failed to write GSettings key."
    exit 1
fi

# Restart the application
echo "Restarting GNOME Weather..."
pkill -f gnome-weather 2>/dev/null
flatpak kill org.gnome.Weather 2>/dev/null

sleep 0.5

if [ "$IS_FLATPAK" = true ]; then
    flatpak run org.gnome.Weather >/dev/null 2>&1 &
elif command -v gnome-weather &>/dev/null; then
    gnome-weather >/dev/null 2>&1 &
fi

exit 0
