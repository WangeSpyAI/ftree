# ftree web installer (bootstrap). Downloads ftree into %LOCALAPPDATA%\ftree and wires your PowerShell profile.
#   Public repo : irm https://raw.githubusercontent.com/WangeSpyAI/ftree/main/web-install.ps1 | iex
#   Private repo: needs GitHub CLI (gh auth login); the script auto-falls back to gh.
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repo   = 'WangeSpyAI/ftree'
$branch = 'main'
$dir    = Join-Path $env:LOCALAPPDATA 'ftree'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

function Get-RepoFile([string]$name, [string]$out) {
    $raw = "https://raw.githubusercontent.com/$repo/$branch/$name"
    try {
        Invoke-WebRequest -Uri $raw -OutFile $out -UseBasicParsing -ErrorAction Stop
        Write-Host "downloaded (raw): $name"
        return
    } catch {}
    $gh = (Get-Command gh -ErrorAction SilentlyContinue).Source
    if (-not $gh) {
        throw "Cannot fetch '$name' (repo is private). Install GitHub CLI, run 'gh auth login', then retry."
    }
    $b64 = (& $gh api "repos/$repo/contents/$($name)?ref=$branch" --jq '.content') -replace '\s', ''
    [IO.File]::WriteAllBytes($out, [Convert]::FromBase64String($b64))
    Write-Host "downloaded (gh): $name"
}

Get-RepoFile 'ftree.ps1'   (Join-Path $dir 'ftree.ps1')
Get-RepoFile 'install.ps1' (Join-Path $dir 'install.ps1')

Write-Host "running installer..."
& (Join-Path $dir 'install.ps1')
