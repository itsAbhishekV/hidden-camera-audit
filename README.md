# hidden-camera-audit

A Claude Code skill for checking a rental (Airbnb/hotel) for hidden cameras from a MacBook.

- `SKILL.md`: investigation workflow, evidence vs false positives, report format
- `scripts/scan.sh`: network discovery, vendor lookup, camera-port/mDNS/SSDP checks

Install: copy this folder to `~/.claude/skills/hidden-camera-audit/`.

Use only on networks you are authorized to use. No exploitation. A clean Wi-Fi scan does not prove a place is camera-free.
