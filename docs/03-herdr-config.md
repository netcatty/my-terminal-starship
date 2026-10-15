# /技术/工具/Windows 终端/herdr 配置

---
title: herdr 配置
date: 2026-10-10T18:58:59+08:00
lastmod: 2026-10-15T17:15:16+08:00
---

> **摘要**：herdr 的界面配色由 ​`[theme.custom]`​ 的 token 决定，配置文件在 ​`D:\program\develop\term\herdr\data\herdr\config.toml`（由 HERDR_CONFIG_PATH 指定）。下面给出可直接照抄的配置全文、复现步骤、抓帧验证方法，以及每个界面元素对应哪个 token 的实测映射。

# 本机环境

|{: style="text-align: center;"}项|{: style="text-align: center;"}值|{: style="text-align: center;"}获取方式|
| :-----------------------------------------: | :---------------------------------------------------------: | :--------------------------------------------------------: |
|{: style="text-align: center;"}herdr|{: style="text-align: center;"}**0.9.5**（stable 渠道）|{: style="text-align: center;"}​`herdr --version`|
|{: style="text-align: center;"}可执行文件|{: style="text-align: center;"}​`D:\program\develop\term\herdr\app\herdr.exe`|{: style="text-align: center;"}​`Get-Command herdr`|
|{: style="text-align: center;"}配置文件|{: style="text-align: center;"}​`D:\program\develop\term\herdr\data\herdr\config.toml`​（由 ​`HERDR_CONFIG_PATH` 指定）|{: style="text-align: center;"}​`herdr --help` 里会打印解析后的路径|
|{: style="text-align: center;"}服务端|{: style="text-align: center;"}长驻进程 ​`herdr.exe server`​，socket ​`herdr.sock`|{: style="text-align: center;"}​`herdr status`|
|{: style="text-align: center;"}客户端会话|{: style="text-align: center;"}用 ​`herdr pane process-info` 读实时状态|{: style="text-align: center;"}—|
|{: style="text-align: center;"}文档|{: style="text-align: center;"}​`https://herdr.dev/zh-cn/docs/configuration/`​；配置参考 JSON：​`https://cdn.jsdelivr.net/gh/herdrdev/herdr@v0.9.1/docs/next/website/src/data/config-reference.json`|{: style="text-align: center;"}—|

内置主题名（​`--default-config`​ 里的注释给的）：​`catppuccin`​ / ​`terminal`​ / ​`tokyo-night`​ / ​`dracula`​ / ​`nord`​ / ​`gruvbox`​ / ​`one-dark`​ / ​`solarized`​ / ​`kanagawa`​ / ​`rose-pine`​ / ​`vesper`​，浅色姊妹主题 ​`catppuccin-latte` 等。

# 最终配置

