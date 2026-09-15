[CmdletBinding()]
param(
    [string]$ManifestPath,
    [string]$InstallRoot,
    [string]$ConfigPath,
    [string]$OutputPath,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
if (-not $ManifestPath) {
    $ManifestPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'stack.manifest.json'
}

$manifest = Get-Content $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $InstallRoot) { $InstallRoot = $manifest.installRoot }
if (-not $ConfigPath) { $ConfigPath = [Environment]::ExpandEnvironmentVariables($manifest.mcpConfigPath) }

$java = if ($env:SHAMELA_JRE) { $env:SHAMELA_JRE } else { 'java' }

function Expand-Tokens([string]$value) {
    if ($null -eq $value) { return $value }
    return $value.Replace('${INSTALL_ROOT}', $InstallRoot).Replace('${JAVA}', $java)
}

$managed = @{}
foreach ($server in $manifest.servers) {
    if (-not $server.register) { continue }
    $dir = Join-Path $InstallRoot $server.dir
    $entry = [ordered]@{}
    $entry['transport'] = 'stdio'
    $entry['enabled'] = $true
    $entry['command'] = Expand-Tokens $server.command
    $entry['args'] = @($server.args | ForEach-Object { Expand-Tokens (Expand-Tokens $_) })
    $entry['args'] = @($entry['args'] | ForEach-Object { $_.Replace('${DIR}', $dir) })
    $envTable = [ordered]@{}
    foreach ($key in $server.env.PSObject.Properties.Name) {
        $envTable[$key] = Expand-Tokens ([string]$server.env.$key)
    }
    if ($envTable.Count -gt 0) { $entry['env'] = $envTable }
    $managed[$server.name] = $entry
}

$existing = [ordered]@{}
if (Test-Path $ConfigPath) {
    $raw = Get-Content $ConfigPath -Raw -Encoding UTF8
    try {
        $parsed = $raw | ConvertFrom-Json
    } catch {
        throw "mcp.json okunamadi (bozuk JSON): $ConfigPath - $($_.Exception.Message)"
    }
    if ($parsed.mcpServers) {
        foreach ($prop in $parsed.mcpServers.PSObject.Properties) {
            $existing[$prop.Name] = $prop.Value
        }
    }
}

$changed = @()
foreach ($name in $managed.Keys) {
    $existing[$name] = $managed[$name]
    $changed += $name
}

$result = [ordered]@{ mcpServers = $existing }
$json = $result | ConvertTo-Json -Depth 8

if ($DryRun -or $OutputPath) {
    $target = if ($OutputPath) { $OutputPath } else { Join-Path $env:TEMP 'mcp.json.preview' }
    [System.IO.File]::WriteAllText($target, $json, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Onizleme yazildi: $target"
    Write-Host ("Yonetilen sunucular: " + ($changed -join ', '))
    return
}

if (Test-Path $ConfigPath) {
    Copy-Item $ConfigPath "$ConfigPath.bak" -Force
}
[System.IO.File]::WriteAllText($ConfigPath, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("mcp.json guncellendi: " + $ConfigPath)
Write-Host ("Yonetilen sunucular: " + ($changed -join ', '))
Write-Host ("Yedek: " + $ConfigPath + ".bak")
