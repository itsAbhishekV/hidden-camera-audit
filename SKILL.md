---
name: hidden-camera-audit
description: Investigate a rental (Airbnb/hotel) for hidden cameras using a MacBook. Scans the authorized Wi-Fi with nmap/arp, identifies vendors and camera services (RTSP/ONVIF), guides physical and IR inspection, and writes a security audit report. Use when the user asks to check an Airbnb/room for hidden cameras or spy devices.
---

# Hidden Camera Audit

Autonomous, honest investigation. Take ownership: analyse every output, decide the next step, never make the user figure it out. Keep instructions concise and technical.

## Rules
- Only scan the network the user is authorized to use (the Wi-Fi they joined). No exploitation, no password guessing, no logging into devices, no capturing streams, no deauth/monitor-mode attacks.
- Never declare the place camera-free from a Wi-Fi scan. Offline SD-card cameras and cameras on separate networks are invisible to it. State this in the report.
- Separate evidence from false positives (see below).
- Run commands yourself with Bash when possible; ask the user to use `! <cmd>` only for sudo/interactive steps.

## Workflow
1. **Run the scan**: `zsh ~/.claude/skills/hidden-camera-audit/scripts/scan.sh` (outputs to `~/airbnb_audit/`). Installs nmap via brew if missing. Does discovery, vendor lookup, camera-port scan, mDNS/SSDP, and a check for camera-style Wi-Fi AP names.
2. **Triage each device**:
   - Randomized (locally administered) MAC (2nd hex digit of first byte is 2/6/A/E): usually a phone/laptop/TV. Low suspicion. Ask which belong to the user.
   - Gateway/ISP vendor (Nokia, TP-Link, etc.) with only admin ports: normal.
   - IoT chip vendors (Espressif, Tuya, Realtek, Ingenic, Hisilicon, Hikvision, Dahua, Reolink, Wyze, Ezviz, Amcrest, Foscam): follow up.
3. **Follow up on suspicious hosts**: `nmap -Pn -sT -sV --top-ports 1000 <ip>` (full `-p-` is very slow without root; avoid unless needed). Camera indicators: 554/8554 (RTSP), 3702 (ONVIF), 37777 (Dahua), 8000 (Hikvision), 34567, 1935, web UI with video/“IPC” titles. You may read banners (`nmap -sV`, `curl -I`), but do not authenticate or pull video.
4. **Cloud-only caveat**: many cheap cameras (Tuya etc.) open no local ports. A silent Espressif/IoT device is *unresolved*, not cleared. Resolve by the unplug test: unplug a suspected object, then `ping -c3 <ip>` / `arp -an | grep <ip>`; if the device disappears, it's identified.
5. **Traffic analysis** (optional, needs sudo, tell user to run with `!`): `sudo tcpdump -i en0 -n host <ip> -c 500`. On client-isolated Wi-Fi a Mac cannot see other clients' traffic; only the router could show a sustained upload. Say so.
6. **Physical inspection** (guide the user step by step):
   - Lights off, curtains closed; sweep with iPhone **front** camera (rear often filters IR) for purple/white IR dots. Test a TV remote first as a known positive.
   - Flashlight sweep for lens glints from multiple angles.
   - Inspect smoke/CO detectors, USB chargers, clocks, outlet plates, speakers, air purifiers, picture frames, tissue boxes, plants, shelves aimed at bed/bathroom, vents, TV/set-top box.
   - Mirror fingertip test (no gap between finger and reflection = possible two-way mirror).
   - Look at the phone Wi-Fi list for AP names like `IPC_`, `CAM-`, `Yi-`, `Tuya`, `SmartLife` (cameras in setup/AP mode).
   - Optional hardware: RF/lens-finder detector for offline or separate-network cameras. Check for hidden/unusual Ethernet or extra routers/switches, and unknown SSIDs.
7. **Ask the user** for results of physical checks and which devices are theirs, then decide the next step yourself.
8. **Report** (write to `~/airbnb_audit/report.md`): scope, method, device table (IP, MAC, vendor, ports, verdict), suspicious devices with evidence, false positives, limitations, overall risk (Low/Medium/High) with justification, and recommended actions (document with photos, notify the platform, contact the host, leave if a camera is in a bedroom/bathroom, local law enforcement if appropriate).

## Evidence vs false positives
- Strong evidence: visible lens or IR emitter; device that vanishes from the network when a specific object is unplugged; RTSP/ONVIF service on an unknown device; camera-vendor MAC.
- Weak/false positives: randomized MACs; TV-remote or motion-sensor LEDs; an Espressif chip alone; port 49152 alone; the ISP router.

## Limitations to always state
Wi-Fi scan only sees devices on that network; client isolation hides peers; offline/SD-card or cellular cameras are not detectable by network scans; IR sweeps miss non-IR cameras in lit rooms.
