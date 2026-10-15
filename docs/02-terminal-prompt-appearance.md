# /技术/工具/Windows 终端/终端提示符与外观配置

---
title: 终端提示符与外观配置
date: 2026-10-10T19:00:24+08:00
lastmod: 2026-10-15T17:33:58+08:00
---

> **摘要**：本机终端提示符统一走 starship（Catppuccin Mocha，主题在 ​`D:\data\config\starship.toml`​）：pwsh 7 由安装目录的 ​`profile.ps1`​ 加载，Windows PowerShell 5.1 由 ​`~\.config\pwsh\profile.shared.ps1`​ 加载，Git Bash 由 ​`~\.config\git\git-prompt.sh`​ 钩子加载；环境变量 ​`PROMPT_IMPL`​ 设成 ​`omp` 可切回 oh-my-posh。文末附四份全文（两份 profile、主题、钩子）。

# 前置检查

```powershell
# 便携版位置（都在 D:\program\develop\term 下）
& 'D:\program\develop\term\powershell\pwsh.exe' -v            # 期望 7.6.6
& 'D:\program\develop\term\starship\starship.exe' --version   # 期望 starship 1.26.0
& 'D:\program\develop\term\omp\oh-my-posh.exe' --version      # 回退实现，期望 30.1.1

# 主题文件必须在（Git Bash 与 pwsh 共用这一份）
Test-Path 'D:\data\config\starship.toml'                      # 期望 True

# 字体族名必须核实，不能照抄文档
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts").PSObject.Properties |
    Where-Object Name -like '*Maple*' | ForEach-Object { "$($_.Name) => $($_.Value)" }
```

字体可用族名（按本机实际情况选）：

|{: style="text-align: center;"}族名|{: style="text-align: center;"}位置|{: style="text-align: center;"}CJK|{: style="text-align: center;"}字重|{: style="text-align: center;"}本记录的选择|
| :-----------------------------------: | :-------------------------------------: | :----------------------------------: | :-----------------------------------------: | :-----------------------------------------------------------------------------: |
|{: style="text-align: center;"}​`Maple Mono NF`|{: style="text-align: center;"}机器级|{: style="text-align: center;"}无|{: style="text-align: center;"}全|{: style="text-align: center;"}不用（中文会 fallback 到非等宽字体，列宽错位）|
|{: style="text-align: center;"}​`Maple Mono NF CN`|{: style="text-align: center;"}机器级|{: style="text-align: center;"}有|{: style="text-align: center;"}全|{: style="text-align: center;"}✅ 选它|
|{: style="text-align: center;"}​`Maple Mono Normal NF CN`|{: style="text-align: center;"}用户级|{: style="text-align: center;"}有|{: style="text-align: center;"}仅 Regular|{: style="text-align: center;"}不用（​`weight: medium` 会退化成 Regular）|

# PowerShell 7 提示符

入口是安装目录里的 ​`profile.ps1`​（AllUsersAllHosts 层，​`$PSHOME`​ 指向它，所以跟着安装目录走）：​`D:\program\develop\term\powershell\profile.ps1`​。用 ​`$env:PROMPT_IMPL`​ 选实现：默认 ​`starship`​，设成 ​`omp` 回退 oh-my-posh；两个都找不到时保持 PowerShell 默认、不报错。

```powershell
# 临时切（只影响当前窗口）
$env:PROMPT_IMPL = 'omp'      # 或 'starship'

# 持久切
setx PROMPT_IMPL omp          # 改完重开窗口

# 确认当前生效的实现（starship 的 prompt 函数体内含 starship）
(Get-Item Function:\prompt).Definition.Contains('starship')   # True = starship
```

同一文件里另有三处配置：​`ll`​ = ​`Get-ChildItem`​ 别名、​`$PSStyle.FileInfo.Directory = $PSStyle.Foreground.Blue`​（去掉 PS7 默认给目录名加的蓝底）、omp 分支里的 ​`$global:_ompTransientPrompt = $false`​。最后这行不能省：omp 的 init 每次都会把它设回 ​`$true`，不覆盖的话每次回车都会把上一条完整提示符就地改写成一行短提示符。全文见附录 B。

# starship 主题

主题文件是 ​`D:\data\config\starship.toml`​（即 ​`$env:XDG_CONFIG_HOME\starship.toml`​）。starship 在 Windows 上不认 ​`XDG_CONFIG_HOME`​，两处入口都必须显式指定 ​`STARSHIP_CONFIG`，否则会退回默认主题。

