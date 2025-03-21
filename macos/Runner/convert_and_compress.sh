#!/bin/bash
export PATH="/opt/homebrew/bin:$PATH"

DIR="$1"
QUALITY="$2"
FORMAT="$3"

# Validate inputs
if [ -z "$DIR" ] || [ -z "$QUALITY" ] || [ -z "$FORMAT" ]; then
  echo "❌ Error: Missing arguments."
  echo "Usage: $0 <directory> <quality (1-100)> <jpeg|png>"
  exit 1
fi

if [[ ! $QUALITY =~ ^[0-9]+$ ]] || [ "$QUALITY" -lt 1 ] || [[ "$QUALITY" -gt 100 ]]; then
  echo "❌ Error: Quality must be between 1-100."
  exit 1
fi

if [[ "$FORMAT" != "jpeg" && "$FORMAT" != "png" ]]; then
  echo "❌ Error: FORMAT must be 'jpeg' or 'png'."
  exit 1
fi

OUTCOME_DIR="$DIR/outcome"
mkdir -p "$OUTCOME_DIR"

echo "📁 Output folder: $OUTCOME_DIR"
echo "🔍 Searching for HEIC files in: $DIR"

FILES=("$DIR"/*.[hH][eE][iI][cC])
TOTAL_FILES=${#FILES[@]}

if [ "$TOTAL_FILES" -eq 0 ]; then
  echo "⚠️ No HEIC files found in: $DIR"
  exit 0
fi

echo "📦 Found $TOTAL_FILES HEIC files."

# Check if ImageMagick is installed
if ! command -v magick &> /dev/null; then
  echo "❌ Error: ImageMagick (magick) is not installed."
  exit 1
fi

if [ "$FORMAT" = "png" ] && ! command -v pngquant &> /dev/null; then
  echo "⚠️ Warning: pngquant not installed, PNG compression may not be optimal."
fi

# Progress bar
update_progress() {
  local completed=$1
  local total=$2
  local progress=$(( (completed * 100) / total ))
  printf "\r=> Progress: %d%%" "$progress"
}

# Convert and compress
counter=0
for file in "$DIR"/*.[hH][eE][iI][cC]; do
  if [ -f "$file" ]; then
    counter=$((counter + 1))
    base_name=$(basename "$file" .HEIC)
    base_name=$(basename "$base_name" .heic)
    output_file="$OUTCOME_DIR/$base_name.$FORMAT"

    echo -e "\n⏳ Converting: $file → $output_file"

    # Convert with magick (ImageMagick v7)
    magick "$file" -quality "$QUALITY" "$output_file"

    if [ $? -eq 0 ]; then
      echo "✅ Successfully converted: $output_file"

      if [ "$FORMAT" = "png" ] && command -v pngquant &> /dev/null; then
        echo "⏳ Compressing PNG: $output_file"
        pngquant --quality=$QUALITY --force --output "$output_file" "$output_file"
        echo "🎯 Compressed PNG with pngquant: $output_file"
      fi
    else
      echo "❌ Conversion failed for: $file"
    fi

    update_progress "$counter" "$TOTAL_FILES"
  fi
done

echo -e "\n🎉 All done! Converted files saved in: $OUTCOME_DIR"