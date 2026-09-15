[CmdletBinding()]
param(
    [string]$ManifestPath,
    [string]$InstallRoot,
    [switch]$Smoke
)

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $ManifestPath) { $ManifestPath = Join-Path $repoRoot 'stack.manifest.json' }

$manifest = Get-Content $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $InstallRoot) { $InstallRoot = $manifest.installRoot }

$rows = @()

function Add-Row([string]$bilesen, [string]$durum, [string]$detay) {
    $script:rows += [pscustomobject]@{ Bilesen = $bilesen; Durum = $durum; Detay = $detay }
}

function Resolve-Tool([string]$name) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidates = @(
        (Join-Path $env:ProgramFiles 'GitHub CLI\gh.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\GitHub CLI\gh.exe')
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

foreach ($tool in @(@('git', 'zorunlu'), @('uv', 'zorunlu'), @('gh', 'onerilen'), @('node', 'onerilen'), @('python', 'onerilen'), @('java', 'Shamela icin'))) {
    $path = Resolve-Tool $tool[0]
    if ($path) { Add-Row $tool[0] 'OK' ($path + ' (' + $tool[1] + ')') }
    else { Add-Row $tool[0] 'EKSIK' $tool[1] }
}

$gh = Resolve-Tool 'gh'
if ($gh) {
    $null = & $gh auth status 2>&1
    if ($LASTEXITCODE -eq 0) { Add-Row 'gh auth' 'OK' 'oturum acik' } else { Add-Row 'gh auth' 'EKSIK' 'gh auth login gerekli' }
}

if (Test-Path $InstallRoot) { Add-Row 'kurulum koku' 'OK' $InstallRoot } else { Add-Row 'kurulum koku' 'EKSIK' $InstallRoot }

foreach ($server in $manifest.servers) {
    $dir = Join-Path $InstallRoot $server.dir
    if ($server.kind -eq 'external') {
        if (Test-Path $dir) { Add-Row ($server.name + ' (harici)') 'OK' $dir }
        else { Add-Row ($server.name + ' (harici)') 'ATLANDI' 'dizin yok: istege bagli' }
    } elseif (Test-Path $dir) {
        Add-Row $server.name 'OK' $dir
    } else {
        Add-Row $server.name 'EKSIK' $dir
    }
}

try {
    $resp = Invoke-WebRequest -Uri 'http://127.0.0.1:23119/api/users/0/items?limit=1' -TimeoutSec 4 -UseBasicParsing
    Add-Row 'Zotero yerel API' 'OK' ('HTTP ' + $resp.StatusCode)
} catch {
    Add-Row 'Zotero yerel API' 'EKSIK' 'Zotero acik mi? (Ayarlar > Gelismis > yerel API izni)'
}

$skillsTarget = [Environment]::ExpandEnvironmentVariables($manifest.skillsTarget)
if (Test-Path $skillsTarget) {
    $found = @(Get-ChildItem $skillsTarget -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') } | ForEach-Object { $_.Name })
    Add-Row 'skill hedefi' 'OK' ($skillsTarget + ' -> ' + ($found -join ', '))
} else {
    Add-Row 'skill hedefi' 'EKSIK' $skillsTarget
}

$rows | Format-Table -AutoSize -Wrap
$problem = @($rows | Where-Object { $_.Durum -eq 'EKSIK' }).Count
Write-Host ("Eksik bilesen: " + $problem)

if ($Smoke) {
    Write-Host ""
    Write-Host "== Duman testi =="
    $smokeScript = Join-Path $repoRoot 'tools\mcp_smoke.py'
    uv run --no-project python $smokeScript --manifest $ManifestPath --root $InstallRoot
}

exit ([int]($problem -gt 0))
