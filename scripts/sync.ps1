[CmdletBinding()]
param(
    [string]$ManifestPath,
    [string]$InstallRoot,
    [switch]$Pull
)

$ErrorActionPreference = 'Stop'
if (-not $ManifestPath) {
    $ManifestPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'stack.manifest.json'
}

$manifest = Get-Content $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $InstallRoot) { $InstallRoot = $manifest.installRoot }

$rows = @()
foreach ($server in $manifest.servers) {
    if ($server.kind -eq 'external') { continue }
    $dir = Join-Path $InstallRoot $server.dir
    if (-not (Test-Path $dir)) {
        $rows += [pscustomobject]@{ Repo = $server.name; Durum = 'yok'; Iliski = '-'; Dirty = '-' }
        continue
    }
    git -C $dir fetch --prune --quiet 2>$null
    $dirty = @(git -C $dir status --porcelain).Count
    $counts = (git -C $dir rev-list --left-right --count 'HEAD...@{u}' 2>$null) -split "`t"
    if ($counts.Count -lt 2) {
        $rows += [pscustomobject]@{ Repo = $server.name; Durum = 'upstream yok'; Iliski = '-'; Dirty = $dirty }
        continue
    }
    $ahead = [int]$counts[0]
    $behind = [int]$counts[1]
    $iliski = if ($ahead -eq 0 -and $behind -eq 0) { 'esit' } else { "ahead=$ahead behind=$behind" }

    if ($Pull -and $behind -gt 0 -and $dirty -eq 0) {
        git -C $dir pull --ff-only --quiet 2>$null
        if ($LASTEXITCODE -eq 0) { $iliski += ' -> guncellendi'; $behind = 0 }
    }
    $durum = if ($behind -gt 0) { 'geride' } elseif ($ahead -gt 0) { 'ileride' } else { 'guncel' }
    $rows += [pscustomobject]@{ Repo = $server.name; Durum = $durum; Iliski = $iliski; Dirty = $dirty }
}

$rows | Format-Table -AutoSize
$drift = @($rows | Where-Object { $_.Durum -eq 'geride' -or $_.Durum -eq 'yok' }).Count
Write-Host ("Geride/eksik repo sayisi: " + $drift)
if ($drift -gt 0 -and -not $Pull) { Write-Host "Guncellemek icin: .\sync.ps1 -Pull" }
