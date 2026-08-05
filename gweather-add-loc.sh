#!/usr/bin/env bash

set -euo pipefail

# Check if bc is installed
if ! command -v bc &> /dev/null; then
    echo "Error: 'bc' is not installed. Please install it to run this script (e.g., 'sudo dnf install bc' or 'sudo apt install bc')." >&2
    exit 1
fi

# Argument check
if [ "$#" -ne 3 ]; then
    echo "Usage:" >&2
    echo "  $0 \"Location name\" LATITUDE LONGITUDE" >&2
    echo "" >&2
    echo "Example:" >&2
    echo "  $0 \"Berlin\" 52.5200 13.4050" >&2
    exit 1
fi

NAME="$1"
LAT_DEG="$2"
LON_DEG="$3"

# Validate that coordinates are valid numbers
regex='^-?[0-9]+([.][0-9]+)?$'
if ! [[ "$LAT_DEG" =~ $regex ]] || ! [[ "$LON_DEG" =~ $regex ]]; then
    echo "The coordinates are not valid numbers." >&2
    exit 1
fi

# Range checks (-90 to 90 and -180 to 180)
if (( $(echo "$LAT_DEG < -90.0 || $LAT_DEG > 90.0" | bc -l) )); then
    echo "Latitude must be between -90 and 90 degrees." >&2
    exit 1
fi

if (( $(echo "$LON_DEG < -180.0 || $LON_DEG > 180.0" | bc -l) )); then
    echo "Longitude must be between -180 and 180 degrees." >&2
    exit 1
fi

# Convert degrees to radians & format leading zeroes for GVariant
PI=$(echo "4 * a(1)" | bc -l)
LAT_RAD=$(echo "scale=12; $LAT_DEG * $PI / 180.0" | bc -l | sed 's/^\./0./; s/^-\./-0./')
LON_RAD=$(echo "scale=12; $LON_DEG * $PI / 180.0" | bc -l | sed 's/^\./0./; s/^-\./-0./')

# libgweather-4 / GNOME GVariant structure
GVARIANT_VALUE="[<(uint32 2, <('$NAME', '', false, [($LAT_RAD, $LON_RAD)], @a(dd) [])>)>]"

# Write to GSettings
if gsettings set org.gnome.Weather locations "$GVARIANT_VALUE"; then
    echo "Location added successfully:"
    LC_NUMERIC=C printf "  %s — %.6f, %.6f degrees\n" "$NAME" "$LAT_DEG" "$LON_DEG"
    LC_NUMERIC=C printf "  %.12f, %.12f radians\n\n" "$LAT_RAD" "$LON_RAD"
    echo "GSettings:"
    echo "$GVARIANT_VALUE"

    # Kill running GNOME Weather process to force reloading configuration
    killall gnome-weather 2>/dev/null || true
else
    echo "Failed to write the GSettings key." >&2
    exit 1
fi
