#!/usr/bin/env bash
#
# Add a custom location to GNOME Weather (org.gnome.Weather) via gsettings.
# Works with native and Flatpak installations (libgweather-4 GVariant format).

set -u

APP_ID="org.gnome.Weather"
RESTART=true

usage() {
    cat <<USAGE
Usage: $0 [--no-restart] "Location Name" LATITUDE LONGITUDE
Example: $0 "Berlin" 52.5200 13.4050

Coordinates are decimal degrees, latitude first. "." and "," both work as
decimal separator.

The new location is put at the top of the list, which GNOME Shell uses as the
current location.

Options:
  --no-restart   do not restart GNOME Weather after adding the location
  -h, --help     show this help
USAGE
}

# Only --no-restart and -h/--help are options; everything else is positional
# (negative coordinates like -33.8688 must not be mistaken for options).
ARGS=()
for arg in "$@"; do
    case "$arg" in
        -h|--help) usage; exit 0 ;;
        --no-restart) RESTART=false ;;
        *) ARGS+=("$arg") ;;
    esac
done

if [ "${#ARGS[@]}" -ne 3 ]; then
    usage >&2
    exit 1
fi

NAME="${ARGS[0]}"
LAT="${ARGS[1]//,/.}"
LON="${ARGS[2]//,/.}"

# Check dependencies
if ! command -v awk &>/dev/null; then
    echo "Error: 'awk' is required but not installed." >&2
    exit 1
fi

# Validate input
is_number() { [[ "$1" =~ ^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]]; }
in_range()  { LC_ALL=C awk -v v="$1" -v max="$2" 'BEGIN { exit !(v >= -max && v <= max) }'; }

if [ -z "${NAME//[[:space:]]/}" ]; then
    echo "Error: the location name must not be empty." >&2
    exit 1
fi
if ! is_number "$LAT" || ! is_number "$LON"; then
    echo "Error: latitude and longitude must be numbers (e.g. 52.5200 13.4050)." >&2
    exit 1
fi
if ! in_range "$LAT" 90; then
    echo "Error: latitude must be between -90 and 90 (latitude comes first)." >&2
    exit 1
fi
if ! in_range "$LON" 180; then
    echo "Error: longitude must be between -180 and 180." >&2
    exit 1
fi

# Build the GVariant entry
# Degrees -> radians. awk's %f always prints a decimal point and a leading zero
# (e.g. "0.0000000000"), so GVariant parses the values as doubles, not integers.
to_rad() { LC_ALL=C awk -v d="$1" 'BEGIN { printf "%.10f", d * atan2(0, -1) / 180 }'; }
LAT_RAD=$(to_rad "$LAT")
LON_RAD=$(to_rad "$LON")

# Escape backslashes and single quotes so names like "Coeur d'Alene" work.
NAME_ESC=${NAME//\\/\\\\}
NAME_ESC=${NAME_ESC//\'/\\\'}

NEW_ENTRY="<(uint32 2, <('$NAME_ESC', '', false, [($LAT_RAD, $LON_RAD)], @a(dd) [])>)>"

# Check Flatpak or native
IS_FLATPAK=false
GSET=(gsettings)
if command -v flatpak &>/dev/null \
    && flatpak list --app --columns=application 2>/dev/null | grep -qx "$APP_ID"; then
    IS_FLATPAK=true
    GSET=(flatpak run --command=gsettings "$APP_ID")
fi

# Read current locations (abort on failure, never overwrite blindly)
if ! CURRENT_LOCS=$("${GSET[@]}" get "$APP_ID" locations 2>/dev/null); then
    echo "Error: could not read the current locations from GSettings." >&2
    exit 1
fi

if [ -z "$CURRENT_LOCS" ] || [ "$CURRENT_LOCS" = "@av []" ] || [ "$CURRENT_LOCS" = "[]" ]; then
    UPDATED_LOCS="[$NEW_ENTRY]"
else
    # Add at the top: GNOME Shell treats the first entry as the current location
    REST="${CURRENT_LOCS#\[}"
    UPDATED_LOCS="[${NEW_ENTRY}, ${REST}"
fi

# Write
if "${GSET[@]}" set "$APP_ID" locations "$UPDATED_LOCS"; then
    echo "Successfully added '$NAME' ($LAT, $LON) to GNOME Weather!"
else
    echo "Error: failed to write the GSettings key." >&2
    exit 1
fi

# Restart GNOME Weather
if [ "$RESTART" = true ]; then
    echo "Restarting GNOME Weather..."
    if [ "$IS_FLATPAK" = true ]; then
        flatpak kill "$APP_ID" 2>/dev/null
    else
        pkill -f gnome-weather 2>/dev/null
    fi

    sleep 0.5

    if [ "$IS_FLATPAK" = true ]; then
        flatpak run "$APP_ID" >/dev/null 2>&1 &
    elif command -v gnome-weather &>/dev/null; then
        gnome-weather >/dev/null 2>&1 &
    fi
fi

exit 0
