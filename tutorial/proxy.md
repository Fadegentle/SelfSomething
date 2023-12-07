- [Clash 通用](#clash-通用)
- [Windows: Clash for Windows ( CFW )](#windows-clash-for-windows--cfw-)
  - [基础使用](#基础使用)
- [Android: Clash for Android ( CFA )](#android-clash-for-android--cfa-)
- [MacOS: ClashX Pro](#macos-clashx-pro)
- [iPhone/iPad](#iphoneipad)
- [Linux: clash](#linux-clash)
- [路由器: Clash Merlin](#路由器-clash-merlin)

# Clash 通用

[RESTful API 文档](https://clash.gitbook.io/doc/restful-api)

# Windows: Clash for Windows ( CFW )

![cfw_home](../assets/tutorial/proxy/cfw_home.png)

## 基础使用

1. 点击左侧栏 `General`，打开 `System Proxy` 启动系统代理
2. 获得机场节点的 `yaml` 后，点击左侧栏 `Profiles`，选择 `Import` 导入文件

![cfw_profiles](../assets/tutorial/proxy/cfw_profiles.png)

2. 点击左侧栏 `Proxies`，选择 `Rule` 模式，并选择想要的节点

![cfw_proxies](../assets/tutorial/proxy/cfw_proxies.png)

# Android: Clash for Android ( CFA )

![cfa](../assets/tutorial/proxy/cfa.png)

# MacOS: ClashX Pro
# iPhone/iPad

1. 使⽤中国⼿机号和美国地址⽣成器注册美区 Apple ID （参考⽂章：
https://zhuanlan.zhihu.com/p/367821925）

   > 美国地址⽣成器建议选以下五个免税州：
   > 
   > 蒙⼤拿州（Montana）
   > 
   > 俄勒冈州（Oregon）
   > 
   > 阿拉斯加州（Alaska）
   > 
   > 特拉华州（Delaware）
   > 
   > 新罕布什尔州（New Hampshire）

2. 登录 `App Store `后下载代理⼯具，推荐 `Potatso` （参考⽂章：
https://itlanyan.com/get-proxy-clients/）

# Linux: clash

- [部署安装](https://www.joeyne.cool/http/proxy/ubuntu-安装clash并配置开机启动/)
  - 有界面的可以选择使用 `CFW`，虽然叫这个名，但他其实支持 `Linux`（doge
  - 下载对应架构软件包，解压后将 `clash` 放入 `/usr/bin`，有需要可以设置成守护进程
  - 使用 `docker` [一键部署](https://blog.laoyutang.cn/linux/clash.html)

- 切换节点
  - 使用或部署 `yacd` 等 `ui` 界面控制台选择
  - 直接使用 `API`，终端输入 `curl -X PUT -H "Content-Type: application/json" -d '{"name":"节点名称"}' http://127.0.0.1:9090/proxies/🔰国外流量`

# 路由器: Clash Merlin