```toml
# herdr 配置 —— Catppuccin Mocha（配色与 starship / omp 同一套调色板）
# 改完执行：herdr server reload-config
# 校验：herdr config check

onboarding = false
[theme]
name = "catppuccin"
auto_switch = false

# ── catppuccin mocha（与 wezterm colors/custom.lua 同源）────
[theme.custom]
accent = "#89b4fa"        # blue，与 wezterm 主蓝一致
panel_bg = "reset"        # keep terminal background
sidebar_bg = "#181825"    # mantle（侧边栏，同 wezterm new_tab_hover 底色）
active_row_bg = "#313244" # surface0（侧边栏选中行）
selection_bg = "#585b70"  # surface2（同 wezterm selection_bg）
surface_dim = "#11111b"   # crust
surface0 = "#313244"      # surface0
surface1 = "#45475a"      # surface1
overlay0 = "#6c7086"
overlay1 = "#9399b2"
text = "#cdd6f4"          # 同 wezterm foreground
subtext0 = "#a6adc8"
green = "#a6e3a1"
teal = "#94e2d5"
blue = "#89b4fa"
mauve = "#cba6f7"
yellow = "#f9e2af"
peach = "#fab387"
red = "#f38ba8"

[keys]
# Collapse/expand the sidebar: press the prefix (ctrl+b), then b.
toggle_sidebar = "prefix+b"

[ui.toast]
delivery = "system"

[ui.sound]
enabled = false

[ui]
show_agent_labels_on_pane_borders = true
tab_bar_position = "top"
tab_bar_right = [
  { type = "zoom" },
  { type = "hostname" },
  { type = "datetime", format = "%H:%M" },
  { type = "text", text = " " }
]
tab_bar_right_separator = " · "

status_indicators = "dots"

# ── 新 pane 的 shell ─────────────────────────────────────────────
# herdr 默认在 Windows 上挑 Windows PowerShell 5.1(它不加载我们的提示符配置),
# 这里显式指向便携版 pwsh:D:\program\develop\term\powershell\pwsh.exe
# 其 AllUsersAllHosts profile(同目录 profile.ps1)渲染 starship
# (主题 D:\data\config\starship.toml;$env:PROMPT_IMPL=omp 可切回 ..\omp 的 oh-my-posh)。
# 换 Git Bash:把上面一行注释掉,启用下面那行,然后 `herdr server reload-config`。
# (Git Bash 走 %USERPROFILE%\.config\git\git-prompt.sh,同一份 starship 主题;bash 下没有 cmd_duration)
[terminal]
default_shell = "D:\\program\\develop\\term\\powershell\\pwsh.exe"
# default_shell = "D:\\program\\develop\\git\\bash\\bin\\bash.exe"
```

# 复现步骤

```powershell
# 1) 确认 herdr 位置与版本
& 'D:\program\develop\term\herdr\app\herdr.exe' --version
herdr status

# 2) 备份现有配置（配置目录是 git 仓库，备份放到仓库外面）
Copy-Item 'D:\program\develop\term\herdr\data\herdr\config.toml' `
    "$env:USERPROFILE\.config\pwsh\herdr-config-$(Get-Date -Format yyyyMMdd-HHmmss).toml" -Force

# 3) 写入「最终配置」那份 config.toml（注意：UTF-8 无 BOM，TOML 带 BOM 会解析失败）

# 4) 校验 + 热加载（不用重启窗格）
herdr config check            # 期望 config: ok
herdr server reload-config    # 期望 status: applied、diagnostics: []