相对预设（catppuccin-powerline）的改动：

- `add_newline = false`​，并把 format 里的 ​`$line_break` 去掉，保持一条命令行的紧凑密度
- `[directory]`​ 加 ​`use_os_path_sep = false`​ 与文件夹图标 ​`\uf07b`
- `[status]`​：成功 ​`success_style = "bg:teal fg:crust"`​、失败 ​`style = "bg:red fg:crust"`​，符号分别是 ​`\uf00c`​ / ​`\uf00d`
- 时间胶囊（​`[time]`​，​`%R`​）、命令耗时胶囊（​`[cmd_duration]`​，​`show_milliseconds`）、语言胶囊（c / rust / golang / nodejs / python …）

全文见附录 C。

# Git Bash 提示符

Git for Windows 的官方钩子 ​`/etc/profile.d/git-prompt.sh`​ 会检查 ​`~/.config/git/git-prompt.sh`​：存在就 source 它，并跳过它自带的默认 PS1。所以 Git Bash 的提示符全写在 ​`C:\Users\jjliu58\.config\git\git-prompt.sh` 里，且只在登录 shell（login shell）里被 source。

它做四件事：

- 显式指定 ​`STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"`，与 pwsh 侧共用同一份主题
- 补回 git 补全：走自定义钩子后默认分支的 ​`git-completion.bash`​ 不会再加载，得自己用 ​`git --exec-path` 找到它
- `LS_COLORS`​：先 ​`eval "$(dircolors -b)"`​ 铺满默认库，再追加 ​`di=01;38;2;137;180;250`​（​`#89B4FA`​）覆盖目录名颜色，只写 ​`di=` 会让未列出的文件类型失去着色
- `eval "$(starship init bash)"`​ 之后给 ​`PS0=""`​ 并 ​`unset -f starship_preexec_ps0 starship_preexec`​：starship 的 bash 集成默认每条命令额外 spawn 三次 starship 打时间戳，摘掉后只剩一次；代价是 Git Bash 里不再显示 ​`in 2s448ms` 胶囊

全文见附录 D；想换回 oh-my-posh，文件末尾注释里有两行现成写法。

# 升级 5.1 的 PSReadLine

5.1 自带的 PowerShellGet 1.0.0.1 缺 NuGet provider，非交互下 ​`Install-Module`​ / ​`Find-Module`​ 会被拦下来，因此从 PSGallery 直取 nupkg 安装（2.3.6 是最后一个带 ​`net462` 目标的版本，Windows PowerShell 5.1 只能用它；PS7 自带 2.4.5，不用处理）：

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$tmp = "$env:TEMP\psreadline"; New-Item -ItemType Directory -Force $tmp | Out-Null
Invoke-WebRequest 'https://www.powershellgallery.com/api/v2/package/PSReadLine/2.3.6' `
    -OutFile "$tmp\PSReadLine.2.3.6.zip" -UseBasicParsing
Expand-Archive "$tmp\PSReadLine.2.3.6.zip" -DestinationPath "$tmp\2.3.6" -Force

# 校验签名（应为 Valid / Microsoft Corporation）
Get-ChildItem "$tmp\2.3.6" -Filter *.dll | ForEach-Object {
    "$($_.Name): $((Get-AuthenticodeSignature $_.FullName).Status)" }

# 装到用户级模块目录
$dst = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\PSReadLine\2.3.6"
New-Item -ItemType Directory -Force $dst | Out-Null
Get-ChildItem "$tmp\2.3.6" -Force |
    Where-Object Name -notin '.signature.p7s','[Content_Types].xml','_rels','package','PSReadLine.nuspec' |
    Copy-Item -Destination $dst -Recurse -Force

# 校验：新进程里应报 2.3.6
powershell.exe -NoProfile -Command "(Get-Module PSReadLine -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version"
```

# Windows PowerShell 5.1 提示符

分工：PS7 走安装目录里的 ​`profile.ps1`​，5.1 走 ​`~\.config\pwsh\profile.shared.ps1`​（5.1 的程序目录在 System32、受 ACL 保护，profile 放不进去）。两份文件只做同一件事：加载 ​`D:\program\develop\term\starship\starship.exe`​，主题共用 ​`D:\data\config\starship.toml`，所以改提示符只改一个地方。

