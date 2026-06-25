# ftree

検索条件に一致したファイルだけをツリー表示する PowerShell コマンド。
標準の `tree /F` と違い、**指定した拡張子のファイルだけ**を残し、マッチを含まない空フォルダは枝刈りして表示します。

```text
> ftree *.cs
tree
├── src
│   ├── Models
│   │   └── User.cs
│   └── Program.cs
└── test
    └── ProgramTest.cs

4 file(s)  pattern: *.cs
```

## 必要環境
- Windows PowerShell 5.1 または PowerShell 7
- cmd.exe（コマンドプロンプト）では動きません

## インストール

```powershell
git clone https://github.com/WangeSpyAI/ftree.git ftree
cd ftree
.\install.ps1
```

`install.ps1` は `ftree.ps1` を PowerShell 起動時に自動読込するよう、ユーザープロファイル（全ホスト共通 `profile.ps1`）へマーカー付きで登録します。Windows PowerShell 5.1 と PowerShell 7 の両方に対応（フォルダが在る方へ書きます）。再実行しても二重登録しません。

インストール後は**新しい PowerShell ウィンドウ**を開くか、現在のウィンドウで `. $PROFILE` を実行すると `ftree` が使えます。

### 手動インストール（プロファイルに1行だけ足す）
```powershell
'. "<ftree.ps1 の絶対パス>"' | Add-Content $PROFILE
```

## 使い方

| コマンド | 説明 |
|---|---|
| `ftree *.cs` | カレント以下の `.cs` だけ |
| `ftree *.cs,*.xaml` | 複数の拡張子 |
| `ftree *.md C:\proj` | 場所を指定 |
| `ftree *.md -ShowSize` | サイズ付き |
| `ftree * . -Exclude bin,obj,.vs` | 全ファイル＋除外フォルダ指定 |

### パラメータ

| 名前 | 位置 | 既定値 | 意味 |
|---|---|---|---|
| `Pattern` | 1 | `*` | 表示するファイル名のワイルドカード（複数可） |
| `Path` | 2 | `.` | 起点ディレクトリ |
| `Exclude` | – | `bin, obj, .git, node_modules` | たどらないフォルダ名 |
| `ShowSize` | – | （スイッチ） | 各ファイルにサイズを付ける |

エイリアス `ftree` は本体関数 `Show-FileTree` を指します。

## アンインストール

```powershell
.\install.ps1 -Uninstall
```

## 仕組み

1. `Get-ChildItem -Recurse -File` で全ファイルを取得
2. `Pattern` に一致し、`Exclude` フォルダを通らないファイルだけを `\` 区切りでネスト辞書に積む
3. 葉＝ファイル／枝＝ディレクトリとして罫線付きで再帰描画（マッチを含まない枝は出ない）

除外はフォルダ名で判定するので、`bin` という名前の**ファイル**は消えません（フォルダ名だけが効く）。

## ライセンス

MIT
