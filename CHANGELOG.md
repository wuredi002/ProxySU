# ProxySU 4.3.2 — Release Notes

## Changes
- Remove the homepage promotional/ad carousel content.
- Update project, help, release and update-check links to the `wuredi002/ProxySU` repository.
- Restore previously requested protocol menu options, including MTProto-Go and V2Ray VLESS WebSocket/mKCP/QUIC entries.
- Keep the VLESS XHTTP, VLESS XTLS (RAW) REALITY and Hysteria2 configuration/share-link improvements from 4.3.1.

## Build and validation
- Windows .NET Framework Release build via MSBuild.
- Configuration and share-link smoke tests run in GitHub Actions.
- Release package includes `ProxySU.zip` and its `ProxySU.sha256` checksum.

## Notes
- GUI interaction and live remote-server protocol deployment have not been exhaustively tested.
