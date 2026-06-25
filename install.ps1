#Requires -Version 5.1
<#
.SYNOPSIS
    ftree をインストール／アンインストールする。
.DESCRIPTION
    同じフォルダにある ftree.ps1 を PowerShell 起動時に自動読込するよう、
    ユーザープロファイル(全ホスト共通 profile.ps1)へマーカー付きで追記する。
    Windows PowerShell 5.1 と PowerShell 7 の両方に対応(フォルダが在る方へ書く)。
    再実行しても二重登録しない。-Uninstall で取り消す。
.EXAMPLE
    .\install.ps1
.EXAMPLE
    .\install.ps1 -Uninstall
#>
[CmdletBinding()]
param([switch]$Uninstall)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ftreePath = Join-Path $scriptDir 'ftree.ps1'
if (-not (Test-Path $ftreePath)) { throw "ftree.ps1 が見つかりません: $ftreePath" }

$marker  = '# >>> ftree >>>'
$endMark = '# <<< ftree <<<'
$block   = "$marker`r`nif (Test-Path `"$ftreePath`") { . `"$ftreePath`" }`r`n$endMark"

# BOM 無し UTF-8 で読み書き(プロファイル先頭以外に BOM を混ぜない)
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Read-All([string]$p) { if (Test-Path $p) { [IO.File]::ReadAllText($p) } else { '' } }
function Write-All([string]$p, [string]$t) { [IO.File]::WriteAllText($p, $t, $utf8) }

# 対象 profile.ps1(全ホスト共通)を集める: 実行中エディション + フォルダが在るエディション
$docs    = [Environment]::GetFolderPath('MyDocuments')
$current = $PROFILE.CurrentUserAllHosts
$targets = New-Object System.Collections.Generic.List[string]
$targets.Add($current)
foreach ($p in @((Join-Path $docs 'WindowsPowerShell\profile.ps1'),
                 (Join-Path $docs 'PowerShell\profile.ps1'))) {
    if ((Test-Path (Split-Path $p -Parent)) -and -not $targets.Contains($p)) { $targets.Add($p) }
}

$rx = [regex]::Escape($marker) + '.*?' + [regex]::Escape($endMark)
foreach ($path in $targets) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $content = Read-All $path
    $has = $content -match [regex]::Escape($marker)

    if ($Uninstall) {
        if ($has) {
            $new = [regex]::Replace($content, $rx, '', 'Singleline').Trim()
            Write-All $path $new
            Write-Host "removed:  $path" -ForegroundColor Yellow
        }
        continue
    }

    if ($has) {
        Write-Host "skip(already): $path" -ForegroundColor DarkGray
    } else {
        $sep = if ($content.Trim()) { "`r`n`r`n" } else { '' }
        Write-All $path ($content.TrimEnd() + $sep + $block + "`r`n")
        Write-Host "installed: $path" -ForegroundColor Green
    }
}

if (-not $Uninstall) {
    . $ftreePath   # 実行中セッションにも反映
    Write-Host ''
    Write-Host '完了。新しい PowerShell を開くか  . $PROFILE  で有効化。例: ftree *.cs' -ForegroundColor Cyan
}