5.1 的入口是 ​`%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`，只有一行点源；文件必须存成 UTF-8 带 BOM（5.1 无 BOM 会按 GBK 读，中文注释变乱码）。

```powershell
# Windows PowerShell 5.1 profile —— 只负责点源共用配置
# 真正的设置在 %USERPROFILE%\.config\pwsh\profile.shared.ps1
. "$env:USERPROFILE\.config\pwsh\profile.shared.ps1"
```

`profile.shared.ps1` 做五件事，全文见附录 A：

1. **UTF-8 控制台**（​`[Console]::OutputEncoding = UTF8` 等，包在 try/catch 里），5.1 默认按 GBK 解码子进程输出，git 的中文会乱码。
2. `$MaximumHistoryCount = 20000`。
3. **PSReadLine**：​`PredictionSource=History`​ + ​`ListView`​、上下键历史搜索、Tab 菜单补全、Ctrl+f 接受建议、15 个 token 的 Mocha 语法配色（写法用 ​`[char]27`，5.1 没有反引号 e 转义）。
4. **提示符**：加载 starship，与 pwsh 7 同一个 exe、同一份 ​`starship.toml`​；取全文用 ​`--print-full-init`​（​`init powershell`​ 只回一行 trampoline，会让 starship 再被拉一次）；​`STARSHIP_CONFIG`​ 必须显式给（starship 在 Windows 不认 ​`XDG_CONFIG_HOME`​）。找不到 ​`starship.exe` 就保持 PowerShell 自带提示符，不报错。
5. **​`ll`​**​ **别名**：​`Set-Alias ll Get-ChildItem`，与 pwsh 7 的 profile 一致。

# 生效与验收

改完关掉所有窗口重开：​`profile.ps1`​、PATH、​`STARSHIP_CONFIG` 都是进程启动时的快照，跑着的窗口读不到新值。

```powershell
# 1) pwsh 7：实现与主题
$pwsh = 'D:\program\develop\term\powershell\pwsh.exe'
& $pwsh -Command '$env:PROMPT_IMPL; (Get-Item Function:\prompt).Definition.Contains("starship"); $env:STARSHIP_CONFIG; (Get-Alias ll).Definition'

# 2) Windows PowerShell 5.1：也是 starship，加上 PSReadLine 版本与 ll 别名
powershell.exe -NoProfile -Command "(Get-Module PSReadLine -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version"
powershell.exe -Command '$env:STARSHIP_CONFIG; (Get-Command prompt).CommandType; (prompt).Length; (Get-Alias ll).Definition'

# 3) Git Bash：主题指针、目录色、starship 是否接管
& 'D:\program\develop\git\bash\bin\bash.exe' -lc 'echo $STARSHIP_CONFIG; echo $LS_COLORS | tr ":" "\n" | grep "^di="; type -t starship_precmd'

# 4) 耗时口径（各 5 次取中位）
1..5 | ForEach-Object { (Measure-Command { & $pwsh -Command '$null = prompt' }).TotalMilliseconds }
1..5 | ForEach-Object { (Measure-Command { & 'D:\program\develop\git\bash\bin\bash.exe' -lc 'true' }).TotalMilliseconds }
```

肉眼验收：新开的 pwsh 窗口是 starship 的 powerline 胶囊（左起 OS → 用户名 → 目录 → git → 语言 → 状态 → 时间 → 耗时，最后 ​`❯`​）；**Windows PowerShell 5.1 与它同款**（同一个 starship、同一份 ​`starship.toml`​）；Git Bash 里目录名是 ​`#89B4FA` 蓝、提示符与 pwsh 同款。实测耗时口径：pwsh 提示符渲染中位 89–194 ms；Git Bash 每条命令改前 564–836 ms、改后 211–372 ms。

# 备份与回滚

```powershell
# 备份到应用目录之外（改之前先做）
$dst = "$env:USERPROFILE\.config\pwsh\bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
New-Item -ItemType Directory -Force $dst | Out-Null
Copy-Item 'D:\data\config\starship.toml' $dst -Force
Copy-Item 'D:\program\develop\term\powershell\profile.ps1' $dst -Force
Copy-Item "$env:USERPROFILE\.config\pwsh\profile.shared.ps1" $dst -Force
Copy-Item "$env:USERPROFILE\.config\git\git-prompt.sh" $dst -Force
```

回滚：把备份覆盖回原位，再重开窗口。

