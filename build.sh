#!/bin/bash

# Sucharu cursors, macOS inspired cursors based on KDE Breeze and
# Capitaine cursors.
# Copyright (c) 2016 Keefer Rourke <mail@krourke.org> and others.
# Copyright (c) 2021-2022 Himadri Sekhar Basu <hsb10@iitbbs.ac.in>.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

function set_sizes()
{
  # Truncates $SIZES based on the specified max DPI.
  # See https://en.wikipedia.org/wiki/Pixel_density#Named_pixel_densities
  # Args:
  #   $1 = lo, tv, hd, xhd, xxhd, xxxhd
  max_size="$1"
  case $max_size in
    lo)
      SIZES=("${SIZES[@]:0:3}")
      ;;
    tv)
      SIZES=("${SIZES[@]:0:4}")
      ;;
    hd)
      SIZES=("${SIZES[@]:0:5}")
      ;;
    xhd)
      SIZES=("${SIZES[@]:0:6}")
      ;;
    xxhd)
      SIZES=("${SIZES[@]:0:7}")
      ;;
    xxxhd)
      SIZES=("${SIZES[@]}")
      ;;
    *)
      return 1
      ;;
  esac
}


function generate_in()
{
  # Scales cursor specs to create an xcursor.in file for each cursor spec.
  # The xcursor.in file line-format is as follows:
  #   size xhot yhot filename [ms-delay]
  # See `man 1 xcursorgen` for more details.
  #
  # Spec files are a custom format that I created, as follows:
  #   xhot yhot [frames ms-delay]
  mkdir -p "$BUILD_DIR"

  # Generate .in files for static cursors.
  for spec in "$SPECS"/static/*.spec; do
    IFS=" " read -r xhot_spec yhot_spec < "$spec"
    cur_name="$(basename "${spec%.*}")"
    target="$BUILD_DIR/$cur_name.in"
    if [ -f "$target" ]; then rm "$target"; fi
    for size in "${SIZES[@]}"; do
      dim=$(echo "$SVG_DIM*$size" | bc)
      xhot=$(echo "$xhot_spec*$size" | bc)
      yhot=$(echo "$yhot_spec*$size" | bc)
      dim=${dim%.*} xhot=${xhot%.*} yhot=${yhot%.*} # Strip decimals parts if any.
      echo "$dim $xhot $yhot x$size/$cur_name.png" | tee -a "$target"
    done
  done
  # Generate .in files for animated cursors.
  for spec in "$SPECS"/animated/*.spec; do
    IFS=" " read -r xhot_spec yhot_spec frames delay < "$spec"
    cur_name="$(basename "${spec%.*}")"
    target="$BUILD_DIR/$cur_name.in"
    if [ -f "$target" ]; then rm "$target"; fi
    for size in "${SIZES[@]}"; do
      dim=$(echo "$SVG_DIM*$size" | bc)
      xhot=$(echo "$xhot_spec*$size" | bc)
      yhot=$(echo "$yhot_spec*$size" | bc)
      dim=${dim%.*} xhot=${xhot%.*} yhot=${yhot%.*} # Strip decimals parts if any.
      for ((i=0; i < frames ; i++)); do
        i_pad=$(printf "%02d" $i)
        echo "$dim $xhot $yhot x$size/$cur_name-$i_pad.png $delay" | tee -a "$target"
      done
    done
  done
}

function render()
{
  # Renders the source SVGs to PNGs in the $BUILD_DIR.
  # Args:
  #  $1 = 1, 1.5, 2, 2.5, 3, 4, 5, 6, ..
  #  $2 = Aqua, Blue, Dark, Green, Grey, Light, Pink, Purple, Red, Teal, Yellow
  #
  name="x$1"
  variant="$2"
  size=$(echo "$SVG_DIM*$1" | bc)
  dpi=$(echo "$SVG_DPI*$1" | bc)

  size=${size%.*} dpi=${size%.*} # Strip decimal parts if any.

  OUTPUT_DIR="$BUILD_DIR/$variant/$name"
  mkdir -p "$OUTPUT_DIR"

  # Set options for Inkscape depending on version.
  INKSCAPE_OPTS=('-w' "$size" -h "$size" -d "$dpi" )
  case $(inkscape -V | cut -d' ' -f2) in
    # NB: The export option (-e or -o) must be the last option in the INKSCAPE_OPTS array.
    0.*) INKSCAPE_OPTS+=('-z' '-e');; # -z specifies not to launch GUI, -e is export
    1.*) INKSCAPE_OPTS+=('-o');;      # v1.0+ uses no GUI by default, -e replaced by -o
  esac

  for svg_file in "$SRC/svg/$variant"/*.svg; do
    inkscape "${INKSCAPE_OPTS[@]}" "$OUTPUT_DIR/$(basename "${svg_file%.svg}").png" "$svg_file" >>log 2>&1 &
    # allow only to execute $(nproc) jobs in parallel
    if [[ $(jobs -r -p | wc -l) -gt $(nproc) ]]; then
      # wait only for first job
      wait $(jobs -p)
    fi
  done
  wait
}


function assemble()
{
  # Assembles rendered PNGs into a cursor distribution.
  #
  # Args:
  #  $1 = Aqua, Blue, Brown, Dark, Green, Grey, Light, Orange, Pink, Purple, Red, Sand, Teal, Yellow
  variant="$1"

  THEME_NAME="Sucharu"
  DIST_DIRNAME="Sucharu"

  case "$variant" in
    Aqua)
      THEME_NAME="$THEME_NAME-Aqua"
      BASE_DIR="$DIST/$DIST_DIRNAME-Aqua"
      ;;
    Blue)
      THEME_NAME="$THEME_NAME-Blue"
      BASE_DIR="$DIST/$DIST_DIRNAME-Blue"
      ;;
    Brown)
      THEME_NAME="$THEME_NAME-Brown"
      BASE_DIR="$DIST/$DIST_DIRNAME-Brown"
      ;;
    Dark)
      THEME_NAME="$THEME_NAME-Dark"
      BASE_DIR="$DIST/$DIST_DIRNAME-Dark"
      ;;
    Green)
      THEME_NAME="$THEME_NAME-Green"
      BASE_DIR="$DIST/$DIST_DIRNAME-Green"
      ;;
    Grey)
      THEME_NAME="$THEME_NAME-Grey"
      BASE_DIR="$DIST/$DIST_DIRNAME-Grey"
      ;;
    Light)
      THEME_NAME="$THEME_NAME-Light"
      BASE_DIR="$DIST/$DIST_DIRNAME-Light"
      ;;
    Orange)
      THEME_NAME="$THEME_NAME-Orange"
      BASE_DIR="$DIST/$DIST_DIRNAME-Orange"
      ;;
    Pink)
      THEME_NAME="$THEME_NAME-Pink"
      BASE_DIR="$DIST/$DIST_DIRNAME-Pink"
      ;;
    Purple)
      THEME_NAME="$THEME_NAME-Purple"
      BASE_DIR="$DIST/$DIST_DIRNAME-Purple"
      ;;
    Red)
      THEME_NAME="$THEME_NAME-Red"
      BASE_DIR="$DIST/$DIST_DIRNAME-Red"
      ;;
    Sand)
      THEME_NAME="$THEME_NAME-Sand"
      BASE_DIR="$DIST/$DIST_DIRNAME-Sand"
      ;;
    Teal)
      THEME_NAME="$THEME_NAME-Teal"
      BASE_DIR="$DIST/$DIST_DIRNAME-Teal"
      ;;
    Yellow)
      THEME_NAME="$THEME_NAME-Yellow"
      BASE_DIR="$DIST/$DIST_DIRNAME-Yellow"
      ;;
    *) exit 1 ;;
  esac

  OUTPUT_DIR="$BASE_DIR/cursors"
  INDEX_FILE="$BASE_DIR/cursor.theme"

  mkdir -p "$BASE_DIR"
  mkdir -p "$OUTPUT_DIR"

  # Move the .in files and target variant to the root of the build directory
  # so that xcursorgen can find everything it needs.
  cp -r "$BUILD_DIR/$variant"/* "$BUILD_DIR"
  pushd "$BUILD_DIR" > /dev/null || return 1
  for cur_cfg in *.in; do
    cur_name="$(basename "${cur_cfg%.*}")"
    xcursorgen "$cur_cfg" "$OUTPUT_DIR/$cur_name"
  done
  popd > /dev/null || return 1

  pushd "$OUTPUT_DIR" > /dev/null || return 1
  while read -r cur_alias; do
    from="${cur_alias#* }"
    to="${cur_alias% *}"

    if [ -e "$to" ]; then continue; fi

    ln -s "$from" "$to"
  done < "$ALIASES"
  popd > /dev/null || return 1

  # Write the index.theme file.
  if [ ! -e "$INDEX_FILE" ]; then
    touch "$INDEX_FILE"
    echo -e "[Icon Theme]\nName=$THEME_NAME\nInherits=$THEME_NAME\nComment=A stylish cursor for humans" > "$INDEX_FILE"
  fi
  
  # Copy a thumbnail.png to serve as a preview in some environments.
  cp "$SRC/thumbnail/thumbnail-$variant.png" "$OUTPUT_DIR/thumbnail.png"
}


function show_usage()
{
  echo -e "This script builds the mamolinux-cursors."
  echo -e "Minimal Usage: ./build.sh [ -t color-code ]"
  echo -e "Usage: ./build.sh [ -d DPI ] [ -t color-code ] [ -p PLATFORM ]"
  echo -e "Usage: ./build.sh [ -d DPI ] [ -p PLATFORM ]"
  echo -e "  -h, --help\t\tPrint this help"
  echo -e "  -d, --max-dpi\t\tSet the max DPI to render. Higher values take longer."
  echo -e                "\t\t\tOne of (" "${DPIS[@]}" ")."
  echo -e "  -t, --type\t\tSpecify the code for build variant.\n\t\t\t\
Choose the code for colour variant from the list below:\n\t\t\t\
(0) All(Default)\n\t\t\t\
(1) Aqua\t(2) Blue\n\t\t\t\
(3) Brown\t(4) Dark/Black\n\t\t\t\
(5) Green\t(6) Grey\n\t\t\t\
(7) Light/White\t(8) Orange\n\t\t\t\
(9) Pink\t(10) Purple\n\t\t\t\
(11) Red\t(12) Sand\n\t\t\t\
(13) Teal\t(14) Yellow\n"
  echo -e "  -p, --platform\tSpecify the build platform. One of (" "${PLATFORMS[@]}" ")."
}

function validate_option()
{
  valid=0
  case "$1" in
    variant)
      if [[ $2 == '0' ]]; then
        valid=1;
      else
        for variant in "${VARIANTS[@]}"; do
          if [[ ${VARIANTS[$2]} == "$variant" ]]; then
            valid=1
          fi
        done
      fi
      ;;
    platform)
      for platform in "${PLATFORMS[@]}"; do
        if [[ "$2" == "$platform" ]]; then valid=1; fi
      done
      ;;
    *) return 1 ;;
  esac
  test "$valid" -eq 1
  return $?
}

# Check dependencies are present.
DEPENDENCIES=(bc inkscape xcursorgen)
for dep in "${DEPENDENCIES[@]}"; do
  if ! command -v "$dep" >/dev/null; then
    echo "$dep is not installed, exiting."
    echo "Please check README.md how to install them."
    exit 1
  fi
done

# inkscape fails if ulimit is 'unlimited'
ulimit -s 4096

# Let user choose the colour variant
VARIANTS=('Aqua' 'Blue' 'Brown' 'Dark' 'Green' 'Grey' 'Light' 'Orange' 'Pink' 'Purple' 'Red' 'Sand' 'Teal' 'Yellow')

SRC=$PWD/src
DIST=$PWD/usr/share/icons
PLATFORMS=('unix' 'win32')
BUILD_DIR=$PWD/_build
SPECS="$SRC/config"
ALIASES="$SRC/cursor-aliases"
SIZES=('1' '1.25' '1.5' '2' '2.5' '3' '4' '5' '6' '10')
DPIS=('lo' 'tv' 'hd' 'xhd' 'xxhd' 'xxxhd')
SVG_DIM=24
SVG_DPI=96

# Check whether any option has been given
if [ -z $1 ]; then
  show_usage
	echo -e "Your choice does not match with any of the given.\n"
  echo -e "Exiting ...\n"
	exit 1
fi

# Parse options to script.
POSITIONAL_ARGS=()
PLATFORM="${PLATFORMS[0]}"  # Default = unix
MAX_DPI=${DPIS[4]}          # Default = xxhd
while [[ $# -gt 0 ]]; do
  opt="$1"
  case $opt in
    -h|--help)
      show_usage
      exit 0
      ;;
    -d|--max-dpi)
      MAX_DPI="$2"
      shift; shift; # Shift past option and value.
      ;;
    -t|--type)
      VARIANT="$2"
      validate_option 'variant' "$VARIANT" || { show_usage; exit 2; }
      IN=$2
      shift ; shift; # Shift past option and value.
      ;;
    -p|--platform)
      PLATFORM="$2"
      validate_option 'platform' "$PLATFORM" || { show_usage; exit 2; }
      shift; shift; # Shift past option and value.
      ;;
    -*=*)
      echo "Unrecognized argument, use --opt value instead of --opt=value"
      exit 2
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift # Shift past the value.
      ;;
  esac
done
# Restore positional arguments.
set -- "${POSITIONAL_ARGS[@]}"

# Begin the build based on User's choice
set_sizes "$MAX_DPI" || { echo "Unrecognized DPI."; exit 1; }

if [ $IN == 0 ]; then
  generate_in >log
  echo -e "\nBuilding all variants...\n"
  for VARIANT in "${VARIANTS[@]}"; do
    echo -e "Building variant: $VARIANT..."
    for size in "${SIZES[@]}"; do
      echo -e "\tRendering $size"
      render "$size" "$VARIANT"
    done
    assemble "$VARIANT"
    echo -e "Variant \"$VARIANT\" built successfully.\n"
  done
  echo -e "All variants built successfully."
elif [ $IN -gt 0 -a $IN -le 14 ]; then
  generate_in >log
  echo -e "\nBuilding variant: ${VARIANTS[IN-1]}..."
  VARIANT=${VARIANTS[IN-1]}
  for size in "${SIZES[@]}"; do
    echo -e "\tRendering $size"
    render "$size" "$VARIANT"
  done
  assemble "$VARIANT"
  echo -e "Variant \"$VARIANT\" built successfully.\n"
fi

exit 0
