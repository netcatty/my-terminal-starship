# ────────────────────────────────────────────────────────────────
#  Catppuccin Mocha 终端 profile（Windows PowerShell 5.1 专用）
#  由 %USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 点源。
#  PowerShell 7 不走这里:它的 profile 是 D:\program\develop\term\powershell\profile.ps1
#  （$PSHOME = AllUsersAllHosts 层;提示符交给 starship,`$env:PROMPT_IMPL=omp` 可切回 oh-my-posh）。
#  不依赖任何三方模块。
# ────────────────────────────────────────────────────────────────

# ── 1. UTF-8 控制台 ─────────────────────────────────────────────
# 5.1 默认按 GBK 解码子进程输出，git 的中文会乱码；这里统一成 UTF-8。
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
    # 非控制台宿主（ISE / 管道）里没有控制台句柄，忽略
}

# ── 2. 历史 ────────────────────────────────────────────────────
$MaximumHistoryCount = 20000

# ── 3. PSReadLine ──────────────────────────────────────────────
$esc = [char]27
$psrl = Get-Module PSReadLine -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
if ($psrl -and $psrl.Version -ge [version]'2.2.0') {
    Import-Module PSReadLine -ErrorAction SilentlyContinue

    try {
        Set-PSReadLineOption -BellStyle None
        Set-PSReadLineOption -EditMode Windows
        Set-PSReadLineOption -HistorySearchCursorMovesToEnd

        Set-PSReadLineOption -Colors @{
        Default              = "$esc[38;2;205;214;244m"   # text
        Comment              = "$esc[38;2;108;112;134m"   # overlay0
        Keyword              = "$esc[38;2;245;194;231m"   # pink
        String               = "$esc[38;2;166;227;161m"   # green
        Number               = "$esc[38;2;250;179;135m"   # peach
        Type                 = "$esc[38;2;249;226;175m"   # yellow
        Operator             = "$esc[38;2;148;226;213m"   # teal
        Variable             = "$esc[38;2;180;190;254m"   # lavender
        Member               = "$esc[38;2;137;180;250m"   # blue
        Parameter            = "$esc[38;2;203;166;247m"   # mauve
        Error                = "$esc[38;2;243;139;168m"   # red
        Selection            = "$esc[48;2;88;91;112m"     # surface2 底
        InlinePrediction     = "$esc[38;2;88;91;112m"     # 历史预测（暗）
        ListPrediction       = "$esc[38;2;147;153;178m"
        ListPredictionSelected = "$esc[48;2;49;50;68m$esc[38;2;205;214;244m"
        }
    } catch { }

    # 内联预测需要真实控制台的 VT 支持，重定向输出的宿主里会报错，忽略
    try {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
    } catch { }

    try {
        Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        Set-PSReadLineKeyHandler -Key Ctrl+f -Function AcceptSuggestion
    } catch { }
}

# ── 4. 提示符 ──────────────────────────────────────────────────
# 与 PowerShell 7 统一:交给便携版 starship,主题走 D:\data\config\starship.toml。
# 找不到 starship.exe 就保持 PowerShell 自带提示符,不报错(与 pwsh 7 的 profile 同口径)。
# 注意:starship 在 Windows 不认 XDG_CONFIG_HOME,必须显式给 STARSHIP_CONFIG。
$starshipExe = 'D:\program\develop\term\starship\starship.exe'
if (Test-Path $starshipExe) {
    $starshipTheme = Join-Path $(if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }) 'starship.toml'
    if (Test-Path $starshipTheme) { $env:STARSHIP_CONFIG = $starshipTheme }
    # 直接要全文(_-print-full-init):`init powershell` 只输出一行 trampoline,
    # 那一行会让 starship 再被拉一次,白多一次进程。
    Invoke-Expression (& $starshipExe init powershell --print-full-init | Out-String)
}

# ── 5. 顺手别名 ────────────────────────────────────────────────
# 与 pwsh 7 的 profile 保持一致:ll = 详细列表(5.1 自带没有 ll)
if (-not (Get-Alias -Name ll -ErrorAction SilentlyContinue)) {
    Set-Alias -Name ll -Value Get-ChildItem -Scope Global
}