```powershell
$bak = "$env:USERPROFILE\.config\pwsh\bak-<时间戳>"
Copy-Item "$bak\starship.toml" 'D:\data\config\starship.toml' -Force
Copy-Item "$bak\profile.ps1" 'D:\program\develop\term\powershell\profile.ps1' -Force
Copy-Item "$bak\profile.shared.ps1" "$env:USERPROFILE\.config\pwsh\profile.shared.ps1" -Force
Copy-Item "$bak\git-prompt.sh" "$env:USERPROFILE\.config\git\git-prompt.sh" -Force
```

# 日常速查

|{: style="text-align: center;"}想做什么|{: style="text-align: center;"}怎么做|
| :----------------------------------------------------------: | :-----------------------------------------------------------------------------: |
|{: style="text-align: center;"}切回 oh-my-posh|{: style="text-align: center;"}​`setx PROMPT_IMPL omp`，重开窗口|
|{: style="text-align: center;"}临时切提示符实现|{: style="text-align: center;"}​`$env:PROMPT_IMPL = 'omp'`（只影响当前窗口）|
|{: style="text-align: center;"}改主题|{: style="text-align: center;"}编辑 ​`D:\data\config\starship.toml`，重开窗口（starship 每次渲染都重读）|
|{: style="text-align: center;"}改 Git Bash 提示符|{: style="text-align: center;"}编辑 ​`~\.config\git\git-prompt.sh`，开新窗口（只在登录 shell 里生效）|
|{: style="text-align: center;"}改 5.1 提示符|{: style="text-align: center;"}编辑 ​`~\.config\pwsh\profile.shared.ps1`（PS7 与 5.1 各维护一份）|
|{: style="text-align: center;"}换字体|{: style="text-align: center;"}改终端程序里的字体设置，族名见「前置检查」那节|
|{: style="text-align: center;"}看 Git Bash 是否走 starship|{: style="text-align: center;"}​`& 'D:\program\develop\git\bash\bin\bash.exe' -lc 'echo $STARSHIP_CONFIG'`|

# 附录 A · profile.shared.ps1

`%USERPROFILE%\.config\pwsh\profile.shared.ps1`：

```powershell
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
```

# 附录 B · profile.ps1

`D:\program\develop\term\powershell\profile.ps1`​（AllUsersAllHosts 层，​`$PSHOME` 指向它）：

```powershell
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
```

# 附录 C · starship.toml

`D:\data\config\starship.toml`：

