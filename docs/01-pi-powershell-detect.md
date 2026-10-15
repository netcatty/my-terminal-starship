# /技术/工具/Windows 终端/pi 的 PowerShell 探测坑与修复

---
title: pi 的 PowerShell 探测坑与修复
date: 2026-10-10T19:00:28+08:00
lastmod: 2026-10-15T17:11:36+08:00
---

> **摘要**：pi 的 ​`powershell`​ 工具在 Windows 上按 ​`where pwsh.exe`​ + ​`fs.existsSync`​ 双重校验挑 shell，别名路径（AppExecutionAlias）会被判否、静默退回 Windows PowerShell 5.1；修法是把真实 ​`pwsh.exe`​ 的目录排到 PATH 最前，用 ​`set-pwsh-path.ps1` 固化，再按验证清单确认。

# 修复

把**真实文件**目录排到 PATH 最前，让 ​`where` 的第一条结果就是它：

```text
旧: C:\Users\jjliu58\AppData\Local\Microsoft\WindowsApps
新: D:\program\develop\term\powershell;C:\Users\jjliu58\AppData\Local\Microsoft\WindowsApps
```

改完复刻 pi 的完整探测逻辑：

```text
where 首条 = D:\program\develop\term\powershell\pwsh.exe
existsSync = true
pi 的 findExecutableOnPath 返回 = 上面那条路径      （不再是 null）
```

# 维护脚本

`%USERPROFILE%\.config\pwsh\set-pwsh-path.ps1`：

```powershell
# 让 pi 的 powershell 工具（以及任何 Node 工具）能正确找到 PowerShell 7。
#
# 背景（实测证据，2026-09-17）：
#   pi 用 `where pwsh.exe` 找 PowerShell，然后对返回的第一条路径做 fs.existsSync 校验：
#       let firstMatch = result.stdout.trim().split(/\r?\n/)[0];
#       if (firstMatch && existsSync(firstMatch)) return firstMatch;   // ← 卡在这里
#       return null;  →  退回 findExecutableOnPath("powershell.exe") = Windows PowerShell 5.1
#   Store(Appx) 版 PowerShell 的 %LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe 是 AppExecutionAlias
#   （0 字节 reparse point）：`where` 能找到、CreateProcess 能执行，但 Node 的 existsSync 对它返回 false。
#   实测：
#       where pwsh.exe                        → 退出码 0，返回 alias 路径
#       existsSync(alias)                     → false      ← 根因
#       existsSync(Appx 包内真身 pwsh.exe)     → true
#       spawn(alias 路径, ['-NoProfile', ...]) → status 0，正常输出 7.6.6
#
# 做法：把「真实的 pwsh.exe 所在目录」排到 PATH 最前，让 `where` 的第一条结果就是真实文件。
#   - 优先用 MSI 安装的 C:\Program Files\PowerShell\7（路径稳定，不用维护）
#   - 没有 MSI 时用 Store 包的 InstallLocation（目录名含版本号，升级后需重跑本脚本）
#
# 用法：
#   .\set-pwsh-path.ps1            # 改用户 PATH（自动备份）
#   .\set-pwsh-path.ps1 -Check     # 只报告当前状态，不改动

param([switch]$Check)

# ---- 1. 找一个「真实文件」的 pwsh 目录 -------------------------------------------------
# 优先级：用户自装的 zip 版（路径稳定）> MSI（稳定）> Store/Appx（含版本号，升级后要重跑）
$candidates = @()
$candidates += [pscustomobject]@{ Source = 'zip/portable'; Dir = 'D:\program\develop\term\powershell' }
$candidates += [pscustomobject]@{ Source = 'MSI'; Dir = (Join-Path ${env:ProgramFiles} 'PowerShell\7') }
$pkg = Get-AppxPackage Microsoft.PowerShell -ErrorAction SilentlyContinue |
    Sort-Object Version -Descending | Select-Object -First 1
if ($pkg) {
    $candidates += [pscustomobject]@{ Source = "Store $($pkg.Version)"; Dir = $pkg.InstallLocation }
}

$pick = $candidates | Where-Object { $_.Dir -and (Test-Path (Join-Path $_.Dir 'pwsh.exe')) } | Select-Object -First 1
if (-not $pick) {
    throw "没找到可用的 pwsh.exe。候选：`n" + (($candidates | ForEach-Object { "  [$($_.Source)] $($_.Dir)" }) -join "`n")
}

# ---- 2. 复刻 pi 的探测逻辑，给出「真实判断」 --------------------------------------------
function Test-PiResolution {
    $probe = Join-Path $env:TEMP 'pi-pwsh-probe.js'
    @'
const { spawnSync } = require("child_process");
const { existsSync } = require("fs");
const r = spawnSync("where", ["pwsh.exe"], { encoding: "utf-8", timeout: 5000, windowsHide: true });
const first = r.stdout ? r.stdout.trim().split(/\r?\n/)[0] : "";
const ok = r.status === 0 && first && existsSync(first);
console.log("  where 退出码    : " + r.status);
console.log("  首条            : " + (first || "(无)"));
console.log("  existsSync      : " + (first ? existsSync(first) : "n/a"));
console.log("  pi 会选         : " + (ok ? first : "null → 退回 powershell.exe (5.1) ❌"));
'@ | Set-Content $probe -Encoding UTF8
    # 用「用户 PATH + 机器 PATH」拼出重启后 pi 会继承到的环境
    $env:PATH = ([Environment]::GetEnvironmentVariable('PATH', 'User') + ';' +
                 [Environment]::GetEnvironmentVariable('PATH', 'Machine'))
    node $probe
}

function Show-State([string]$label) {
    "--- $label ---"
    "选用来源 : $($pick.Source)"
    "真实目录 : $($pick.Dir)"
    Test-PiResolution
}

if ($Check) { Show-State '当前状态'; return }

# ---- 3. 改用户 PATH ---------------------------------------------------------------------
$old = [Environment]::GetEnvironmentVariable('PATH', 'User')
$backup = "$env:USERPROFILE\.config\path-backup-user-$([DateTime]::Now.ToString('yyyyMMdd-HHmmss')).txt"
$old | Set-Content $backup -Encoding UTF8
"备份用户 PATH -> $backup"

# 去掉历史遗留的 PowerShell 目录条目（Appx 版本目录 / Program Files\PowerShell\7）
$kept = $old -split ';' | Where-Object { $_ -and $_ -notmatch 'Microsoft\.PowerShell_' -and $_ -notmatch 'PowerShell\\7$' }
$new = (@($pick.Dir) + $kept) -join ';'

if ($new -eq $old) { "用户 PATH 已是最新，无需改动。" }
else {
    [Environment]::SetEnvironmentVariable('PATH', $new, 'User')
    "用户 PATH 已更新："
    "  旧: $old"
    "  新: $new"
}

Show-State '改完后'
if ($pick.Source -like 'Store*') {
    "注意：用的是 Store 包目录，含版本号。PowerShell 升级后重跑本脚本。"
    "      想免掉这一步，装 MSI（winget install --id Microsoft.PowerShell）后重跑即可切到稳定路径。"
}
"提示：pi 进程的 PATH 是启动快照，改完要重启 pi 才生效。"
```

