# Some useful scripts
# 一些有用的脚本


git_this.sh 
===================
##### 提交当前改动到github
***

setup-ssr-with-net_speeder.sh 
===================
##### 一键搭建SSR脚本
- 支持自选混淆协议，加密协议，自定义docker名字和端口 
- 来自其他人的镜像
***
python3.5-for-spider.sh
===================
##### 一键运行单个的python脚本
- 含有python3.5,requsets, beautifulsoup4
- 运行此脚本时，接收一个参数，参数为要运行的脚本的文件名，例如"./python3.5-for-spider.sh example.py"
- 需要docker环境的支持
***
newlinux.sh
===================
##### 用来在新的linux上安装必要环境
- 含有screenfetch mycli speedometer shadowsocks 以及java8  
- 复制自己的ssh和bash习惯到当前环境
***
install-docker.sh
===================
##### docker安装脚本
***
l2tp.sh
=======

- Description: Auto install L2TP VPN for CentOS6+/Debian7+/Ubuntu12+
- Intro: https://teddysun.com/448.html
```bash
Usage: l2tp [-l,--list|-a,--add|-d,--del|-m,--mod|-h,--help]

| Bash Command     | Description                  |
|------------------|------------------------------|
| l2tp -l,--list   | List all users               |
| l2tp -a,--add    | Add a user                   |
| l2tp -d,--del    | Delete a user                |
| l2tp -m,--mod    | Modify a user password       |
| l2tp -h,--help   | Print this help information  |
```
***
bbr.sh
======
- 一键升级内核以支持谷歌bbr加速技术
- Description: Auto install latest kernel for TCP BBR
- Intro: https://teddysun.com/489.html
***
bench.sh
========
- vps性能及连接速度测试
- Description: Auto test download & I/O speed script
- Intro: https://teddysun.com/444.html
```bash
Usage:

| No.      | Bash Command                    |
|----------|---------------------------------|
| 1        | wget -qO- bench.sh | bash       |
| 2        | curl -Lso- bench.sh | bash      |
| 3        | wget -qO- 86.re/bench.sh | bash |
| 4        | curl -so- 86.re/bench.sh | bash |
```
***
backup.sh
=========

- You must modify the config before run it
- Backup MySQL/MariaDB/Percona datebases, files and directories
- Backup file is encrypted with AES256-cbc with SHA1 message-digest (option)
- Auto transfer backup file to Google Drive (need install `gdrive` command) (option)
- Auto transfer backup file to FTP server (option)
- Auto delete Google Drive's or FTP server's remote file (option)
- Intro: https://teddysun.com/469.html

```bash
Install gdrive command step:

For x86_64: 
wget -O /usr/bin/gdrive http://dl.lamp.sh/files/gdrive-linux-x64
chmod +x /usr/bin/gdrive

For i386: 
wget -O /usr/bin/gdrive http://dl.lamp.sh/files/gdrive-linux-386
chmod +x /usr/bin/gdrive
```
***
ftp_upload.sh
=============

- You must modify the config before run it
- Upload file(s) to FTP server
- Intro: https://teddysun.com/484.html
***
unixbench.sh
============

- Description: Auto install unixbench and test script
- Intro: https://teddysun.com/245.html
***
pptp.sh(Deprecated)
===================

- Description: Auto Install PPTP for CentOS 6
- Intro: https://teddysun.com/134.html

Copyright (C) 2013-2017 Teddysun <i@teddysun.com>
