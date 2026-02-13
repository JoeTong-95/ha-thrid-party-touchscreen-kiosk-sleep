#!/usr/bin/env bash
set -euo pipefail

echo "=== Kiosk Installer: Wayland sleep support (swayidle + wlr-randr) ==="

# --- helpers ---
need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: missing command '$1'"
    exit 1
  }
}

detect_output() {
  # Prefer DSI-1 if present, else pick first output line that looks like "NAME ..."
  local out
  out="$(wlr-randr | awk '/^[A-Za-z0-9-]+/ {print $1}' | head -n 50)"

  if echo "$out" | grep -qx "DSI-1"; then
    echo "DSI-1"
    return 0
  fi

  # Otherwise first output
  echo "$out" | head -n 1
}

echo "[1/4] Installing packages..."
sudo apt update
sudo apt install -y swayidle wlr-randr

echo "[2/4] Verifying Wayland + wlroots tooling..."
need_cmd wlr-randr
need_cmd swayidle

# wlr-randr must run in a Wayland session (kiosk user session)
if ! wlr-randr >/dev/null 2>&1; then
  echo "ERROR: wlr-randr failed."
  echo "This usually means you're not running this inside a Wayland session."
  echo "Run this from the kiosk user terminal (not SSH TTY without Wayland env)."
  exit 1
fi

echo "[3/4] Auto-detecting display output..."
OUTPUT="$(detect_output)"
if [[ -z "${OUTPUT}" ]]; then
  echo "ERROR: Could not detect any outputs from wlr-randr."
  exit 1
fi

echo "Detected output: ${OUTPUT}"
echo "Saving to: /etc/kiosk-display-output.env"

# Save system-wide so you can reference it later if needed
echo "KIOSK_WLR_OUTPUT=${OUTPUT}" | sudo tee /etc/kiosk-display-output.env >/dev/null

echo "[4/4] Quick functional test (screen off for 2s)..."
wlr-randr --output "${OUTPUT}" --off
sleep 2
wlr-randr --output "${OUTPUT}" --on

echo ""
echo "✅ Kiosk install complete."
echo "Output name: ${OUTPUT}"
echo "Next: run HA script to generate YAML (uses this output)."