# 验证清单

```powershell
# 1) 会话是不是 PS7（期望 Core / 7.6.6）
"$($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)"
[Diagnostics.Process]::GetCurrentProcess().MainModule.FileName

# 2) 编码两个坑（拿任意含中文的 UTF-8 文件试；这里用 Git 的 git-prompt.sh）
$f = "$env:USERPROFILE\.config\git\git-prompt.sh"; $s = Get-Content $f -Raw
([int[]][char[]]$s[0..13]) -join ' '     # 期望 35 32 71 105 116 32 102 111 114 32 87 105 110 100
Set-Content "$env:TEMP\enc.txt" '测试' -Force
[IO.File]::ReadAllBytes("$env:TEMP\enc.txt") -join ' '   # 期望 230 181 139 232 175 149 13 10

# 3) PS7 语法/参数
"`e" -eq [string][char]27                                  # True
(Get-Command ConvertFrom-Json).Parameters.ContainsKey('AsHashtable')   # True
$PSNativeCommandArgumentPassing                             # Windows

# 4) 维护脚本自检
~\.config\pwsh\set-pwsh-path.ps1 -Check
```

实测结果（修好之后）：

|{: style="text-align: center;"}检查|{: style="text-align: center;"}结果|
| :--------------------------------------------------------: | :---------------------------------------------------: |
|{: style="text-align: center;"}​`PSEdition`​ / ​`PSVersion`|{: style="text-align: center;"}​`Core`​ / ​`7.6.6`|
|{: style="text-align: center;"}工具进程 exe|{: style="text-align: center;"}​`D:\program\develop\term\powershell\pwsh.exe`|
|{: style="text-align: center;"}​`Set-Content` 中文字节|{: style="text-align: center;"}​`230 181 139 232 175 149` ✅ UTF-8 无 BOM|
|{: style="text-align: center;"}​`&&`​ / ​`` `e ``​ / ​`Test-Json`​ / ​`-AsHashtable`|{: style="text-align: center;"}全部 True ✅|
|{: style="text-align: center;"}​`bash.exe` 短命令|{: style="text-align: center;"}仍可用（Git Bash）✅|

# 速查

|{: style="text-align: center;"}想做什么|{: style="text-align: center;"}怎么做|
| :-----------------------------------------------------------------: | :----------------------------------------------------: |
|{: style="text-align: center;"}看当前是不是 PS7|{: style="text-align: center;"}​`$PSVersionTable.PSEdition`​（期望 ​`Core`）|
|{: style="text-align: center;"}看 pi 会选哪个 shell|{: style="text-align: center;"}​`~\.config\pwsh\set-pwsh-path.ps1 -Check`|
|{: style="text-align: center;"}修好 / 升级后重跑|{: style="text-align: center;"}​`~\.config\pwsh\set-pwsh-path.ps1`，然后重启 pi|
|{: style="text-align: center;"}判断某个 pwsh 路径 Node 能不能看见|{: style="text-align: center;"}​`node -e "console.log(require('fs').existsSync(process.argv[1]))" "<路径>"`|
|{: style="text-align: center;"}直接看 pi 的探测源码|{: style="text-align: center;"}​`node_modules/@earendil-works/pi-coding-agent/dist/utils/shell.js`​ 里的 ​`findExecutableOnPath`​ / ​`getPowerShellConfig`|
|{: style="text-align: center;"}切到 MSI 稳定路径|{: style="text-align: center;"}​`winget install --id Microsoft.PowerShell` 后重跑脚本|
