$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

# themes: paradox, uew, stelbent-compact.minimal, lambdageneration, kushal, if_tea, hul10, 1_shell, jandedobbeleer, jblab_2021
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\fadegentle.omp.json" | Invoke-Expression


# alias eza
function lse { eza --icons }  # 默认显示 icons：
function ll { eza --icons --long --header }  # 显示文件目录详情
function la { eza --icons --long --header --all }  # 显示全部文件目录，包括隐藏文件
function lg { eza --icons --long --header --all --git }  # 显示详情的同时，附带 git 状态信息
function tree { eza --tree --icons }  # 替换 tree 命令

# alias zoxide
New-Alias -Name z -Value C:\Users\Fadegentle\AppData\Local\Microsoft\WinGet\Packages\ajeetdsouza.zoxide_Microsoft.Winget.Source_8wekyb3d8bbwe\zoxide.exe
z init powershell | Out-String | Invoke-Expression