# 5) 客户端本地设置（主题、状态图标等属于客户端）在 herdr 里按 prefix+shift+r，
#    或全局菜单里的 reload config
```

**启动时生效、reload 无效的项**：​`terminal.kitty_graphics`​（文档明确要求重启 server 或重新 attach）、​`default_shell`​ 只影响**新建**窗格（已有窗格保留原 shell，要换得重建窗格）。

# 验证

## 工具

`%USERPROFILE%\.config\pwsh\parse-herdr-frame.ps1`（全文见附录 A）

```powershell
~\.config\pwsh\parse-herdr-frame.ps1 -Seconds 4
# 原始帧 $env:TEMP\herdr-frame.bin，翻译结果 $env:TEMP\herdr-frame.txt
```

副作用：会往运行中的 server 挂一个客户端再断开（​`herdr-server.log` 里能看到 client connected / disconnected）。不改会话、不动窗格。

## 抓帧里长什么样

```text
{1;27} [R fg#1E1E2E bg#89B4FA]   1        ← 活跃标签：accent 蓝底 + 深色字
       [R fgDEF bgDEF] [R DIM fg#BAC2DE bg#1E1E2E]   2    ← 不活跃标签：DIM + overlay0 色 + surface0 底板
       [R fgDEF bgDEF] [R fg#A6ADC8 bgDEF] +    ← 新建标签按钮：overlay1
{4;5}  [R DIM fg#BAC2DE bg#1E1E2E] [R B fg#CDD6F4 bg#1E1E2E]herdr  ← 侧边栏 space 行：加粗正文色，无 DIM
```

`[R ...]`​ = SGR 0 复位起步，​`B`​ = 加粗，​`DIM`​ = SGR 2，​`bgDEF` = SGR 49（未涂底色，即透明）。

## 实测的 token → 界面元素映射

|{: style="text-align: center;"}界面元素|{: style="text-align: center;"}实测属性|{: style="text-align: center;"}token|
| :-----------------------------------------------------------------------------: | :---------------------------------------------: | :---------------------------------------------------------------------: |
|{: style="text-align: center;"}正文、标签文字、聚焦的 workspace 名|{: style="text-align: center;"}​`fg#CDD6F4`|{: style="text-align: center;"}​`text`|
|{: style="text-align: center;"}**不活跃标签标题**|{: style="text-align: center;"}​`DIM fg#BAC2DE bg#1E1E2E`|{: style="text-align: center;"}色 = ​`overlay0`​，底板 = ​`surface0`，外加硬编码 DIM|
|{: style="text-align: center;"}活跃标签|{: style="text-align: center;"}​`fg#1E1E2E bg#89B4FA`|{: style="text-align: center;"}底板 = ​`accent`|
|{: style="text-align: center;"}侧边栏小标题（machines/spaces/agents/grouped）|{: style="text-align: center;"}​`B fg#BAC2DE`|{: style="text-align: center;"}​`overlay0`|
|{: style="text-align: center;"}未聚焦 workspace 行|{: style="text-align: center;"}​`fg#BAC2DE`|{: style="text-align: center;"}​`subtext0`|
|{: style="text-align: center;"}「+」新建标签按钮|{: style="text-align: center;"}​`fg#A6ADC8`|{: style="text-align: center;"}​`overlay1`|
|{: style="text-align: center;"}面板/标签栏底色|{: style="text-align: center;"}​`bgDEF`（SGR 49）|{: style="text-align: center;"}​`panel_bg = "reset"`|

# 备份与回滚

`D:\program\develop\term\herdr\data\herdr\`​ 里是 git 仓库中的 ​`config.toml`​；​`%APPDATA%\herdr\` 下还留着 2026-09-17 那批副本：

```text
config.toml                     当前配置（data\herdr，git 仓库里）
config.toml.bak-20260917-165636 旧副本（%APPDATA%\herdr）
config.toml.prev-*              分段快照
config.toml.good-*              定稿快照
```

回滚：用上面第 2 步的备份覆盖回去，再 reload。

```powershell
Copy-Item "$env:USERPROFILE\.config\pwsh\herdr-config-<时间戳>.toml" 'D:\program\develop\term\herdr\data\herdr\config.toml' -Force
herdr server reload-config
```

# 速查

|{: style="text-align: center;"}想做什么|{: style="text-align: center;"}怎么做|
| :-------------------------------------------------------: | :-----------------------------------------------------------------------: |
|{: style="text-align: center;"}改配置|{: style="text-align: center;"}编辑 ​`D:\program\develop\term\herdr\data\herdr\config.toml`​ → ​`herdr config check`​ → ​`herdr server reload-config`​ → 客户端 ​`prefix+shift+r`|
|{: style="text-align: center;"}看当前窗格跑什么|{: style="text-align: center;"}​`herdr pane process-info`（含完整 argv、cwd、pid）|
|{: style="text-align: center;"}看会话结构|{: style="text-align: center;"}​`herdr api snapshot`|
|{: style="text-align: center;"}查某个配置键|{: style="text-align: center;"}​`https://cdn.jsdelivr.net/gh/herdrdev/herdr@v0.9.1/docs/next/website/src/data/config-reference.json`，比 HTML 文档好筛|
|{: style="text-align: center;"}查某界面元素用哪个 token|{: style="text-align: center;"}​`~\.config\pwsh\parse-herdr-frame.ps1` 抓帧 + 改 token 值再抓一次对比|
|{: style="text-align: center;"}透明相关的重置别名|{: style="text-align: center;"}颜色值可写 ​`reset`​ / ​`default`​ / ​`none`​ / ​`transparent`|
|{: style="text-align: center;"}前缀键|{: style="text-align: center;"}默认 ​`ctrl+b`​；帮助面板 ​`prefix+?`|

# 附录 A · parse-herdr-frame.ps1

```powershell
# 抓取并翻译 herdr 客户端的一帧渲染输出，用来确定"界面上某个元素到底用的是哪个 theme token"。
# 用法：
#   .\parse-herdr-frame.ps1                 # 抓 4 秒，写 $env:TEMP\herdr-frame.bin / .txt
#   .\parse-herdr-frame.ps1 -Seconds 6
#
# 原理：herdr 客户端的渲染输出就是标准终端转义序列。把它的 stdout 重定向到文件跑几秒，
# 再被 kill，文件里就有一整帧；把 CSI 序列翻译成可读标签后，就能看到每个格子用的颜色。
# 副作用：会往运行中的 server 挂一个客户端再断开（日志里能看到 client connected/disconnected）。

param(
    [int]$Seconds = 4,
    [string]$Bin = "$env:TEMP\herdr-frame.bin",
    [string]$Text = "$env:TEMP\herdr-frame.txt",
    [string]$HerdrExe = "D:\program\develop\term\herdr\app\herdr.exe"
)

if (-not (Test-Path $HerdrExe)) { throw "找不到 herdr.exe：$HerdrExe" }

"抓取 $Seconds 秒 -> $Bin"
Remove-Item $Bin, $Text -ErrorAction SilentlyContinue
$p = Start-Process $HerdrExe -RedirectStandardOutput $Bin -NoNewWindow -PassThru
Start-Sleep -Seconds $Seconds
if (-not $p.HasExited) { $p.Kill() }
Start-Sleep -Seconds 1
if (-not (Test-Path $Bin)) { throw "没有抓到输出" }

$esc = [char]27
$s = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($Bin))

function Hex3([int]$r, [int]$g, [int]$b) { return ('#{0:X2}{1:X2}{2:X2}' -f $r, $g, $b) }

function Tag([string]$params) {
    $p = $params -split ';'
    $o = New-Object System.Collections.ArrayList
    $i = 0
    while ($i -lt $p.Count) {
        switch ($p[$i]) {
            '0'   { [void]$o.Add('R') }
            '1'   { [void]$o.Add('B') }
            '2'   { [void]$o.Add('DIM') }
            '4'   { [void]$o.Add('U') }
            '7'   { [void]$o.Add('REV') }
            '38'  { if ($p[$i + 1] -eq '2') { [void]$o.Add('fg' + (Hex3 $p[$i+2] $p[$i+3] $p[$i+4])); $i += 4 } }
            '48'  { if ($p[$i + 1] -eq '2') { [void]$o.Add('bg' + (Hex3 $p[$i+2] $p[$i+3] $p[$i+4])); $i += 4 } }
            '49'  { [void]$o.Add('bgDEF') }
            '39'  { [void]$o.Add('fgDEF') }
            default { [void]$o.Add('?' + $p[$i]) }
        }
        $i++
    }
    if ($o.Count -eq 0) { return '' }
    return '[' + ($o -join ' ') + ']'
}

$t = [regex]::Replace($s, ($esc + '\[([0-9;]*)m'), { param($m) Tag $m.Groups[1].Value })
$t = [regex]::Replace($t, ($esc + '\[([0-9;]+)H'), { param($m) "`n{" + $m.Groups[1].Value + "} " })
$t = $t -replace ($esc + '\['), '{CSI' -replace ($esc + '\]'), '{OSC' -replace $esc, '{ESC'

[IO.File]::WriteAllText($Text, $t, (New-Object Text.UTF8Encoding($false)))

"原始帧 $((Get-Item $Bin).Length) 字节 -> 翻译后 $($t.Length) 字符：$Text"
"提示：搜 'DIM' 看被 herdr 额外变暗的元素；搜 'bg#' 看哪些面被涂了实心底色。"
```
