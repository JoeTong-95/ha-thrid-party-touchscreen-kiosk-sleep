# home-assistant-thirdpartyTFT_touchscreen-kiosk-sleep
Control a Raspberry Pi touchscreen kiosk sleep/wake behavior directly from Home Assistant.


# About
this is a small change in addition to the touchkio project (https://github.com/leukipp/touchkio), which supports screen dimming with the original Pi display. 

I'm running a third party TFT display ([link](https://www.amazon.com/dp/B0D3QB7X4Z?ref=ppx_yo2ov_dt_b_fed_asin_title&th=1)), and this mod works with any display that are driven by Wayland compositor using wlroots (wlr-randr).


# Architecture
- This project adds a control layer between Home Assistant and the kiosk compositor
- creates a SSH key between a pi running HA, and another driving the display
- add shell layer to send wlr-randr commands
- create automation to let a bool switch to execute shell command


# Setup - Foundation
This repo includes two helper scripts:

- `kiosk_setup.sh` → run on the display / kiosk Pi
- `ha_generate_yaml.sh` → run on the Home Assistant machine

---


Run this on the Raspberry Pi that drives the touchscreen.

```bash
# Navigate to the script directory
cd scripts

# Make executable (first time only)
chmod +x kiosk_setup.sh

# Run installer
./kiosk_setup.sh
```

Do the same for Pi that runs HA for the `HA_setup.sh` file, and paste the generated YAML to `configuration.yaml` on HA, and reload. 


# Setup - HA
- if everything goes right, after reboot, in developer tool - actions, there should now be on and off entries if you search "Kiosk"
- define a boolean helper and configure two automations to call these actions depending on boolean button state
- done!  