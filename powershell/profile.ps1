# AllUsersAllHosts profile(位于 pwsh 安装目录,$PSHOME):跟着 D:\program\develop 一起迁移。
# 提示符默认交给便携版 starship(..\starship);$env:PROMPT_IMPL=omp 可切回 oh-my-posh(..\omp)。
# 两个都找不到就保持 PowerShell 默认,不报错。

# 从 Git Bash/MSYS 启动的进程会继承 OSTYPE=cygwin,pwsh 再往下传给 pane;
# oh-my-posh 看到它会把 init 脚本路径转成 /c/... 而加载失败(提示符退回 PowerShell 默认)。
# 只清这一个变量:实测 TMP=/tmp、SHELL=/usr/bin/bash.exe 都不影响 omp。
if ($env:OSTYPE -eq 'cygwin') { Remove-Item Env:OSTYPE -ErrorAction SilentlyContinue }

# ── 提示符实现:starship(默认) / omp ─────────────────────────────
# 持久切换:setx PROMPT_IMPL omp(或 starship),然后重开窗口。
# 别同时初始化两个:它们都会接管 prompt 和 PSReadLine 的 Enter 绑定,会打架。
$promptImpl = $env:PROMPT_IMPL
if (-not $promptImpl) { $promptImpl = 'starship' }

$starshipExe = Join-Path $PSScriptRoot '..\starship\starship.exe'
$ompExe = Join-Path $PSScriptRoot '..\omp\oh-my-posh.exe'
$ompTheme = Join-Path $PSScriptRoot '..\omp\catppuccin-mocha.omp.json'

if ($promptImpl -eq 'omp') {
    if (Test-Path $ompExe) {
        $ompArgs = @('init', 'pwsh')
        if (Test-Path $ompTheme) {
            $ompArgs += @('--config', $ompTheme)
        }
        & $ompExe @ompArgs | Invoke-Expression

        # 关掉 omp 的 transient prompt：否则每次回车都会把上一条完整提示符就地改写成一行
        # 短提示符（主题里的 transient_prompt，默认是 mauve 的 "<目录名>" 胶囊），
        # 回看历史时只剩一排短胶囊。omp init 生成的脚本每次都会把它设回 $true，
        # 所以必须在 init 之后覆盖。主题里的 transient_prompt 保留不动，
        # 万一别处又把它打开，至少还是那个胶囊而不是 omp 默认的 "pwsh> "。
        $global:_ompTransientPrompt = $false
    }
}
elseif (Test-Path $starshipExe) {
    # starship 自己不看 XDG_CONFIG_HOME（本机实测:放在那里不会被自动发现），
    # 所以显式指定主题；位置跟着 dotfiles 走:$XDG_CONFIG_HOME\starship.toml
    $starshipTheme = Join-Path $(if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }) 'starship.toml'
    if (Test-Path $starshipTheme) { $env:STARSHIP_CONFIG = $starshipTheme }

    Invoke-Expression (& $starshipExe init powershell)
}

# ── 顺手别名 ─────────────────────────────────────────────────
# ll = 详细列表(Git Bash 的习惯;pwsh 自带的 ls/dir 是 Get-ChildItem 的别名,没有 ll)
if (-not (Get-Alias -Name ll -ErrorAction SilentlyContinue)) {
    Set-Alias -Name ll -Value Get-ChildItem -Scope Global
}

# ── 目录名配色 ─────────────────────────────────────────────
# PS 7 默认给目录名加蓝底(ESC[44;1m),跟 catppuccin 提示符不搭;
# 改成纯蓝前景色,颜色由终端主题的 blue 决定(跟提示符的蓝同源)。
if ($PSStyle) { $PSStyle.FileInfo.Directory = $PSStyle.Foreground.Blue }
