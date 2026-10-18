$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$coreDll = Join-Path $PSScriptRoot '..\ProxySuper.Core\bin\Release\ProxySuper.Core.dll'
if (-not (Test-Path $coreDll)) { throw "Core assembly not found: $coreDll" }

# Load the built application assembly and its colocated dependencies.
[void][Reflection.Assembly]::LoadFrom((Resolve-Path $coreDll).Path)

function Assert-True([bool]$condition, [string]$message) {
    if (-not $condition) { throw "ASSERTION FAILED: $message" }
    Write-Host "PASS: $message"
}

function Assert-Throws([scriptblock]$action, [string]$message) {
    $thrown = $false
    try { & $action } catch { $thrown = $true }
    Assert-True $thrown $message
}

# Trojan-Go WebSocket path normalization and invalid-path rejection.
$trojan = New-Object ProxySuper.Core.Models.Projects.TrojanGoSettings
$trojan.Domain = 'proxy.example.com'
$trojan.Password = 'smoke-test-password'
$trojan.WebSocketPath = 'ws'
$trojanJson = [ProxySuper.Core.Services.TrojanGoConfigBuilder]::BuildTrojanGoConfig($trojan) | ConvertFrom-Json
Assert-True ($trojanJson.websocket.path -eq '/ws') 'Trojan-Go WebSocket path receives a leading slash'

$trojan.WebSocketPath = '   '
$trojanJson = [ProxySuper.Core.Services.TrojanGoConfigBuilder]::BuildTrojanGoConfig($trojan) | ConvertFrom-Json
Assert-True ($trojanJson.websocket.path -eq '/') 'Blank Trojan-Go WebSocket path normalizes to /'

$trojan.WebSocketPath = 'ws?token=bad'
Assert-Throws { [ProxySuper.Core.Services.TrojanGoConfigBuilder]::BuildTrojanGoConfig($trojan) | Out-Null } 'Invalid Trojan-Go WebSocket query string is rejected'

# Validate disguise URL parsing, including non-default ports and unsafe schemes.
$trojan.MaskDomain = 'https://mask.example.com:8443/path'
$caddy = [ProxySuper.Core.Services.TrojanGoConfigBuilder]::BuildCaddyConfig($trojan)
Assert-True ($caddy.Contains('https://mask.example.com:8443')) 'Trojan-Go Caddy proxy preserves an explicit HTTPS port'
Assert-True ($caddy.Contains('header_up Host mask.example.com')) 'Trojan-Go Caddy Host header uses the parsed host'

$trojan.MaskDomain = 'file:///etc/passwd'
Assert-Throws { [ProxySuper.Core.Services.TrojanGoConfigBuilder]::BuildCaddyConfig($trojan) | Out-Null } 'Trojan-Go rejects non-HTTP disguise URLs'

$xray = New-Object ProxySuper.Core.Models.Projects.XraySettings
$xray.Domain = 'proxy.example.com'
$xray.MaskDomain = 'https://mask.example.com:9443/path'
$xrayCaddy = [ProxySuper.Core.Services.XrayConfigBuilder]::BuildCaddyConfig($xray)
Assert-True ($xrayCaddy.Contains('https://mask.example.com:9443')) 'Xray Caddy proxy preserves an explicit HTTPS port'
Assert-True ($xrayCaddy.Contains('header_up Host mask.example.com')) 'Xray Caddy Host header uses the parsed host'

$xray.MaskDomain = 'javascript:alert(1)'
Assert-Throws { [ProxySuper.Core.Services.XrayConfigBuilder]::BuildCaddyConfig($xray) | Out-Null } 'Xray rejects non-HTTP disguise URLs'

# Exercise actual Xray gRPC config generation and the empty service-name fallback.
$xray.MaskDomain = 'mask.example.com'
$xray.Types.Clear()
$xray.Types.Add([ProxySuper.Core.Models.Projects.XrayType]::VLESS_gRPC)
$xray.VLESS_gRPC_ServiceName = '   '
$xrayConfig = [ProxySuper.Core.Services.XrayConfigBuilder]::BuildXrayConfig($xray) | ConvertFrom-Json
$grpcInbound = $xrayConfig.inbounds | Where-Object { $_.streamSettings.grpcSettings } | Select-Object -First 1
Assert-True ($null -ne $grpcInbound) 'Xray gRPC inbound is generated'
Assert-True ($grpcInbound.streamSettings.grpcSettings.serviceName -eq 'grpc') 'Empty Xray gRPC service name defaults to grpc'

# Check gRPC share-link encoding and fallback for both V2Ray and Xray links.
$v2ray = New-Object ProxySuper.Core.Models.Projects.V2raySettings
$v2ray.Domain = 'proxy.example.com'
$v2ray.VLESS_gRPC_ServiceName = 'api service/1'
$v2link = [ProxySuper.Core.Services.ShareLink]::Build([ProxySuper.Core.Models.Projects.V2RayType]::VLESS_gRPC, $v2ray)
Assert-True ($v2link -match '(?i)serviceName=api[+]service%2f1') 'V2Ray gRPC service name is URL encoded'

$v2ray.VLESS_gRPC_ServiceName = ' '
$v2link = [ProxySuper.Core.Services.ShareLink]::Build([ProxySuper.Core.Models.Projects.V2RayType]::VLESS_gRPC, $v2ray)
Assert-True ($v2link.Contains('serviceName=grpc')) 'V2Ray gRPC share link defaults empty service name to grpc'

$xray.VLESS_gRPC_ServiceName = 'api service/1'
$xlink = [ProxySuper.Core.Services.ShareLink]::XrayBuild([ProxySuper.Core.Models.Projects.XrayType]::VLESS_gRPC, $xray)
Assert-True ($xlink -match '(?i)serviceName=api[+]service%2f1') 'Xray gRPC service name is URL encoded'

$xray.VLESS_gRPC_ServiceName = ''
$xlink = [ProxySuper.Core.Services.ShareLink]::XrayBuild([ProxySuper.Core.Models.Projects.XrayType]::VLESS_gRPC, $xray)
Assert-True ($xlink.Contains('serviceName=grpc')) 'Xray gRPC share link defaults empty service name to grpc'

Write-Host 'All ProxySU smoke tests passed.'
