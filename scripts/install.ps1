[CmdletBinding()]
param(
    [string]$ManifestPath,
    [string]$Root,
    [switch]$SkipClone,
    [switch]$SkipSync,
    [switch]$SkipRegister,
    [switch]$SkipSkills,
    [switch]$SkipSmoke,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $ManifestPath) { $ManifestPath = Join-Path $repoRoot 'stack.manifest.json' }

$manifest = Get-Content $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $Root) { $Root = $manifest.installRoot }

function Get-Tool([string]$name) {
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

function Test-Prerequisites {
    $required = @('git', 'uv')
    $optional = @('gh', 'node', 'java')
    $missing = @()
    foreach ($tool in $required) {
        if (Get-Tool $tool) { Write-Host ("[ok]   " + $tool) } else { Write-Host ("[HATA] " + $tool + " bulunamadi (zorunlu)"); $missing += $tool }
    }
    foreach ($tool in $optional) {
        if (Get-Tool $tool) { Write-Host ("[ok]   " + $tool) } else { Write-Host ("[uyari] " + $tool + " yok (istege bagli)") }
    }
    if ($missing.Count -gt 0) { throw ("Zorunlu araclar eksik: " + ($missing -join ', ')) }
}

Write-Host "== On kosullar =="
Test-Prerequisites
Write-Host ("Kurulum koku: " + $Root)
if ($DryRun) { Write-Host "(DryRun: hicbir sey yazilmaz, sadece plan gosterilir)" }

if (-not (Test-Path $Root)) {
    if ($DryRun) { Write-Host ("[plan] olustur: " + $Root) } else { New-Item -ItemType Directory -Path $Root -Force | Out-Null }
}

Write-Host ""
Write-Host "== Depolar =="
foreach ($server in $manifest.servers) {
    if ($server.kind -eq 'external') { continue }
    $dir = Join-Path $Root $server.dir
    if (Test-Path (Join-Path $dir '.git')) {
        if ($SkipClone) { Write-Host ("[atla] " + $server.name); continue }
        if ($DryRun) { Write-Host ("[plan] fetch+pull: " + $server.name); continue }
        git -C $dir fetch --prune --quiet
        git -C $dir pull --ff-only --quiet
        Write-Host ("[guncel] " + $server.name)
    } else {
        if ($DryRun) { Write-Host ("[plan] clone: " + $server.url + " -> " + $dir); continue }
        if (Test-Path $dir) { throw ("Dizin var ama git deposu degil: " + $dir + " - elle inceleyin") }
        git clone $server.url $dir
        if ($LASTEXITCODE -ne 0) { throw ("Klon basarisiz: " + $server.url + " (private repo icin 'gh auth login' gerekir)") }
        Write-Host ("[klonlandi] " + $server.name)
    }
}

if (-not $SkipSync) {
    Write-Host ""
    Write-Host "== Bagimliliklar (uv sync) =="
    foreach ($server in $manifest.servers) {
        if (-not $server.sync) { continue }
        $dir = Join-Path $Root $server.dir
        if (-not (Test-Path $dir)) { continue }
        $argv = @($server.sync | ForEach-Object { ([string]$_).Replace('${DIR}', $dir) })
        if ($DryRun) { Write-Host ("[plan] " + ($argv -join ' ')); continue }
        & $argv[0] $argv[1..($argv.Count - 1)]
        if ($LASTEXITCODE -ne 0) { Write-Warning ("uv sync basarisiz: " + $server.name) }
        else { Write-Host ("[ok] " + $server.name) }
    }
}

if (-not $SkipRegister) {
    Write-Host ""
    Write-Host "== mcp.json kaydi =="
    $register = Join-Path $PSScriptRoot 'register-mcp.ps1'
    $registerArgs = @{ ManifestPath = $ManifestPath; InstallRoot = $Root }
    if ($DryRun) { $registerArgs['DryRun'] = $true }
    & $register @registerArgs
}

if (-not $SkipSkills) {
    Write-Host ""
    Write-Host "== Skill'ler =="
    $skillsRepo = $manifest.servers | Where-Object { $_.kind -eq 'skills' } | Select-Object -First 1
    if ($skillsRepo) {
        $installer = Join-Path (Join-Path $Root $skillsRepo.dir) 'install.ps1'
        $skillsTarget = [Environment]::ExpandEnvironmentVariables($manifest.skillsTarget)
        if (Test-Path $installer) {
            if ($DryRun) { Write-Host ("[plan] " + $installer + " -Force -Target " + $skillsTarget) }
            else { & $installer -Force -Target $skillsTarget }
        } else {
            Write-Warning ("Skill kurucusu bulunamadi: " + $installer)
        }
    }
}

if (-not $SkipSmoke) {
    Write-Host ""
    Write-Host "== Duman testi =="
    $smoke = Join-Path $repoRoot 'tools\mcp_smoke.py'
    if ($DryRun) {
        Write-Host ("[plan] uv run --no-project python " + $smoke + " --root " + $Root)
    } else {
        uv run --no-project python $smoke --manifest $ManifestPath --root $Root
    }
}

Write-Host ""
Write-Host "Bitti. Command Code'u yeniden baslatip /mcp ile sunuculari dogrulayin."
