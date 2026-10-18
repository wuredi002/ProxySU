# ProxySU 4.3.3 — Release Notes

## Changes
- Change the default primary port for new Xray and V2Ray configurations from fixed port 443 to a randomly selected port in the inclusive range 2000–65535.
- Keep the existing VLESS XHTTP, VLESS XTLS (RAW) REALITY, Hysteria2, share-link, and repository-link improvements.
- Preserve existing saved configuration ports; the random default applies when creating a new settings instance.

## Build and validation
- Windows .NET Framework Release build via MSBuild.
- Configuration and share-link smoke tests run in GitHub Actions.
- Release package includes `ProxySU.zip` and its `ProxySU.sha256` checksum.

## Notes
- GUI interaction and live remote-server protocol deployment have not been exhaustively tested.
- This release note does not claim the separately requested Xray VMESS/VLESS TCP, WebSocket and QUIC protocol restorations are complete.
