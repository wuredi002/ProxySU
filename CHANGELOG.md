# ProxySU 4.3.1 — Release Notes

> Status: validation build on `master`; not yet a tagged GitHub release.

## Protocols
- Include VLESS XHTTP configuration controls, Xray server configuration, and share-link generation.
- Include VLESS XTLS (RAW) REALITY configuration controls, key generation, server configuration, and share-link generation.
- Use Hysteria2 configuration templates and `hysteria2://` share links.

## Fixes
- Normalize Trojan-Go WebSocket paths: empty values become `/`, missing leading slashes are added, and query/fragment or whitespace-containing paths are rejected.
- Parse Trojan-Go and Xray disguise URLs using URI validation, preserving explicit non-default ports and rejecting non-HTTP(S) schemes.
- Default blank Xray gRPC service names to `grpc` and URL-encode gRPC service names in V2Ray/Xray share links.

## Build and validation
- Target Windows .NET Framework Release builds with MSBuild.
- Run configuration/share-link smoke tests in GitHub Actions and upload the build output as an artifact.
- The CI workflow is not a formal release pipeline; no GitHub Release or tag is created by this change.

## Known follow-up
- Upgraded SSH.NET from 2023.0.0 to 2026.0.0 and aligned the required cryptography, logging, and runtime NuGet dependencies to address high-severity SSH.NET advisories.
- GUI interaction and live remote-server protocol deployment have not been exhaustively tested.
