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
