> [配套题目 N1BOOK](https://book.nu1l.com)

# 1）`Web` 入门
## 1.1 信息收集
### 敏感目录泄露

[`目录扫描工具 dirsearch`](https://github.com/maurosoria/dirsearch)

1. `git` 泄露
   - 常规泄露，工具 [`scrabble`](https://github.com/denny0223/scrabble)
   - 回滚，`git reset`
   - 分支，工具 [`GitHacker`](https://github.com/WangYihang/GitHacker)，`git reflog fsck diff`
   - 文件，`.git/config` 中可能存在 `access_token`，访问 `config` 有返回往往意味着泄露
2. `SVN` 泄露
   - `.svn/entries` 或 `wc.db` 文件获取服务器源码等信息，工具 [`Seay-svn`](https://github.com/kost/dvcs-ripper) 
   - `.svn/entries` 为空时，若 `wc.db` 存在可通过其中的 `checksum` 在 `pristine` 文件夹中获取源代码
3. `HG` 泄露
   - `.hg` 文件获取代码和分支修改记录等信息，工具 [`dvcs-ripper`](https://github.com/kost/dvcs-ripper) 

### 敏感备份文件

1. `gedit` 编辑保存文件后存在 `~` 后缀文件
2. `vim` 编辑时意外退出时（如 `SSH` 连接中断），会生成 `.文件名.swp` 备份文件，第二次为 `swo`，第三次为 `swn`，以此类推，此外还有 `*.un.文件名.swp` 类型，`vim -r flag`
3. 常规文件靠字典和经验，比如
   - `robots.txt`，记录一些目录和 `CMS` 版本信息
   - `readme.md`，记录CMS版本信息，有的甚至有 `Github` 地址
   - `www.zip/rar/tar.gz`，往往是网站的源码备份，也有可能是域名压缩包

### `Banner` 识别

1. 自行搜集指纹库，如 `Github` 上有大量成型且公开的 `CMS` 指纹库
   - 服务器的信息，针对 `Windows` 服务器，大概率去寻找 `CMS` 在其上的一些漏洞
   - 在不知道密码和无法重置的情况下，通过 `CMS` 网站本身的特性，结合目录遍历来实现最后的 `RCE（Remote Command/Code Execute，远程命令/代码执行）`
   - `Web` 框架，开启 `debug` 即使是 `404/302` 也有可能显示框架版本
   - `DedeCMS` 中，只要管理员登录过后台，就会在 `data` 目录下有一个相应的 `session` 文件，再通过 `editcookie` 修改 `Cookie` 进入后台
2. 使用 `Wappalyzer` 等工具，在 `data` 目录下，`apps.json` 文件是其规则库


## 1.2 `SQL` 注入