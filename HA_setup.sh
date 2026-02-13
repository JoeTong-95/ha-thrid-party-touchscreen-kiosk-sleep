#!/usr/bin/env bash
set -euo pipefail

echo "=== HA YAML Generator: Kiosk Screen Sleep Control ==="

# Defaults you can change
DEFAULT_KEY="/config/.ssh/id_ed25519"
DEFAULT_TOGGLE="input_boolean.kioskscreen_sleep_on"
DEFAULT_START="input_datetime.sleeptime_start"
DEFAULT_END="input_datetime.sleeptime_off"
DEFAULT_TIMEOUT="30"

read -rp "Kiosk IP (e.g. 192.168.8.120): " KIOSK_IP
read -rp "Kiosk SSH user (e.g. hamonitor): " KIOSK_USER

read -rp "Wayland output name (e.g. DSI-1) [press Enter to use DSI-1]: " OUTPUT
OUTPUT="${OUTPUT:-DSI-1}"

read -rp "Idle timeout seconds [${DEFAULT_TIMEOUT}]: " TIMEOUT
TIMEOUT="${TIMEOUT:-$DEFAULT_TIMEOUT}"

read -rp "HA SSH key path [${DEFAULT_KEY}]: " KEY_PATH
KEY_PATH="${KEY_PATH:-$DEFAULT_KEY}"

read -rp "Toggle entity_id [${DEFAULT_TOGGLE}]: " TOGGLE
TOGGLE="${TOGGLE:-$DEFAULT_TOGGLE}"

read -rp "Sleep start time entity_id [${DEFAULT_START}]: " START_TIME
START_TIME="${START_TIME:-$DEFAULT_START}"

read -rp "Sleep end time entity_id [${DEFAULT_END}]: " END_TIME
END_TIME="${END_TIME:-$DEFAULT_END}"

echo ""
read -rp "Generate SSH key at ${KEY_PATH} if missing? (y/n) [n]: " DO_KEY
DO_KEY="${DO_KEY:-n}"

if [[ "${DO_KEY}" =~ ^[Yy]$ ]]; then
  SSH_DIR="$(dirname "${KEY_PATH}")"
  mkdir -p "${SSH_DIR}"
  chmod 700 "${SSH_DIR}"

  if [[ ! -f "${KEY_PATH}" ]]; then
    echo "Generating key..."
    ssh-keygen -t ed25519 -f "${KEY_PATH}" -N ""
  else
    echo "Key already exists, skipping generation."
  fi

  echo ""
  echo "Next (manual): copy the public key to the kiosk once:"
  echo "ssh-copy-id -i ${KEY_PATH}.pub ${KIOSK_USER}@${KIOSK_IP}"
fi

echo ""
echo "==================== PASTE INTO configuration.yaml ===================="
cat <<EOF
shell_command:
  kiosk_screen_sleep_on: >
    ssh -i ${KEY_PATH} -o StrictHostKeyChecking=no ${KIOSK_USER}@${KIOSK_IP}
    "pkill swayidle || true; /usr/bin/swayidle -w timeout ${TIMEOUT} '/usr/bin/wlr-randr --output ${OUTPUT} --off' resume '/usr/bin/wlr-randr --output ${OUTPUT} --on' &"

  kiosk_screen_sleep_off: >
    ssh -i ${KEY_PATH} -o StrictHostKeyChecking=no ${KIOSK_USER}@${KIOSK_IP}
    "pkill swayidle || true; /usr/bin/wlr-randr --output ${OUTPUT} --on"
EOF

echo ""
echo "==================== AUTOMATIONS (YAML SNIPPETS) ======================"
cat <<EOF
# 1) Toggle ON → enable ${TIMEOUT}s sleep
alias: Kiosk - toggle ON enables sleep
trigger:
  - platform: state
    entity_id: ${TOGGLE}
    to: "on"
action:
  - service: shell_command.kiosk_screen_sleep_on
mode: restart

# 2) Toggle OFF → disable sleep
alias: Kiosk - toggle OFF disables sleep
trigger:
  - platform: state
    entity_id: ${TOGGLE}
    to: "off"
action:
  - service: shell_command.kiosk_screen_sleep_off
mode: restart

# 3) Scheduled start flips toggle ON
alias: Kiosk - scheduled sleep start
trigger:
  - platform: time
    at: ${START_TIME}
action:
  - service: input_boolean.turn_on
    target:
      entity_id: ${TOGGLE}
mode: single

# 4) Scheduled end flips toggle OFF
alias: Kiosk - scheduled sleep end
trigger:
  - platform: time
    at: ${END_TIME}
action:
  - service: input_boolean.turn_off
    target:
      entity_id: ${TOGGLE}
mode: single
EOF

echo ""
echo "✅ Done. After pasting shell_command, do: Developer Tools → YAML → Reload Shell Commands."
