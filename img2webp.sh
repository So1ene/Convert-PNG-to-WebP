#!/usr/bin/env bash

# Usage: 
# ./img2webp.sh

# Usage with optional quality parameter: 
# ./img2webp.sh [QUALITY] - (quality 1-100, default: 100)
# Example:
# ./img2webp.sh 80

QUALITY=100
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
set -euo pipefail
[[ -n "${1:-}" ]] && QUALITY="$1"
[[ "$QUALITY" =~ ^[0-9]+$ && "$QUALITY" -ge 1 && "$QUALITY" -le 100 ]] || {
  echo "Error: Quality must be a number between 1 and 100" >&2
  exit 1
}
command -v cwebp >/dev/null || { echo "Error: Install webp (brew install webp)" >&2; exit 1; }
shopt -s nullglob nocaseglob
images=( *.png *.jpg *.jpeg )
shopt -u nocaseglob
(( ${#images} )) || { echo "No images found."; exit 0; }
mkdir -p webp
echo "Converting ${#images[@]} images with quality $QUALITY..."
failed_count=0

for img in "${images[@]}"; do
  out="webp/${img%.*}.webp"
  
  if [[ -e "$out" ]]; then
    echo " —(Press Ctrl+C to cancel script)—"
    echo "File exists: $out - Overwrite? [y/N]:"
    echo -n " > "
    read -r response
    case "$response" in
      [yY]|[yY][eE][sS]) ;;
      *) echo "Skip: $img"; continue ;;
    esac
  fi
  
  if cwebp -q "$QUALITY" -metadata all -mt -quiet "$img" -o "$out" && touch -r "$img" "$out"; then
    echo "OK: $img → $out"
  else
    echo "Failed: $img" >&2
    ((failed_count++))
  fi
done

echo "Done. Converted $((${#images[@]} - failed_count)) images successfully."
[[ $failed_count -gt 0 ]] && echo "Failed: $failed_count images" >&2
