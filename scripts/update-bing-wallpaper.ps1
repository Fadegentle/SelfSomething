# 更新 Bing 今日壁纸

# ===== 配置 =====
$ImagePath = "C:\Users\Fadegentle\Documents\PowerShell\bing-today.jpg"
$MetaPath  = "C:\Users\Fadegentle\Documents\PowerShell\bing-today.txt"
$ApiUrl    = "https://cn.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=zh-CN"

# ===== 判断是否需要更新 =====
$today = (Get-Date).ToString("yyyyMMdd")

if (Test-Path $MetaPath) {
    $last = Get-Content $MetaPath -ErrorAction SilentlyContinue
    if ($last -eq $today -and (Test-Path $ImagePath)) {
        return   # 今天已经有了，直接退出
    }
}

# ===== 获取 Bing 今日壁纸信息 =====
try {
    $json = Invoke-RestMethod -Uri $ApiUrl -TimeoutSec 10
    $relativeUrl = $json.images[0].url.Split("&")[0]
    $imageUrl = "https://www.bing.com$relativeUrl"

    # ===== 下载图片 =====
    Invoke-WebRequest -Uri $imageUrl -OutFile $ImagePath -TimeoutSec 20

    # ===== 记录日期 =====
    Set-Content -Path $MetaPath -Value $today -Encoding ASCII
}
catch {
    # 网络或 API 失败，什么都不做，Terminal 还能用旧图
}
