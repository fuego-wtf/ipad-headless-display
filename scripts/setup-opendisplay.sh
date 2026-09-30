#!/bin/zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: setup-opendisplay.sh [--install-mac] [--open-ipad-links] [--verify]
EOF
}

install_mac() {
  local workdir="${TMPDIR:-/tmp}/opendisplay-install"
  mkdir -p "$workdir"
  curl -fsSL https://api.github.com/repos/peetzweg/opendisplay/releases/latest \
    | awk -F'"' '/OpenDisplay\.dmg/{print $4; exit}' > "$workdir/url"
  local url="$(<"$workdir/url")"
  [[ -n "$url" ]] || { echo "Could not find an OpenDisplay release URL" >&2; exit 1; }
  curl -fL "$url" -o "$workdir/OpenDisplay.dmg"
  local mountpoint="$(hdiutil attach "$workdir/OpenDisplay.dmg" -nobrowse | awk '/\/Volumes\//{print $3; exit}')"
  [[ -d "$mountpoint/OpenDisplay.app" ]] || { echo "OpenDisplay.app not found" >&2; exit 1; }
  ditto "$mountpoint/OpenDisplay.app" /Applications/OpenDisplay.app
  hdiutil detach "$mountpoint" >/dev/null
  open -g -a OpenDisplay
}

open_ipad_links() {
  open 'https://apps.apple.com/app/id6754265378'
  open 'https://testflight.apple.com/join/3NYaY11c'
}

verify() {
  [[ -d /Applications/OpenDisplay.app ]] && echo "sender: installed" || echo "sender: missing"
  system_profiler SPUSBDataType 2>/dev/null | rg -qi 'iPad|Apple' && echo "iPad USB: detected" || echo "iPad USB: not detected"
  local log="$HOME/Library/Logs/OpenDisplay/opendisplay.log"
  [[ -f "$log" ]] && tail -80 "$log" | rg 'Extending to iPad|Mirroring to iPad|Connection lost|Failed to find any displays|virtual display created' || echo "OpenDisplay log: not found"
}

[[ $# -gt 0 ]] || { usage; exit 0; }
for arg in "$@"; do
  case "$arg" in
    --install-mac) install_mac ;;
    --open-ipad-links) open_ipad_links ;;
    --verify) verify ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $arg" >&2; usage; exit 2 ;;
  esac
done
