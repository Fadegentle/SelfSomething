# === 编码设置 ===
$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# === 颜色定义 ===
$Colors = @{
    Blue = "`e[38;5;153m"     # 淡蓝
    Pink = "`e[38;5;225m"     # 淡粉
    Purple = "`e[38;5;0m`e[48;5;229m"   # 黑字黄底
    Yellow = "`e[38;5;229m"   # 淡黄
    Green = "`e[38;5;193m"    # 淡绿
    Reset = "`e[0m"
}

# === 命令执行时间统计 ===
$Global:LastCommandStartTime = $null
$Global:LastCommandEndTime = $null

Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    $Global:LastCommandEndTime = Get-Date
} | Out-Null

function Measure-CommandTime {
    if ($Global:LastCommandStartTime -and $Global:LastCommandEndTime) {
        $duration = New-TimeSpan -Start $Global:LastCommandStartTime -End $Global:LastCommandEndTime
        if ($duration.TotalSeconds -lt 1) {
            return "$($duration.TotalMilliseconds.ToString('0'))ms"
        } elseif ($duration.TotalMinutes -lt 1) {
            return "$($duration.TotalSeconds.ToString('0.00'))s"
        } else {
            return "$($duration.TotalMinutes.ToString('0.00'))m"
        }
    }
    return "0ms"
}

# === 自定义提示符 ===
function prompt {
    # 记录命令开始时间
    $Global:LastCommandStartTime = Get-Date
    
    # 获取信息
    $username = $env:USERNAME
    $hostname = $env:COMPUTERNAME
    $currentDir = Split-Path -leaf -path (Get-Location)
    $currentTime = Get-Date -Format "HH:mm:ss"
    $commandTime = Measure-CommandTime
    
    # 构建提示符
    $promptText = ""
    $promptText += "$($Colors.Blue)$username$($Colors.Reset)$($Colors.Pink)@$hostname$($Colors.Reset) "
    $promptText += "$($Colors.Purple) $currentDir $($Colors.Reset) "
    $timeText = "$($Colors.Green)$commandTime$($Colors.Reset) $($Colors.Yellow)$currentTime$($Colors.Reset)"
    $promptText += $timeText
    $promptText += "`n$($Colors.Blue)PS>$($Colors.Reset)"
    
    return $promptText
}

# === 基础别名 ===
function lse { Get-ChildItem @args }
function ll { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force @args }
function tree { Get-ChildItem -Recurse @args }