```toml
"$schema" = 'https://starship.rs/config-schema.json'

# ── 本机开关：跟 omp 侧的密度保持一致 ────────────────────────
# add_newline = true 时每条命令前多一个空行（starship 默认）；这里保持 1 行紧凑。
add_newline = false
# 想要「提示符一行 + 命令在下一行」，把下面 format 里的 $line_break\ 加回去即可。

format = """
[](red)\
$os\
$username\
[](bg:peach fg:red)\
$directory\
[](bg:yellow fg:peach)\
$git_branch\
$git_status\
[](fg:yellow bg:green)\
$c\
$rust\
$golang\
$nodejs\
$bun\
$php\
$java\
$kotlin\
$haskell\
$python\
[](fg:green bg:sapphire)\
$conda\
[](bg:teal fg:sapphire)\
$status\
[](fg:teal bg:lavender)\
$time\
[ ](fg:lavender)\
$cmd_duration\
$character"""

palette = 'catppuccin_mocha'

[os]
disabled = false
style = "bg:red fg:crust"

[os.symbols]
Windows = ""
Ubuntu = "󰕈"
SUSE = ""
Raspbian = "󰐿"
Mint = "󰣭"
Macos = "󰀵"
Manjaro = ""
Linux = "󰌽"
Gentoo = "󰣨"
Fedora = "󰣛"
Alpine = ""
Amazon = ""
Android = ""
AOSC = ""
Arch = "󰣇"
Artix = "󰣇"
CentOS = ""
Debian = "󰣚"
Redhat = "󱄛"
RedHatEnterprise = "󱄛"

[username]
show_always = true
style_user = "bg:red fg:crust"
style_root = "bg:red fg:crust"
format = '[ $user]($style)'

[directory]
use_os_path_sep = false
style = "bg:peach fg:crust"
format = "[ \uf07b $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[directory.substitutions]
"Documents" = "󰈙 "
"Downloads" = " "
"Music" = "󰝚 "
"Pictures" = " "
"Developer" = "󰲋 "

[git_branch]
symbol = ""
style = "bg:yellow"
format = '[[ $symbol $branch ](fg:crust bg:yellow)]($style)'

[git_status]
style = "bg:yellow"
format = '[[($all_status$ahead_behind )](fg:crust bg:yellow)]($style)'

[nodejs]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[bun]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[c]
symbol = " "
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[rust]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[golang]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[php]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[java]
symbol = " "
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[kotlin]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[haskell]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version) ](fg:crust bg:green)]($style)'

[python]
symbol = ""
style = "bg:green"
format = '[[ $symbol( $version)(\(#$virtualenv\)) ](fg:crust bg:green)]($style)'

[docker_context]
symbol = ""
style = "bg:sapphire"
format = '[[ $symbol( $context) ](fg:crust bg:sapphire)]($style)'

[conda]
symbol = "  "
style = "fg:crust bg:sapphire"
format = '[$symbol$environment ]($style)'
ignore_base = false

[time]
disabled = false
time_format = "%R"
style = "bg:lavender"
format = '[[  $time ](fg:crust bg:lavender)]($style)'

[line_break]
disabled = true

[character]
disabled = false
success_symbol = '[❯](bold fg:green)'
error_symbol = '[❯](bold fg:red)'
vimcmd_symbol = '[❮](bold fg:green)'
vimcmd_replace_one_symbol = '[❮](bold fg:lavender)'
vimcmd_replace_symbol = '[❮](bold fg:lavender)'
vimcmd_visual_symbol = '[❮](bold fg:yellow)'

[cmd_duration]
show_milliseconds = true
format = " in $duration "
style = "bg:lavender"
disabled = false
show_notifications = true
min_time_to_notify = 45000

[palettes.catppuccin_mocha]
rosewater = "#f5e0dc"
flamingo = "#f2cdcd"
pink = "#f5c2e7"
mauve = "#cba6f7"
red = "#f38ba8"
maroon = "#eba0ac"
peach = "#fab387"
yellow = "#f9e2af"
green = "#a6e3a1"
teal = "#94e2d5"
sky = "#89dceb"
sapphire = "#74c7ec"
blue = "#89b4fa"
lavender = "#b4befe"
text = "#cdd6f4"
subtext1 = "#bac2de"
subtext0 = "#a6adc8"
overlay2 = "#9399b2"
overlay1 = "#7f849c"
overlay0 = "#6c7086"
surface2 = "#585b70"
surface1 = "#45475a"
surface0 = "#313244"
base = "#1e1e2e"
mantle = "#181825"
crust = "#11111b"

[palettes.catppuccin_frappe]
rosewater = "#f2d5cf"
flamingo = "#eebebe"
pink = "#f4b8e4"
mauve = "#ca9ee6"
red = "#e78284"
maroon = "#ea999c"
peach = "#ef9f76"
yellow = "#e5c890"
green = "#a6d189"
teal = "#81c8be"
sky = "#99d1db"
sapphire = "#85c1dc"
blue = "#8caaee"
lavender = "#babbf1"
text = "#c6d0f5"
subtext1 = "#b5bfe2"
subtext0 = "#a5adce"
overlay2 = "#949cbb"
overlay1 = "#838ba7"
overlay0 = "#737994"
surface2 = "#626880"
surface1 = "#51576d"
surface0 = "#414559"
base = "#303446"
mantle = "#292c3c"
crust = "#232634"

[palettes.catppuccin_latte]
rosewater = "#dc8a78"
flamingo = "#dd7878"
pink = "#ea76cb"
mauve = "#8839ef"
red = "#d20f39"
maroon = "#e64553"
peach = "#fe640b"
yellow = "#df8e1d"
green = "#40a02b"
teal = "#179299"
sky = "#04a5e5"
sapphire = "#209fb5"
blue = "#1e66f5"
lavender = "#7287fd"
text = "#4c4f69"
subtext1 = "#5c5f77"
subtext0 = "#6c6f85"
overlay2 = "#7c7f93"
overlay1 = "#8c8fa1"
overlay0 = "#9ca0b0"
surface2 = "#acb0be"
surface1 = "#bcc0cc"
surface0 = "#ccd0da"
base = "#eff1f5"
mantle = "#e6e9ef"
crust = "#dce0e8"

[palettes.catppuccin_macchiato]
rosewater = "#f4dbd6"
flamingo = "#f0c6c6"
pink = "#f5bde6"
mauve = "#c6a0f6"
red = "#ed8796"
maroon = "#ee99a0"
peach = "#f5a97f"
yellow = "#eed49f"
green = "#a6da95"
teal = "#8bd5ca"
sky = "#91d7e3"
sapphire = "#7dc4e4"
blue = "#8aadf4"
lavender = "#b7bdf8"
text = "#cad3f5"
subtext1 = "#b8c0e0"
subtext0 = "#a5adcb"
overlay2 = "#939ab7"
overlay1 = "#8087a2"
overlay0 = "#6e738d"
surface2 = "#5b6078"
surface1 = "#494d64"
surface0 = "#363a4f"
base = "#24273a"
mantle = "#1e2030"
crust = "#181926"

# ── 状态胶囊：对齐 omp 的 teal 药丸 ✓/✗（预设里没有 status 段，默认禁用）──
[status]
disabled = false
format = "[ $symbol ]($style)"
success_symbol = "\uf00c"
symbol = "\uf00d"
style = "bg:red fg:crust"
success_style = "bg:teal fg:crust"
```

