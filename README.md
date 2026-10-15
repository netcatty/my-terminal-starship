# 终端提示符与外观（Windows）

一份可直接复现的配置快照：Windows 上三个 shell 的提示符统一走 **starship**（Catppuccin Mocha powerline），另附 herdr 的配色配置和本套环境用到的辅助脚本。

`docs/` 下是同一次整理时从思源笔记导出的三篇说明（复现步骤、验收口令、踩过的坑都在里面）。

## 文件与目标位置

| 文件 | 目标位置 | 说明 |
| --- | --- | --- |
| `starship.toml` | `D:\data\config\starship.toml` | 提示符主题（catppuccin-powerline 的单行版） |
| `powershell/profile.ps1` | `<pwsh 安装目录>\profile.ps1` | PowerShell 7 的 AllUsersAllHosts profile |
| `powershell/profile.shared.ps1` | `%USERPROFILE%\.config\pwsh\profile.shared.ps1` | Windows PowerShell 5.1 的配置 |
| `powershell/Microsoft.PowerShell_profile.ps1` | `%USERPROFILE%\Documents\WindowsPowerShell\` | 5.1 的入口，只有一行点源 |
| `powershell/set-pwsh-path.ps1` | `%USERPROFILE%\.config\pwsh\` | 让 pi / Node 正确找到 PowerShell 7 |
| `powershell/parse-herdr-frame.ps1` | `%USERPROFILE%\.config\pwsh\` | 抓 herdr 一帧渲染，翻译成可读的颜色标签 |
| `git/git-prompt.sh` | `%USERPROFILE%\.config\git\git-prompt.sh` | Git Bash 的提示符钩子（Git for Windows 优先 source 它） |
| `herdr/config.toml` | `<herdr 配置目录>\config.toml` | herdr 主题与界面配置 |
| `wezterm/wezterm.lua` | `D:\data\config\wezterm\wezterm.lua` | 配色同源参考，herdr 与 starship 的调色板取自它 |

## 复现步骤

1. 装便携版 starship 到 `D:\program\develop\term\starship\starship.exe`
2. 按上表把文件放到目标位置。**`.ps1` 必须保留 UTF-8 BOM**（Windows PowerShell 5.1 无 BOM 会按 GBK 读，中文注释变乱码）；脚本里写死的 `D:\program\develop\term\...`、`D:\data\config\...` 是本机路径，换机器要改成自己的
3. 装 Nerd Font（JetBrainsMono NF），否则胶囊和图标是方块
4. 关掉所有终端窗口重开
5. 验收：见 `docs/02-terminal-prompt-appearance.md` 的「生效与验收」一节

## 本机环境口径

| 项 | 值 |
| --- | --- |
| PowerShell 7 | 7.6.6（便携版，`D:\program\develop\term\powershell`） |
| Windows PowerShell | 5.1.26100.6725（系统自带） |
| starship | 1.26.0 |
| oh-my-posh | 30.1.1（可选） |
| herdr | 0.9.5 |
| 字体 | JetBrainsMono NF |

## 容易踩的三点

- `PROMPT_IMPL` 环境变量控制实现：默认 starship，设成 `omp` 切回 oh-my-posh。回退需本地自己装 omp，主题也不在本仓库（`profile.ps1` 指向 `..\omp\catppuccin-mocha.omp.json`，没有就用 omp 自带主题）
- starship 在 Windows **不认 `XDG_CONFIG_HOME`**，脚本里必须显式给 `STARSHIP_CONFIG`
- Git Bash 钩子里 `PS0=""` 加 `unset -f starship_preexec_ps0 starship_preexec` 是为了去掉两条 `starship time`（每条命令 3 个进程降到 1 个），代价是 bash 下不再显示 `in 2s448ms` 胶囊

## 性质

这是**快照**，不随本机改动自动更新。本机改完配置后回这里同步一次，或者干脆把本机的文件软链到本目录的对应位置。
