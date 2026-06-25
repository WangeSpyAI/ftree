<#
.SYNOPSIS
    検索条件に一致したファイルだけをツリー表示する（標準 tree の枝刈り版）。

.DESCRIPTION
    Get-ChildItem で対象ファイルを集め、一致したファイルへ至る経路のディレクトリ
    だけを残してツリーを再構築する（マッチを含まない空ディレクトリは出さない）。

.PARAMETER Pattern
    表示するファイル名のワイルドカード。複数可。既定は * （全ファイル＝tree /F 相当）。

.PARAMETER Path
    起点ディレクトリ。既定はカレント。

.PARAMETER Exclude
    たどらないディレクトリ名。既定は bin / obj / .git / node_modules。

.PARAMETER ShowSize
    各ファイルにサイズを付ける。

.EXAMPLE
    ftree *.cs
.EXAMPLE
    ftree *.cs,*.xaml src -Exclude bin,obj,packages
.EXAMPLE
    ftree *.md -ShowSize
#>
function Show-FileTree {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string[]] $Pattern = @('*'),

        [Parameter(Position = 1)]
        [string] $Path = '.',

        [string[]] $Exclude = @('bin', 'obj', '.git', 'node_modules'),

        [switch] $ShowSize
    )

    $resolved = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
    if (-not $resolved) { Write-Error "パスが見つかりません: $Path"; return }
    $root = $resolved.Path

    $tree  = @{}   # ネストしたハッシュテーブル（葉=空のハッシュ=ファイル）
    $sizes = @{}   # 相対パス -> バイト数
    $count = 0

    Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        $rel   = $_.FullName.Substring($root.Length).TrimStart('\')
        $parts = $rel -split '\\'

        # ディレクトリ区間に除外名が含まれたら捨てる
        if ($parts.Count -gt 1) {
            $dirParts = $parts[0..($parts.Count - 2)]
            if ($dirParts | Where-Object { $Exclude -contains $_ }) { return }
        }

        # ファイル名がどれかのパターンに一致しなければ捨てる
        $name = $_.Name
        if (-not ($Pattern | Where-Object { $name -like $_ })) { return }

        $node = $tree
        foreach ($p in $parts) {
            if (-not $node.ContainsKey($p)) { $node[$p] = @{} }
            $node = $node[$p]
        }
        $sizes[$rel] = $_.Length
        $count++
    }

    function Format-Size([long] $bytes) {
        if ($bytes -ge 1GB) { return ('{0:N1}G' -f ($bytes / 1GB)) }
        if ($bytes -ge 1MB) { return ('{0:N1}M' -f ($bytes / 1MB)) }
        if ($bytes -ge 1KB) { return ('{0:N1}K' -f ($bytes / 1KB)) }
        return "${bytes}B"
    }

    function Write-Node($node, $prefix, $relPath) {
        $keys  = @($node.Keys)
        $dirs  = @($keys | Where-Object { $node[$_].Count -gt 0 } | Sort-Object)
        $files = @($keys | Where-Object { $node[$_].Count -eq 0 } | Sort-Object)
        $ordered = $dirs + $files   # ディレクトリ先・ファイル後、各々アルファベット順

        for ($i = 0; $i -lt $ordered.Count; $i++) {
            $key   = $ordered[$i]
            $last  = ($i -eq $ordered.Count - 1)
            $conn  = if ($last) { '└── ' } else { '├── ' }
            $isDir = $node[$key].Count -gt 0
            $childRel = if ($relPath) { "$relPath\$key" } else { $key }

            $label = $key
            if (-not $isDir -and $ShowSize) {
                $label = "$key  ($(Format-Size $sizes[$childRel]))"
            }

            if ($isDir) {
                Write-Host "$prefix$conn" -NoNewline
                Write-Host $label -ForegroundColor Cyan
                $childPrefix = if ($last) { "$prefix    " } else { "$prefix│   " }
                Write-Node $node[$key] $childPrefix $childRel
            }
            else {
                Write-Host "$prefix$conn$label"
            }
        }
    }

    Write-Host (Split-Path $root -Leaf) -ForegroundColor Cyan
    Write-Node $tree '' ''
    Write-Host ''
    Write-Host "$count file(s)  pattern: $($Pattern -join ', ')" -ForegroundColor DarkGray
}

Set-Alias -Name ftree -Value Show-FileTree