# 附录 D · git-prompt.sh

`C:\Users\jjliu58\.config\git\git-prompt.sh`：

```bash
# Git for Windows 的提示符钩子:/etc/profile.d/git-prompt.sh 发现本文件时会 source 它,
# 并跳过它自带的 PS1 —— 所以 git 补全要在这里自己补回来(见下)。
# 提示符交给便携版 starship,主题与 pwsh 侧共用 D:\data\config\starship.toml。
# 注意:本文件只在登录 shell(login shell)里被 source。

# 主题位置:bash 下 starship 同样不认 XDG_CONFIG_HOME,必须显式给
# (XDG_CONFIG_HOME=D:\data\config,路径里正反斜杠混用 Windows 程序能认)
export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"

# Git 补全:默认分支才加载,走自定义钩子就得自己来
if test -n "$BASH_VERSION" && test -z "$WINELOADERNOEXEC"; then
	_git_exec_path="$(git --exec-path 2>/dev/null)"
	_git_completion="${_git_exec_path%/libexec/git-core}"
	_git_completion="${_git_completion%/lib/git-core}/share/git/completion/git-completion.bash"
	if test -f "$_git_completion"; then
		. "$_git_completion"
	fi
	unset _git_exec_path _git_completion
fi

# ls 的目录名默认是 MSYS 的亮蓝(#3B78FF),换成主题里的蓝 #89B4FA,跟提示符一致。
# 注意:LS_COLORS 一旦显式设置,没列出的类型就不再上色 —— 所以先用 dircolors 的默认库
# 铺满全部类型,再追加一条 di= 覆盖它(同名前項后出现者生效)。
if command -v dircolors >/dev/null 2>&1; then
	eval "$(dircolors -b)"
	LS_COLORS="${LS_COLORS}di=01;38;2;137;180;250:"
	export LS_COLORS
fi

# starship:PATH 里有就用 PATH 上的,否则用 D:\program\develop\term\starship 里的便携版
if test -z "$_STARSHIP_INITIALIZED"; then
	_starship="$(command -v starship 2>/dev/null)"
	test -n "$_starship" || _starship="/d/program/develop/term/starship/starship.exe"
	if test -x "$_starship"; then
		export _STARSHIP_INITIALIZED=1
		eval "$("$_starship" init bash)"

		# starship 的 bash 集成用 PS0 + `starship time` 二进制来打时间戳(每条命令多 2 个进程,
		# 本机实测 564-836ms vs omp 270-369ms)。这里把两条都摘掉:cmd_duration 在
		# Git Bash 里不显示(pwsh 侧照旧),换回每条命令只 spawn 1 次。
		# 想要 bash 下也有 `in 2s581ms`,注释下面三行即可。
		PS0=""
		unset -f starship_preexec_ps0 starship_preexec 2>/dev/null
	fi
	unset _starship
fi

# 想换回 oh-my-posh:注释掉上面那段 starship,改成
#   _omp="/d/program/develop/term/omp"
#   eval "$("$_omp/oh-my-posh.exe" init bash --config "$_omp/catppuccin-mocha.omp.json")"
# (Git Bash 下 omp 主题里的 rprompt 不显示,也没有 transient,只有左侧提示符)
```
